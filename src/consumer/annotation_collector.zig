// annotation_collector.zig
//
// A semantic consumer that extracts Annotation payloads
// from a segment.
//

const std = @import("std");
const Kernel = @import("kernel").Kernel;
const Segment = @import("consumer").Segment;
const EventIterator = @import("consumer").EventIterator;

pub const AnnotationCollector = struct {
    pub fn collect(
        log: Kernel.EventLog,
        segment: Segment,
        allocator: std.mem.Allocator,
    ) ![][]const u8 {
        var it = EventIterator.init(log, segment);
        var results = std.ArrayList([]const u8).init(allocator);

        while (it.next()) |ev| {
            if (ev.tag == @intFromEnum(Kernel.EventTag.Annotation)) {
                try results.append(ev.payload);
            }
        }

        return results.toOwnedSlice();
    }
};
