// delimiter_index.zig
//
// A projection that indexes the byte offsets of delimiter events
// in the kernel event log. No semantics, no payload parsing.
//

const std = @import("std");
const Kernel = @import("kernel").Kernel;
const DelimiterCursor = @import("consumer").DelimiterCursor;

pub const DelimiterIndex = struct {
    allocator: std.mem.Allocator,
    offsets: std.ArrayListUnmanaged(usize),

    pub fn init(allocator: std.mem.Allocator) DelimiterIndex {
        return .{
            .allocator = allocator,
            .offsets = .{},
        };
    }

    pub fn deinit(self: *DelimiterIndex) void {
        self.offsets.deinit(self.allocator);
    }

    /// Build the index by walking the log with a DelimiterCursor.
    ///
    /// Records the starting byte offset of each delimiter event.
    /// Deterministic and replay-safe.
    pub fn build(
        self: *DelimiterIndex,
        log: Kernel.EventLog,
    ) !void {
        var cursor = DelimiterCursor.init();

        while (true) {
            const delimiter_start = cursor.advance(log) orelse break;
            try self.offsets.append(self.allocator, delimiter_start);
        }
    }

    /// Number of delimiter events indexed.
    pub fn count(self: *const DelimiterIndex) usize {
        return self.offsets.items.len;
    }

    /// Get the byte offset of the i-th delimiter.
    pub fn at(self: *const DelimiterIndex, i: usize) usize {
        return self.offsets.items[i];
    }
};
