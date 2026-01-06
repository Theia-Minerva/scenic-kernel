const std = @import("std");
const Kernel = @import("kernel").Kernel;

pub const sk_kernel = struct {
    kernel: Kernel,
};

pub const sk_kernel_error = enum(c_int) {
    ok = 0,
    invalid_args = 1,
    payload_too_large = 2,
    capacity_exceeded = 3,
    out_of_memory = 4,
};

pub export fn sk_kernel_create(max_bytes: usize) ?*sk_kernel {
    const allocator = std.heap.page_allocator;
    const kernel = Kernel.init(allocator, max_bytes) catch return null;
    const handle = allocator.create(sk_kernel) catch {
        var owned_kernel = kernel;
        owned_kernel.deinit();
        return null;
    };
    handle.* = .{ .kernel = kernel };
    return handle;
}

pub export fn sk_kernel_destroy(kernel: ?*sk_kernel) void {
    if (kernel) |handle| {
        const allocator = handle.kernel.allocator;
        handle.kernel.deinit();
        allocator.destroy(handle);
    }
}

pub export fn sk_kernel_append_annotation(
    kernel: ?*sk_kernel,
    payload: ?[*]const u8,
    payload_len: usize,
) c_int {
    if (kernel == null) return @intFromEnum(sk_kernel_error.invalid_args);
    if (payload_len > 255) return @intFromEnum(sk_kernel_error.payload_too_large);
    if (payload_len > 0 and payload == null) {
        return @intFromEnum(sk_kernel_error.invalid_args);
    }

    const slice = if (payload_len == 0) &[_]u8{} else payload.?[0..payload_len];

    kernel.?.kernel.annotate(slice) catch |err| {
        return switch (err) {
            error.PayloadTooLarge => @intFromEnum(sk_kernel_error.payload_too_large),
            error.CapacityExceeded => @intFromEnum(sk_kernel_error.capacity_exceeded),
            else => @intFromEnum(sk_kernel_error.out_of_memory),
        };
    };

    return @intFromEnum(sk_kernel_error.ok);
}

pub export fn sk_kernel_event_bytes(
    kernel: ?*const sk_kernel,
    out_len: ?*usize,
) ?[*]const u8 {
    if (kernel == null) {
        if (out_len) |len_ptr| len_ptr.* = 0;
        return null;
    }

    const bytes = kernel.?.kernel.events().bytes;
    if (out_len) |len_ptr| len_ptr.* = bytes.len;
    if (bytes.len == 0) return null;
    return bytes.ptr;
}
