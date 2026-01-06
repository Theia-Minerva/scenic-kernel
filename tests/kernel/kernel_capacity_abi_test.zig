const std = @import("std");
const kernel_mod = @import("kernel");

const Kernel = kernel_mod.Kernel;
const sk_kernel = kernel_mod.sk_kernel;
const sk_kernel_create = kernel_mod.sk_kernel_create;
const sk_kernel_destroy = kernel_mod.sk_kernel_destroy;
const sk_kernel_append_annotation = kernel_mod.sk_kernel_append_annotation;
const sk_kernel_event_bytes = kernel_mod.sk_kernel_event_bytes;
const sk_kernel_error = kernel_mod.sk_kernel_error;

test "append succeeds when buffer exactly fits" {
    const allocator = std.testing.allocator;
    const payload = "abc";
    const capacity = 2 + payload.len;

    var kernel = try Kernel.init(allocator, capacity);
    defer kernel.deinit();

    try kernel.annotate(payload);

    const events = kernel.events().bytes;
    try std.testing.expectEqual(@as(usize, capacity), events.len);
}

test "append fails cleanly on capacity overflow" {
    const allocator = std.testing.allocator;
    var kernel = try Kernel.init(allocator, 2);
    defer kernel.deinit();

    const before = kernel.events();
    try std.testing.expectError(
        Kernel.StepError.CapacityExceeded,
        kernel.annotate("a"),
    );

    const after = kernel.events();
    try std.testing.expectEqual(before.bytes.len, after.bytes.len);
}

test "C ABI append rejects payloads larger than 255 bytes" {
    const handle = sk_kernel_create(512);
    try std.testing.expect(handle != null);
    defer sk_kernel_destroy(handle);

    var payload = [_]u8{0} ** 256;
    const rc = sk_kernel_append_annotation(handle, &payload, payload.len);
    try std.testing.expectEqual(
        @intFromEnum(sk_kernel_error.payload_too_large),
        rc,
    );

    var out_len: usize = 123;
    const ptr = sk_kernel_event_bytes(handle, &out_len);
    try std.testing.expect(ptr == null);
    try std.testing.expectEqual(@as(usize, 0), out_len);
}

test "C ABI event bytes pointer is stable until next append" {
    const handle = sk_kernel_create(64);
    try std.testing.expect(handle != null);
    defer sk_kernel_destroy(handle);

    var payload = [_]u8{1};
    const rc = sk_kernel_append_annotation(handle, &payload, payload.len);
    try std.testing.expectEqual(@intFromEnum(sk_kernel_error.ok), rc);

    var len1: usize = 0;
    const ptr1 = sk_kernel_event_bytes(handle, &len1);
    try std.testing.expect(ptr1 != null);

    var len2: usize = 0;
    const ptr2 = sk_kernel_event_bytes(handle, &len2);

    try std.testing.expect(ptr1 == ptr2);
    try std.testing.expectEqual(len1, len2);
}

test "C ABI destroy releases kernel safely" {
    const handle = sk_kernel_create(16);
    try std.testing.expect(handle != null);
    sk_kernel_destroy(handle);
}
