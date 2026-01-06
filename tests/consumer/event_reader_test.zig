const std = @import("std");
const Kernel = @import("kernel").Kernel;
const consumer = @import("consumer");

const kernel_capacity: usize = 1024;

test "EventReader yields exact event and payload slices" {
    const allocator = std.testing.allocator;

    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    try kernel.step(1.0);
    try kernel.annotate("hi");
    try kernel.checkpoint();

    const bytes = kernel.events().bytes;

    var reader = consumer.EventReader.init(bytes);

    const ev0 = (try reader.next()).?;
    try std.testing.expectEqual(@intFromEnum(Kernel.EventTag.Boundary), ev0.tag);
    try std.testing.expect(ev0.payload.len == 0);
    try std.testing.expect(ev0.event_bytes.len == 2);

    const ev1 = (try reader.next()).?;
    try std.testing.expectEqual(@intFromEnum(Kernel.EventTag.Annotation), ev1.tag);
    try std.testing.expectEqualSlices(u8, "hi", ev1.payload);
    try std.testing.expect(ev1.event_bytes.len == 4);

    const ev2 = (try reader.next()).?;
    try std.testing.expectEqual(@intFromEnum(Kernel.EventTag.Checkpoint), ev2.tag);
    try std.testing.expect(ev2.payload.len == 0);
    try std.testing.expect(ev2.event_bytes.len == 2);

    try std.testing.expect((try reader.next()) == null);
}

test "EventReader rejects truncated input" {
    var reader = consumer.EventReader.init(&[_]u8{1});
    try std.testing.expectError(consumer.EventReader.Error.MalformedLog, reader.next());

    var reader2 = consumer.EventReader.init(&[_]u8{ 2, 3, 9 });
    try std.testing.expectError(consumer.EventReader.Error.MalformedLog, reader2.next());
}

test "EventReader errors after buffer mutation mid-iteration" {
    const allocator = std.testing.allocator;

    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    try kernel.step(1.0);
    try kernel.annotate("a");

    const bytes = kernel.events().bytes;

    var reader = consumer.EventReader.init(bytes);
    const ev0 = (try reader.next()).?;

    const next_offset = ev0.offset + ev0.event_bytes.len;
    // Corrupt the next event length to exceed the remaining buffer.
    bytes[next_offset + 1] = 250;

    try std.testing.expectError(
        consumer.EventReader.Error.MalformedLog,
        reader.next(),
    );
}

test "EventReader errors on truncated slice view mid-stream" {
    const allocator = std.testing.allocator;

    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    try kernel.step(1.0);
    try kernel.annotate("abc");
    try kernel.checkpoint();

    const bytes = kernel.events().bytes;

    var reader = consumer.EventReader.init(bytes);
    _ = (try reader.next()).?;
    _ = (try reader.next()).?;

    const offset_after_two = reader.offset;
    const truncated = bytes[0 .. offset_after_two + 1];

    var reader2 = consumer.EventReader.init(truncated);
    _ = (try reader2.next()).?;
    _ = (try reader2.next()).?;

    try std.testing.expectError(
        consumer.EventReader.Error.MalformedLog,
        reader2.next(),
    );
}
