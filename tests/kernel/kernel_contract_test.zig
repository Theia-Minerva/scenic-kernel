const std = @import("std");
const Kernel = @import("kernel").Kernel;
const Segmenter = @import("consumer").Segmenter;
const DelimiterIndex = @import("consumer").DelimiterIndex;

const kernel_capacity: usize = 1024;

// KC-01: Kernel Construction Has No Side Effects
test "KC-01: A newly created kernel has an observable, empty event log and has not advanced time or state" {
    const allocator = std.testing.allocator;
    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    const events = kernel.events();
    try std.testing.expect(events.bytes.len == 0);
}

// KC-02: Explicit Time Advancement
test "KC-02: kernel advances only via explicit positive step" {
    const allocator = std.testing.allocator;
    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    const before = kernel.events();

    // dt == 0 must be rejected
    try std.testing.expectError(Kernel.StepError.InvalidDt, kernel.step(0));

    // dt < 0 must be rejected
    try std.testing.expectError(Kernel.StepError.InvalidDt, kernel.step(-1.0));

    const after = kernel.events();

    // Rejected steps must not change observable state
    try std.testing.expectEqual(before.bytes.len, after.bytes.len);
}

// KC-03: Append-Only Event Log
test "KC-03: successful steps do not rewrite existing event history" {
    const allocator = std.testing.allocator;
    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    const before = kernel.events();

    try kernel.step(1.0);

    const after = kernel.events();

    // Existing history must be preserved
    try std.testing.expect(after.bytes.len >= before.bytes.len);
    try std.testing.expectEqualSlices(
        u8,
        before.bytes,
        after.bytes[0..before.bytes.len],
    );
}

test "KC-03: successful step appends to event log" {
    const allocator = std.testing.allocator;
    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    const before = kernel.events();

    try kernel.step(1.0);

    const after = kernel.events();

    try std.testing.expect(after.bytes.len > before.bytes.len);
    try std.testing.expectEqualSlices(
        u8,
        before.bytes,
        after.bytes[0..before.bytes.len],
    );
}

// KC-04: Atomic, Self-Delimiting Events
test "KC-04: event log is composed of atomic, self-delimiting events" {
    const allocator = std.testing.allocator;
    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    // Cause some observable activity
    try kernel.step(1.0);
    try kernel.step(1.0);

    const log = kernel.events().bytes;

    const header_size: usize = 2; // tag:u8 + len:u8

    var i: usize = 0;
    while (i < log.len) {
        // Must be able to read a full header
        try std.testing.expect(i + header_size <= log.len);

        const len = log[i + 1];

        const next = i + header_size + len;

        // Must not run past end of log
        try std.testing.expect(next <= log.len);

        i = next;
    }

    // Must end exactly on an event boundary
    try std.testing.expect(i == log.len);
}

test "KC-06: checkpoints act as structural delimiters, not segment members" {
    const allocator = std.testing.allocator;
    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    try kernel.step(1.0);
    try kernel.checkpoint();
    try kernel.step(1.0);
    try kernel.checkpoint();
    try kernel.step(1.0);

    const log = kernel.events();

    var index = DelimiterIndex.init(allocator);
    defer index.deinit();
    try index.build(log);

    var segmenter = Segmenter.init(&index, log);

    try std.testing.expectEqual(
        index.count() + 1,
        segmenter.segmentCount(),
    );
}
