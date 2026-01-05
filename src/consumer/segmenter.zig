// segmenter.zig
//
// Derives byte-range segments from a DelimiterIndex.
// Purely structural: no semantics, no payload parsing.
//

const Kernel = @import("kernel").Kernel;
const DelimiterIndex = @import("consumer").DelimiterIndex;

pub const Segment = struct {
    start: usize,
    end: usize, // exclusive
};

pub const Segmenter = struct {
    index: *const DelimiterIndex,
    log_len: usize,

    pub fn init(index: *const DelimiterIndex, log: Kernel.EventLog) Segmenter {
        return .{
            .index = index,
            .log_len = log.bytes.len,
        };
    }

    /// Total number of segments including the initial (pre-first-boundary) segment
    /// and the trailing (post-last-boundary) segment.
    pub fn segmentCount(self: *const Segmenter) usize {
        // segments = delimiters + 1
        return self.index.count() + 1;
    }

    /// Get the i-th segment as a byte range [start, end).
    /// Valid for i in 0..segmentCount().
    pub fn segmentAt(self: *const Segmenter, i: usize) Segment {
        const n = self.index.count();
        const delimiter_size: usize = 2;

        if (i == 0) {
            // Before first delimiter
            return .{
                .start = 0,
                .end = if (n > 0) self.index.at(0) else self.log_len,
            };
        }

        if (i < n) {
            // Between delimiters
            return .{
                .start = self.index.at(i - 1) + delimiter_size,
                .end = self.index.at(i),
            };
        }

        // After last delimiter
        return .{
            .start = self.index.at(n - 1) + delimiter_size,
            .end = self.log_len,
        };
    }
};
