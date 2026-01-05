const std = @import("std");
const Kernel = @import("kernel").Kernel;
const DelimiterIndex = @import("consumer").DelimiterIndex;
const Segmenter = @import("consumer").Segmenter;
const EventIterator = @import("consumer").EventIterator;

test "EventIterator walks events inside a segment" {
    const allocator = std.testing.allocator;

    var kernel = Kernel.init(allocator);
    defer kernel.deinit();

    // Delimiter
    try kernel.step(1.0);

    // Inject a non-boundary event: tag=7, len=2, payload=[1,2]
    {
        const old_len = kernel.event_bytes.len;
        kernel.event_bytes =
            try allocator.realloc(kernel.event_bytes, old_len + 4);
        kernel.event_bytes[old_len + 0] = 7;
        kernel.event_bytes[old_len + 1] = 2;
        kernel.event_bytes[old_len + 2] = 1;
        kernel.event_bytes[old_len + 3] = 2;
    }

    var index = DelimiterIndex.init(allocator);
    defer index.deinit();
    try index.build(kernel.events());

    var seg = Segmenter.init(&index, kernel.events());

    // Segment AFTER the boundary
    const s1 = seg.segmentAt(1);

    var it = EventIterator.init(kernel.events(), s1);

    const e0 = it.next().?;
    try std.testing.expect(e0.tag == 7);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 2 }, e0.payload);

    try std.testing.expect(it.next() == null);
}
