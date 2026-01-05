const std = @import("std");
const Kernel = @import("kernel").Kernel;
const DelimiterCursor = @import("consumer").DelimiterCursor;

test "DelimiterCursor consumes one Step per kernel.step()" {
    const allocator = std.testing.allocator;

    var kernel = Kernel.init(allocator);
    defer kernel.deinit();

    var cursor = DelimiterCursor.init();

    // No events yet
    try std.testing.expect(cursor.advance(kernel.events()) == null);

    // Emit one step
    try kernel.step(1.0);

    // Cursor should advance exactly once
    try std.testing.expect(cursor.advance(kernel.events()) != null);
    try std.testing.expect(cursor.advance(kernel.events()) == null);

    // Emit two more steps
    try kernel.step(1.0);
    try kernel.step(1.0);

    // Cursor should advance twice
    try std.testing.expect(cursor.advance(kernel.events()) != null);
    try std.testing.expect(cursor.advance(kernel.events()) != null);
    try std.testing.expect(cursor.advance(kernel.events()) == null);
}

test "DelimiterCursor skips unknown events" {
    const allocator = std.testing.allocator;

    var kernel = Kernel.init(allocator);
    defer kernel.deinit();

    // Emit delimiter
    try kernel.step(1.0);

    // Manually append a fake unknown event: tag=255, len=0
    const old_len = kernel.event_bytes.len;
    kernel.event_bytes =
        try allocator.realloc(kernel.event_bytes, old_len + 2);
    kernel.event_bytes[old_len + 0] = 255;
    kernel.event_bytes[old_len + 1] = 0;

    // Emit another delimiter
    try kernel.step(1.0);

    var cursor = DelimiterCursor.init();
    var count: usize = 0;

    while (true) {
        const off = cursor.advance(kernel.events());
        if (off == null) break;
        count += 1;
    }

    try std.testing.expectEqual(count, 2);
}
