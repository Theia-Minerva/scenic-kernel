// boundary_index.zig
//
// A projection that indexes the byte offsets of Boundary events
// in the kernel event log. No semantics, no payload parsing.
//

const std = @import("std");
const Kernel = @import("kernel").Kernel;
const BoundaryCursor = @import("consumer").BoundaryCursor;

pub const BoundaryIndex = struct {
    allocator: std.mem.Allocator,
    offsets: std.ArrayListUnmanaged(usize),

    pub fn init(allocator: std.mem.Allocator) BoundaryIndex {
        return .{
            .allocator = allocator,
            .offsets = .{},
        };
    }

    pub fn deinit(self: *BoundaryIndex) void {
        self.offsets.deinit(self.allocator);
    }

    /// Build the index by walking the log with a BoundaryCursor.
    ///
    /// Records the starting byte offset of each Boundary event.
    /// Deterministic and replay-safe.
    pub fn build(
        self: *BoundaryIndex,
        log: Kernel.EventLog,
    ) !void {
        var cursor = BoundaryCursor.init();

        while (true) {
            const boundary_start = cursor.advance(log) orelse break;
            try self.offsets.append(self.allocator, boundary_start);
        }
    }

    /// Number of Boundary events indexed.
    pub fn count(self: *const BoundaryIndex) usize {
        return self.offsets.items.len;
    }

    /// Get the byte offset of the i-th Boundary.
    pub fn at(self: *const BoundaryIndex, i: usize) usize {
        return self.offsets.items[i];
    }
};
