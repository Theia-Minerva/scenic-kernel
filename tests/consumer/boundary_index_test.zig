const std = @import("std");
const Kernel = @import("kernel").Kernel;
const BoundaryIndex = @import("consumer").BoundaryIndex;

test "BoundaryIndex indexes boundary offsets deterministically and skips non-boundary events" {
    const allocator = std.testing.allocator;

    var kernel = Kernel.init(allocator);
    defer kernel.deinit();

    // Boundary 0
    try kernel.step(1.0);

    // Inject an unknown event: tag=255, len=0
    {
        const old_len = kernel.event_bytes.len;
        kernel.event_bytes =
            try allocator.realloc(kernel.event_bytes, old_len + 2);
        kernel.event_bytes[old_len + 0] = 255; // unknown tag
        kernel.event_bytes[old_len + 1] = 0;
    }

    // Boundary 1
    try kernel.step(1.0);

    // Inject another unknown event
    {
        const old_len = kernel.event_bytes.len;
        kernel.event_bytes =
            try allocator.realloc(kernel.event_bytes, old_len + 2);
        kernel.event_bytes[old_len + 0] = 42; // another unknown tag
        kernel.event_bytes[old_len + 1] = 0;
    }

    // Boundary 2
    try kernel.step(1.0);

    var index = BoundaryIndex.init(allocator);
    defer index.deinit();

    try index.build(kernel.events());

    // We should see exactly the three boundaries
    try std.testing.expectEqual(@as(usize, 3), index.count());

    // Offsets must be strictly increasing
    try std.testing.expect(index.at(0) < index.at(1));
    try std.testing.expect(index.at(1) < index.at(2));
}
