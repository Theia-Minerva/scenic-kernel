const std = @import("std");
const Walker = @import("walker");
const Kernel = @import("kernel").Kernel;

const kernel_capacity: usize = 1024;

test "log walker can traverse kernel event log" {
    const allocator = std.testing.allocator;
    var kernel = try Kernel.init(allocator, kernel_capacity);
    defer kernel.deinit();

    try kernel.step(1.0);
    try kernel.step(1.0);

    const log = kernel.events().bytes;

    var offset: usize = 0;
    var count: usize = 0;

    while (true) {
        const ev = Walker.nextEvent(log, offset) orelse break;
        offset = ev.next_offset;
        count += 1;
    }

    try std.testing.expect(offset == log.len);
    try std.testing.expect(count > 0);
}
