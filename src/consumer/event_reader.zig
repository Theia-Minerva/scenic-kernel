// event_reader.zig
//
// Zero-allocation reader for the kernel event byte stream.
// Yields exact event slices and payload slices.

pub const EventReader = struct {
    bytes: []const u8,
    offset: usize,

    pub const Error = error{
        MalformedLog,
    };

    pub const Event = struct {
        offset: usize,
        tag: u8,
        event_bytes: []const u8,
        payload: []const u8,
    };

    pub fn init(bytes: []const u8) EventReader {
        return .{
            .bytes = bytes,
            .offset = 0,
        };
    }

    /// Return the next event in the stream.
    /// Errors on malformed or truncated input.
    pub fn next(self: *EventReader) Error!?Event {
        if (self.offset == self.bytes.len) return null;
        if (self.offset + 2 > self.bytes.len) return error.MalformedLog;

        const start = self.offset;
        const tag = self.bytes[start];
        const len: usize = self.bytes[start + 1];
        const next_offset = start + 2 + len;

        if (next_offset > self.bytes.len) return error.MalformedLog;

        const event_bytes = self.bytes[start..next_offset];
        const payload = self.bytes[start + 2 .. next_offset];

        self.offset = next_offset;
        return .{
            .offset = start,
            .tag = tag,
            .event_bytes = event_bytes,
            .payload = payload,
        };
    }
};
