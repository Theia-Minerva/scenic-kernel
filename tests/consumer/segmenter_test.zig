const std = @import("std");
const Kernel = @import("kernel").Kernel;
const DelimiterIndex = @import("consumer").DelimiterIndex;
const Segmenter = @import("consumer").Segmenter;

const kernel_capacity: usize = 1024;

test "Segmenter derives correct segments from DelimiterIndex" {
    const allocator = std.testing.allocator;

    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    try kernel.step(1.0); // D0
    try kernel.step(1.0); // D1
    try kernel.step(1.0); // D2

    var index = DelimiterIndex.init(allocator);
    defer index.deinit();
    try index.build(kernel.events());

    var seg = Segmenter.init(&index, kernel.events());

    try std.testing.expectEqual(@as(usize, 4), seg.segmentCount());

    const s0 = seg.segmentAt(0);
    const s1 = seg.segmentAt(1);
    const s2 = seg.segmentAt(2);
    const s3 = seg.segmentAt(3);

    // Segment 0: before first delimiter
    try std.testing.expect(s0.start == 0);
    try std.testing.expect(s0.end == index.at(0));

    // Segment 1: between D0 and D1 (excluding delimiters)
    try std.testing.expect(s1.start == index.at(0) + 2);
    try std.testing.expect(s1.end == index.at(1));

    // Segment 2: between D1 and D2
    try std.testing.expect(s2.start == index.at(1) + 2);
    try std.testing.expect(s2.end == index.at(2));

    // Segment 3: after last delimiter
    try std.testing.expect(s3.start == index.at(2) + 2);
    try std.testing.expect(s3.end == kernel.events().bytes.len);
}
