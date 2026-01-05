// event_iterator.zig
//
// Iterates over events within a byte-range segment of the event log.
// Structural only: no semantics, no allocations.
//

const Kernel = @import("kernel").Kernel;
const Segment = @import("consumer").Segment;

pub const EventView = struct {
    tag: u8,
    payload: []const u8,
};

pub const EventIterator = struct {
    bytes: []const u8,
    offset: usize,
    end: usize,

    pub fn init(
        log: Kernel.EventLog,
        segment: Segment,
    ) EventIterator {
        return .{
            .bytes = log.bytes,
            .offset = segment.start,
            .end = segment.end,
        };
    }

    /// Return the next event inside the segment, or null if exhausted
    /// or if the log is malformed.
    pub fn next(self: *EventIterator) ?EventView {
        // End of segment
        if (self.offset >= self.end) {
            return null;
        }

        // Need at least [tag][len]
        if (self.offset + 2 > self.end) {
            return null;
        }

        const tag = self.bytes[self.offset];
        const len: usize = self.bytes[self.offset + 1];

        const payload_start = self.offset + 2;
        const payload_end = payload_start + len;

        // Payload must fit within the segment
        if (payload_end > self.end) {
            return null;
        }

        const view = EventView{
            .tag = tag,
            .payload = self.bytes[payload_start..payload_end],
        };

        self.offset = payload_end;
        return view;
    }
};
