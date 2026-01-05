/// kernel.zig
///
/// see docs/design/KERNEL_CONTRACT.md
///
const std = @import("std");

pub const Kernel = struct {
    allocator: std.mem.Allocator,
    event_bytes: []u8,

    pub const EventLog = struct {
        bytes: []u8,
    };

    pub const EventTag = enum(u8) {
        Boundary,
    };

    pub const StepError = error{
        InvalidDt,
        OutOfMemory,
    };

    pub fn init(
        allocator: std.mem.Allocator,
    ) Kernel {
        return .{
            .allocator = allocator,
            .event_bytes = &[_]u8{},
        };
    }

    pub fn deinit(self: *Kernel) void {
        self.allocator.free(self.event_bytes);
    }

    pub fn step(self: *Kernel, dt: f32) StepError!void {
        if (dt <= 0) return StepError.InvalidDt;

        // Event format: [tag:u8][len:u8][payload...], with len in 0..255 (KC-04, KC-05).
        // space for [tag::u8][len=0]
        const old_len = self.event_bytes.len;
        const new_len = old_len + 2;

        self.event_bytes =
            self.allocator.realloc(self.event_bytes, new_len) catch return error.OutOfMemory;

        self.event_bytes[old_len + 0] = @intFromEnum(EventTag.Boundary); // tag
        self.event_bytes[old_len + 1] = 0; // payload length
    }

    pub fn events(self: *const Kernel) EventLog {
        return .{
            .bytes = self.event_bytes,
        };
    }
};
