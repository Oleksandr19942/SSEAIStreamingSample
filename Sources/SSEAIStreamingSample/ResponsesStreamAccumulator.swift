import Foundation

/// Accumulates Azure OpenAI Responses-style SSE JSON events into a single turn result.
public struct ResponsesStreamAccumulator: Sendable {
    private(set) var result = StreamTurnResult()

    public init() {}

    public mutating func consume(dataLine: String, onTextDelta: (@Sendable (String) -> Void)? = nil) {
        let trimmed = dataLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("data:") else { return }

        let jsonPart = trimmed.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
        if jsonPart == "[DONE]" { return }

        guard let data = jsonPart.data(using: .utf8),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        if let responseID = payload["response_id"] as? String, !responseID.isEmpty {
            result.responseID = responseID
        }
        if let response = payload["response"] as? [String: Any],
           let responseID = response["id"] as? String, !responseID.isEmpty {
            result.responseID = responseID
        }

        let eventType = payload["type"] as? String
        if let eventType { result.eventTypes.append(eventType) }

        switch eventType {
        case "response.output_text.delta", "response.refusal.delta":
            if let delta = payload["delta"] as? String {
                onTextDelta?(delta)
            }
        case "response.output_text.done":
            if let text = payload["text"] as? String, !text.isEmpty {
                result.finalOutputText = text
            }
        case "response.function_call_arguments.done":
            if let toolCall = extractToolCall(from: payload) {
                appendToolCall(toolCall)
            }
        case "response.output_item.done":
            if let item = payload["item"] as? [String: Any],
               let toolCall = extractToolCall(fromOutputItem: item) {
                appendToolCall(toolCall)
            }
        case "response.completed", "response.failed", "response.incomplete", "response.cancelled":
            if let response = payload["response"] as? [String: Any] {
                mergeCompletion(from: response)
            }
        case "error":
            if let message = payload["message"] as? String, !message.isEmpty {
                result.failureMessage = message
            }
        default:
            break
        }
    }

    private mutating func mergeCompletion(from response: [String: Any]) {
        result.responseStatus = response["status"] as? String
        if let output = response["output"] as? [[String: Any]], !output.isEmpty {
            result.hasOutputItems = true
            for item in output {
                if let toolCall = extractToolCall(fromOutputItem: item) {
                    appendToolCall(toolCall)
                }
            }
        }
        if let text = extractText(from: response), !text.isEmpty {
            result.finalOutputText = text
        }
    }

    private mutating func appendToolCall(_ toolCall: StreamToolCall) {
        guard !result.toolCalls.contains(where: { $0.callID == toolCall.callID && $0.name == toolCall.name }) else {
            return
        }
        result.toolCalls.append(toolCall)
    }

    private func extractToolCall(from payload: [String: Any]) -> StreamToolCall? {
        guard let callID = payload["call_id"] as? String, !callID.isEmpty,
              let name = payload["name"] as? String, !name.isEmpty,
              let arguments = argumentsJSON(from: payload["arguments"]) else {
            return nil
        }
        return StreamToolCall(callID: callID, name: name, argumentsJSON: arguments)
    }

    private func extractToolCall(fromOutputItem item: [String: Any]) -> StreamToolCall? {
        guard (item["type"] as? String) == "function_call",
              let callID = item["call_id"] as? String, !callID.isEmpty,
              let name = item["name"] as? String, !name.isEmpty,
              let arguments = argumentsJSON(from: item["arguments"]) else {
            return nil
        }
        return StreamToolCall(callID: callID, name: name, argumentsJSON: arguments)
    }

    private func argumentsJSON(from value: Any?) -> String? {
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "{}" : trimmed
        }
        if let object = value as? [String: Any],
           let data = try? JSONSerialization.data(withJSONObject: object),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return nil
    }

    private func extractText(from response: [String: Any]) -> String? {
        guard let output = response["output"] as? [[String: Any]] else { return nil }
        for item in output {
            if let content = item["content"] as? [[String: Any]] {
                for part in content {
                    if let text = part["text"] as? String, !text.isEmpty { return text }
                }
            }
        }
        return nil
    }
}
