import Foundation

public enum SSEAIStreamEvent: Sendable, Equatable {
    case textDelta(String)
    case completed
    case unknown(eventType: String)
}

public struct SSEAIStreamParser: Sendable {
    public init() {}

    /// Parses one SSE `data:` JSON line from Azure OpenAI Responses-style streams.
    public func parse(dataLine: String) -> SSEAIStreamEvent? {
        let trimmed = dataLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("data:") else { return nil }

        let jsonPart = trimmed.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
        if jsonPart == "[DONE]" { return .completed }
        guard let data = jsonPart.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let eventType = object["type"] as? String ?? ""
        if eventType == "response.output_text.delta",
           let delta = object["delta"] as? String {
            return .textDelta(delta)
        }

        return .unknown(eventType: eventType)
    }
}
