pub const EventHeader = struct {
    tag: u8,
    len: u8,
};

pub fn nextEvent(
    log: []const u8,
    offset: usize,
) ?struct {
    header: EventHeader,
    payload: []const u8,
    next_offset: usize,
} {
    // Header = tag (1 byte) len (1 byte)
    const header_size: usize = 2;

    if (offset == log.len) return null;
    if (offset + header_size > log.len) return null;

    const tag = log[offset];
    const len = log[offset + 1];

    // Payload length ∈ [0, 255] bytes
    // if real payload larger, must be split
    // if len = 0, there is no payload, so payload_start = next
    const payload_start = offset + header_size;
    const next = payload_start + len;

    if (next > log.len) return null;

    return .{
        .header = .{
            .tag = tag,
            .len = len,
        },
        .payload = log[payload_start..next],
        .next_offset = next,
    };
}
