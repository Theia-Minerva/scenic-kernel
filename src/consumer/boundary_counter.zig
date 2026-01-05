// boundary_counter.zig
//
// A minimal projection that derives state from Boundary events.
// This is a consumer-side construct; it does not touch the kernel.
//

pub const BoundaryCounter = struct {
    count: usize,

    pub fn init() BoundaryCounter {
        return .{
            .count = 0,
        };
    }

    /// Apply a single Boundary event.
    ///
    /// This function:
    /// - derives state from history
    /// - has no side effects
    /// - is deterministic
    ///
    pub fn applyBoundary(self: *BoundaryCounter) void {
        self.count += 1;
    }
};
