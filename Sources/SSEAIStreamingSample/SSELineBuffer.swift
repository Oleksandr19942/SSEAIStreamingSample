import Foundation

/// Accumulates UTF-8 chunks into complete SSE lines (`\n` or `\r\n` delimited).
struct SSELineBuffer {
    private var pending = ""

    mutating func append(_ chunk: String) -> [String] {
        pending += chunk
        var lines: [String] = []

        while let range = pending.rangeOfCharacter(from: .newlines) {
            let line = String(pending[..<range.lowerBound])
            lines.append(line)
            var index = range.upperBound
            if index < pending.endIndex, pending[index] == "\n" {
                index = pending.index(after: index)
            }
            pending = String(pending[index...])
        }

        return lines
    }

    mutating func drain() -> [String] {
        guard !pending.isEmpty else { return [] }
        defer { pending = "" }
        return [pending]
    }
}
