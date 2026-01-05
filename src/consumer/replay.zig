// replay.zig
//
// Consumer-side replay utilities for the kernel event stream.

const std = @import("std");
const EventReader = @import("consumer").EventReader;

pub fn replayTo(
    writer: anytype,
    bytes: []const u8,
) (EventReader.Error || @TypeOf(writer).Error)!void {
    var reader = EventReader.init(bytes);

    while (true) {
        const ev = try reader.next() orelse break;
        try writer.writeAll(ev.event_bytes);
    }
}

pub fn replayAlloc(
    allocator: std.mem.Allocator,
    bytes: []const u8,
) (EventReader.Error || error{OutOfMemory})![]u8 {
    var reader = EventReader.init(bytes);

    while (true) {
        _ = try reader.next() orelse break;
    }

    const out = try allocator.alloc(u8, bytes.len);
    @memcpy(out, bytes);
    return out;
}
