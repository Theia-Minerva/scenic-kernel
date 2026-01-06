/// kernel.zig
///
/// see docs/design/KERNEL_CONTRACT.md
///
const std = @import("std");

pub const Kernel = struct {
    allocator: std.mem.Allocator,
    buffer: []u8,
    len: usize,

    pub const EventLog = struct {
        bytes: []u8,
    };

    pub const EventTag = enum(u8) {
        Boundary,
        Annotation,
        Checkpoint,
    };

    pub const Checkpoint = struct {
        /// Monotonic, kernel-assigned identifier.
        /// Increments strictly by emission order.
        id: u64,
    };

    pub const StepError = error{
        InvalidDt,
        PayloadTooLarge,
        CapacityExceeded,
    };

    pub fn init(
        allocator: std.mem.Allocator,
        max_bytes: usize,
    ) error{OutOfMemory}!Kernel {
        const buffer = try allocator.alloc(u8, max_bytes);
        return .{
            .allocator = allocator,
            .buffer = buffer,
            .len = 0,
        };
    }

    pub fn deinit(self: *Kernel) void {
        self.allocator.free(self.buffer);
    }

    pub fn step(self: *Kernel, dt: f32) StepError!void {
        if (dt <= 0) return StepError.InvalidDt;

        // Event format: [tag:u8][len:u8][payload...], with len in 0..255 (KC-04, KC-05).
        // space for [tag::u8][len=0]
        const old_len = self.len;
        const new_len = old_len + 2;

        if (new_len > self.buffer.len) return error.CapacityExceeded;

        self.buffer[old_len + 0] = @intFromEnum(EventTag.Boundary); // tag
        self.buffer[old_len + 1] = 0; // payload length
        self.len = new_len;
    }

    // payloads
    pub fn annotate(
        self: *Kernel,
        payload: []const u8,
    ) StepError!void {
        if (payload.len > 255) return error.PayloadTooLarge; // bounded format

        const old_len = self.len;
        const new_len = old_len + 2 + payload.len;

        if (new_len > self.buffer.len) return error.CapacityExceeded;

        self.buffer[old_len + 0] =
            @intFromEnum(EventTag.Annotation);
        self.buffer[old_len + 1] =
            @intCast(payload.len);

        @memcpy(
            self.buffer[old_len + 2 .. new_len],
            payload,
        );
        self.len = new_len;
    }

    pub fn checkpoint(self: *Kernel) StepError!void {
        // Event format: [tag:u8][len:u8][payload...], with len in 0..255.
        // Checkpoint is an empty structural marker.
        const old_len = self.len;
        const new_len = old_len + 2;

        if (new_len > self.buffer.len) return error.CapacityExceeded;

        self.buffer[old_len + 0] = @intFromEnum(EventTag.Checkpoint); // tag
        self.buffer[old_len + 1] = 0; // payload length
        self.len = new_len;
    }

    pub fn events(self: *const Kernel) EventLog {
        return .{
            .bytes = self.buffer[0..self.len],
        };
    }
};
