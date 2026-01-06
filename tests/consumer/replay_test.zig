const std = @import("std");
const Kernel = @import("kernel").Kernel;
const consumer = @import("consumer");

const kernel_capacity: usize = 64 * 1024;

test "replayAlloc round-trips bytes" {
    const allocator = std.testing.allocator;

    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    try kernel.step(1.0);
    try kernel.annotate("abc");
    try kernel.checkpoint();
    try kernel.step(1.0);

    const bytes = kernel.events().bytes;

    const out = try consumer.replayAlloc(allocator, bytes);
    defer allocator.free(out);

    try std.testing.expectEqualSlices(u8, bytes, out);
}

test "replayTo round-trips bytes" {
    const allocator = std.testing.allocator;

    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    try kernel.step(1.0);
    try kernel.checkpoint();
    try kernel.annotate("payload");

    const bytes = kernel.events().bytes;

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    try consumer.replayTo(list.writer(), bytes);
    try std.testing.expectEqualSlices(u8, bytes, list.items);
}

test "replayAlloc rejects truncated input" {
    const allocator = std.testing.allocator;
    const bad = &[_]u8{ 7, 2, 1 };

    try std.testing.expectError(
        consumer.EventReader.Error.MalformedLog,
        consumer.replayAlloc(allocator, bad),
    );
}

test "replayAlloc scales with many events" {
    const allocator = std.testing.allocator;

    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    var i: usize = 0;
    while (i < 10_000) : (i += 1) {
        try kernel.step(1.0);
    }

    const bytes = kernel.events().bytes;
    const out = try consumer.replayAlloc(allocator, bytes);
    defer allocator.free(out);

    try std.testing.expectEqualSlices(u8, bytes, out);
}
