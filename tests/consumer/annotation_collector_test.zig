const std = @import("std");
const Kernel = @import("kernel").Kernel;
const DelimiterIndex = @import("consumer").DelimiterIndex;
const Segmenter = @import("consumer").Segmenter;
const EventIterator = @import("consumer").EventIterator;
const AnnotationCollector = @import("consumer").AnnotationCollector;

const kernel_capacity: usize = 1024;

test "Annotation events are preserved and replayable within a segment" {
    const allocator = std.testing.allocator;

    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    try kernel.step(1.0);
    try kernel.annotate("hello");
    try kernel.annotate("world");
    try kernel.step(1.0);

    try std.testing.expect(kernel.events().bytes.len > 16);
    // std.debug.print(
    //     "event log bytes (len={}): {any}\n",
    //     .{ kernel.events().bytes.len, kernel.events().bytes },
    // );

    var index = DelimiterIndex.init(allocator);
    defer index.deinit();
    try index.build(kernel.events());

    // std.debug.print(
    //     "DelimiterIndex offsets (count={}): {any}\n",
    //     .{ index.count(), index.offsets.items },
    // );

    var seg = Segmenter.init(&index, kernel.events());

    const s1 = seg.segmentAt(1);

    const ann =
        try AnnotationCollector.collect(
            kernel.events(),
            s1,
            allocator,
        );
    defer allocator.free(ann);

    try std.testing.expectEqual(@as(usize, 2), ann.len);
    try std.testing.expectEqualStrings("hello", ann[0]);
    try std.testing.expectEqualStrings("world", ann[1]);
}
