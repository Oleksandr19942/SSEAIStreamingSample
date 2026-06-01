import Foundation

/// Extracts user-visible chat text while the model is still streaming JSON (e.g. `{"message":"Hel`).
public struct JSONMessagePreviewExtractor: Sendable {
    public init() {}

    public func streamingDisplayText(from raw: String) -> String {
        let cleaned = stripCodeFence(from: raw)
        if let preview = extractMessagePreview(from: cleaned), !preview.isEmpty {
            return preview
        }
        if cleaned.hasPrefix("{") || cleaned.hasPrefix("```json") {
            return ""
        }
        return cleaned
    }

    public func finalDisplayText(from raw: String) -> String {
        let cleaned = stripCodeFence(from: raw)
        if let json = parseJSONObject(from: cleaned),
           let message = bestMessage(from: json) {
            return message
        }
        if let preview = extractMessagePreview(from: cleaned), !preview.isEmpty {
            return preview
        }
        return cleaned
    }

    private func stripCodeFence(from raw: String) -> String {
        raw
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseJSONObject(from text: String) -> [String: Any]? {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }

    private func bestMessage(from json: [String: Any]) -> String? {
        for key in ["message", "text", "answer"] {
            if let value = json[key] as? String, !value.isEmpty { return value }
        }
        return nil
    }

    private func extractMessagePreview(from raw: String) -> String? {
        guard let keyRange = raw.range(of: "\"message\"", options: .backwards),
              let colon = raw.range(of: ":", range: keyRange.upperBound..<raw.endIndex),
              let startQuote = raw.range(of: "\"", range: colon.upperBound..<raw.endIndex) else {
            return nil
        }

        var index = startQuote.upperBound
        var escaped = false
        var collected = ""

        while index < raw.endIndex {
            let char = raw[index]
            if escaped {
                collected.append(char)
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else if char == "\"" {
                return collected
            } else {
                collected.append(char)
            }
            index = raw.index(after: index)
        }

        return collected.isEmpty ? nil : collected
    }
}
