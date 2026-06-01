import Foundation

public protocol StreamToolExecuting: Sendable {
    func execute(name: String, argumentsJSON: String) async -> String
}

public typealias StreamTurnHandler = @Sendable (
    _ input: StreamLoopInput,
    _ onTextDelta: @escaping @Sendable (String) -> Void,
    _ onRateLimitRetry: @escaping @Sendable () -> Void
) async throws -> StreamTurnResult

@MainActor
public struct ToolCallingConversationLoop {
    public let maxTurns: Int
    public let previewExtractor: JSONMessagePreviewExtractor

    public init(maxTurns: Int = 32, previewExtractor: JSONMessagePreviewExtractor = .init()) {
        self.maxTurns = maxTurns
        self.previewExtractor = previewExtractor
    }

    /// Mirrors production chat orchestration: stream → tools → stream again, with preview + recovery.
    public func run(
        request: ConversationLoopRequest,
        toolExecutor: StreamToolExecuting,
        streamTurn: StreamTurnHandler,
        requestTurn: @Sendable (_ input: StreamLoopInput) async throws -> StreamTurnResult,
        onStreamingPreview: @escaping @Sendable (String) -> Void,
        onRateLimitRetry: @escaping @Sendable (String) -> Void
    ) async throws -> ConversationLoopResult {
        var nextInput = request.initialInput
        var previousResponseID = request.initialPreviousResponseID
        var rawBuffer = ""
        var toolCache: [String: String] = [:]

        for _ in 0..<maxTurns {
            try Task.checkCancellation()

            let baseBuffer = rawBuffer
            let attemptBuffer = AttemptBuffer()

            var turn = try await streamTurn(
                StreamLoopInput(
                    payload: nextInput,
                    previousResponseID: previousResponseID,
                    instructions: request.instructions
                ),
                { delta in
                    attemptBuffer.append(delta)
                    let preview = previewExtractor.streamingDisplayText(from: baseBuffer + attemptBuffer.text)
                    if !preview.isEmpty {
                        onStreamingPreview(preview)
                    }
                },
                {
                    let preview = previewExtractor.streamingDisplayText(from: baseBuffer)
                    onRateLimitRetry(preview)
                }
            )

            if !attemptBuffer.text.isEmpty {
                rawBuffer = baseBuffer + attemptBuffer.text
            }

            if needsNonStreamingRecovery(turn: turn, buffer: rawBuffer) {
                turn = try await requestTurn(
                    StreamLoopInput(
                        payload: nextInput,
                        previousResponseID: previousResponseID,
                        instructions: request.instructions
                    )
                )
            }

            if let final = turn.finalOutputText?.trimmingCharacters(in: .whitespacesAndNewlines),
               !final.isEmpty,
               rawBuffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || final.count > rawBuffer.count {
                rawBuffer = final
                let preview = previewExtractor.streamingDisplayText(from: rawBuffer)
                if !preview.isEmpty { onStreamingPreview(preview) }
            }

            if !turn.toolCalls.isEmpty {
                guard let responseID = turn.responseID ?? previousResponseID, !responseID.isEmpty else {
                    throw StreamClientError.server("Tool calls returned without response context.")
                }
                previousResponseID = responseID

                var outputs: [[String: Any]] = []
                for call in turn.toolCalls {
                    let signature = "\(call.name)|\(call.argumentsJSON)"
                    let output: String
                    if let cached = toolCache[signature] {
                        output = cached
                    } else {
                        output = await toolExecutor.execute(
                            name: call.name,
                            argumentsJSON: call.argumentsJSON
                        )
                        toolCache[signature] = output
                    }
                    outputs.append([
                        "type": "function_call_output",
                        "call_id": call.callID,
                        "output": output
                    ])
                }
                nextInput = outputs
                continue
            }

            guard hasVisibleOutput(turn: turn, buffer: rawBuffer) else {
                throw StreamClientError.server("Model completed without visible text output.")
            }

            return ConversationLoopResult(
                displayText: previewExtractor.finalDisplayText(from: rawBuffer),
                responseID: turn.responseID
            )
        }

        throw StreamClientError.server("Tool loop exceeded \(maxTurns) turns.")
    }

    public func needsNonStreamingRecovery(turn: StreamTurnResult, buffer: String) -> Bool {
        guard turn.toolCalls.isEmpty, !hasVisibleOutput(turn: turn, buffer: buffer) else {
            return false
        }
        if turn.hasOutputItems { return false }

        let completionEvents: Set<String> = [
            "response.completed", "response.incomplete", "response.failed", "response.cancelled"
        ]
        if !completionEvents.isDisjoint(with: turn.eventTypes) { return false }

        let terminalStatuses: Set<String> = ["completed", "incomplete", "failed", "cancelled"]
        if let status = turn.responseStatus?.lowercased(), terminalStatuses.contains(status) {
            return false
        }
        return true
    }

    private func hasVisibleOutput(turn: StreamTurnResult, buffer: String) -> Bool {
        let hasBuffer = !buffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasFinal = !(turn.finalOutputText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        return hasBuffer || hasFinal
    }
}

public struct ConversationLoopRequest: @unchecked Sendable {
    public let initialInput: Any
    public let initialPreviousResponseID: String?
    public let instructions: String

    public init(initialInput: Any, initialPreviousResponseID: String? = nil, instructions: String) {
        self.initialInput = initialInput
        self.initialPreviousResponseID = initialPreviousResponseID
        self.instructions = instructions
    }
}

public struct ConversationLoopResult: Sendable, Equatable {
    public let displayText: String
    public let responseID: String?
}

public struct StreamLoopInput: @unchecked Sendable {
    public let payload: Any
    public let previousResponseID: String?
    public let instructions: String

    public init(payload: Any, previousResponseID: String?, instructions: String) {
        self.payload = payload
        self.previousResponseID = previousResponseID
        self.instructions = instructions
    }
}

private final class AttemptBuffer: @unchecked Sendable {
    var text = ""

    func append(_ delta: String) {
        text += delta
    }
}
