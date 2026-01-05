// boundary_cursor.zig
//
// A minimal consumer of scenic-kernel's event log.
// Treats each EventTag.Boundary as a single advancement boundary.
//

const std = @import("std");
const Kernel = @import("kernel").Kernel;

pub const BoundaryCursor = struct {
    /// Byte offset into the event log
    offset: usize,

    pub fn init() BoundaryCursor {
        return .{
            .offset = 0,
        };
    }

    /// Advance the cursor by exactly one Boundary event, if available.
    ///
    /// Returns:
    /// - true  if a Boundary event was consumed
    /// - false if no further Boundary events are available
    ///   or the log is malformed
    ///
    /// This function:
    /// - does not allocate
    /// - does not mutate the kernel
    /// - does not interpret payloads
    ///
    pub fn advance(
        self: *BoundaryCursor,
        log: Kernel.EventLog,
    ) bool {
        const bytes = log.bytes;

        while (true) {
            // No more data
            if (self.offset >= bytes.len) {
                return false;
            }

            // Need at least [tag][len]
            if (self.offset + 2 > bytes.len) {
                // Malformed log
                return false;
            }

            const tag_byte: u8 = bytes[self.offset];
            const payload_len: usize = bytes[self.offset + 1];

            const next_offset = self.offset + 2 + payload_len;

            // Payload must not run past buffer
            if (next_offset > bytes.len) {
                // Malformed log
                return false;
            }

            // Advance cursor past this event
            self.offset = next_offset;

            // Compare numerically; do NOT enumFromInt unknown values
            if (tag_byte == @intFromEnum(Kernel.EventTag.Boundary)) {
                return true;
            }

            // Otherwise: skip and continue
        }
    }
};
