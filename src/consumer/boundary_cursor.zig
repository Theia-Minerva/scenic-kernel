// boundary_cursor.zig
//
// A minimal structural cursor over scenic-kernel's event log.
// Locates and consumes Boundary events while skipping all others.
//

const std = @import("std");
const Kernel = @import("kernel").Kernel;

pub const BoundaryCursor = struct {
    /// Current byte offset into the event log.
    /// Always points to the start of the next event to examine.
    offset: usize,

    pub fn init() BoundaryCursor {
        return .{
            .offset = 0,
        };
    }

    /// Advance the cursor to the next Boundary event, if any.
    ///
    /// Returns:
    /// - `usize` — the byte offset at which the Boundary event begins
    /// - `null`  — if no further Boundary events are available
    ///             or the log is malformed
    ///
    /// On success, the cursor advances past the entire Boundary event
    /// ([tag][len][payload]).
    ///
    /// This function:
    /// - does not allocate
    /// - does not mutate the kernel
    /// - does not interpret payload contents
    /// - skips non-Boundary events transparently
    ///
    pub fn advance(
        self: *BoundaryCursor,
        log: Kernel.EventLog,
    ) ?usize {
        const bytes = log.bytes;

        while (true) {
            if (self.offset >= bytes.len) return null;
            if (self.offset + 2 > bytes.len) return null;

            const start = self.offset;
            const tag = bytes[start];
            const len = bytes[start + 1];
            const next = start + 2 + len;
            if (next > bytes.len) return null;

            if (tag == @intFromEnum(Kernel.EventTag.Boundary)) {
                self.offset = next;
                return start; // byte offset where Boundary begins
            }

            // Skip non-boundary event
            self.offset = next;
        }
    }
};
