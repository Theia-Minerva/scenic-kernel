const std = @import("std");
const Kernel = @import("kernel").Kernel;
const BoundaryIndex = @import("consumer").BoundaryIndex;
const Segmenter = @import("consumer").Segmenter;

test "Segmenter derives correct segments from BoundaryIndex" {
    const allocator = std.testing.allocator;

    var kernel = Kernel.init(allocator);
    defer kernel.deinit();

    try kernel.step(1.0); // B0
    try kernel.step(1.0); // B1
    try kernel.step(1.0); // B2

    var index = BoundaryIndex.init(allocator);
    defer index.deinit();
    try index.build(kernel.events());

    var seg = Segmenter.init(&index, kernel.events());

    try std.testing.expectEqual(@as(usize, 4), seg.segmentCount());

    const s0 = seg.segmentAt(0);
    const s1 = seg.segmentAt(1);
    const s2 = seg.segmentAt(2);
    const s3 = seg.segmentAt(3);

    // Segment 0: before first boundary
    try std.testing.expect(s0.start == 0);
    try std.testing.expect(s0.end == index.at(0));

    // Segment 1: between B0 and B1 (excluding boundaries)
    try std.testing.expect(s1.start == index.at(0) + 2);
    try std.testing.expect(s1.end == index.at(1));

    // Segment 2: between B1 and B2
    try std.testing.expect(s2.start == index.at(1) + 2);
    try std.testing.expect(s2.end == index.at(2));

    // Segment 3: after last boundary
    try std.testing.expect(s3.start == index.at(2) + 2);
    try std.testing.expect(s3.end == kernel.events().bytes.len);
}
