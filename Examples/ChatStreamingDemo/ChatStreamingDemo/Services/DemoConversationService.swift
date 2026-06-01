import Foundation
import SSEAIStreamingSample

/// Mock streaming service that exercises `ResponsesStreamAccumulator` + `ToolCallingConversationLoop`.
@MainActor
final class DemoConversationService {
    func streamHealthAnswer(
        onPreview: @escaping (String) -> Void
    ) async throws -> String {
        var accumulator = ResponsesStreamAccumulator()
        var buffer = ""

        for line in DemoStreamScript.healthAnswerLines {
            try await Task.sleep(nanoseconds: 180_000_000)
            accumulator.consume(dataLine: line) { delta in
                buffer += delta
                if !buffer.isEmpty {
                    onPreview(buffer)
                }
            }
        }

        if let final = accumulator.result.finalOutputText, !final.isEmpty {
            return final
        }
        return buffer
    }

    func runToolLoopDemo(
        onPreview: @escaping (String) -> Void
    ) async throws -> String {
        let loop = ToolCallingConversationLoop(maxTurns: 3)
        let executor = DemoToolExecutor()

        let result = try await loop.run(
            request: ConversationLoopRequest(
                initialInput: "How is my sleep this week?",
                instructions: "You are a helpful health assistant."
            ),
            toolExecutor: executor,
            streamTurn: { input, onDelta, _ in
                if input.payload is [[String: Any]] {
                    var buffer = ""
                    for line in DemoStreamScript.healthAnswerLines {
                        var accumulator = ResponsesStreamAccumulator()
                        accumulator.consume(dataLine: line) { delta in
                            buffer += delta
                            onDelta(delta)
                        }
                    }
                    return StreamTurnResult(
                        responseID: "resp-2",
                        finalOutputText: buffer.isEmpty
                            ? "Based on your recent Apple Health data, your resting heart rate trend looks stable."
                            : buffer
                    )
                }
                return StreamTurnResult(
                    responseID: "resp-1",
                    toolCalls: [
                        StreamToolCall(
                            callID: "call-health",
                            name: AppleHealthAIToolDefinition.toolName,
                            argumentsJSON: #"{"limit":14}"#
                        )
                    ]
                )
            },
            requestTurn: { _ in
                StreamTurnResult(finalOutputText: "Recovered final answer.")
            },
            onStreamingPreview: onPreview,
            onRateLimitRetry: { _ in }
        )

        return result.displayText
    }

}

private struct DemoToolExecutor: StreamToolExecuting {
    func execute(name: String, argumentsJSON: String) async -> String {
        #"{"snapshots":14,"source":"AppleHealth","metrics":["sleep","heartRate","steps"]}"#
    }
}
