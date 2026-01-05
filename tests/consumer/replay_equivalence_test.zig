const std = @import("std");

const Kernel = @import("kernel").Kernel;
const DelimiterCursor = @import("consumer").DelimiterCursor;
const BoundaryCounter = @import("consumer").BoundaryCounter;

test "replay equivalence: boundary-derived state is deterministic" {
    const allocator = std.testing.allocator;

    // --- Live run: produce history ---
    var kernel = Kernel.init(allocator);
    defer kernel.deinit();

    try kernel.step(1.0);
    try kernel.step(1.0);
    try kernel.step(1.0);

    const log = kernel.events();

    // --- First consumption ---
    var cursor1 = DelimiterCursor.init();
    var counter1 = BoundaryCounter.init();

    while (cursor1.advance(log)) |_| {
        counter1.applyBoundary();
    }

    // --- Replay consumption ---
    var cursor2 = DelimiterCursor.init();
    var counter2 = BoundaryCounter.init();

    while (cursor2.advance(log)) |_| {
        counter2.applyBoundary();
    }

    // --- Determinism check ---
    try std.testing.expectEqual(counter1.count, counter2.count);
    try std.testing.expectEqual(counter1.count, 3);
}
