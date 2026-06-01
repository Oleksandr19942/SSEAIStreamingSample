import XCTest
@testable import SSEAIStreamingSample

final class SSEAIStreamingSampleTests: XCTestCase {
    func testAccumulatorParsesDeltaAndToolCall() {
        var accumulator = ResponsesStreamAccumulator()
        accumulator.consume(dataLine: #"data: {"type":"response.output_text.delta","delta":"Hel"}"#) { delta in
            XCTAssertEqual(delta, "Hel")
        }
        accumulator.consume(dataLine: #"data: {"type":"response.function_call_arguments.done","call_id":"c1","name":"SemanticSearch","arguments":"{\"query\":\"heart\"}"}"#)

        XCTAssertEqual(accumulator.result.toolCalls.count, 1)
        XCTAssertEqual(accumulator.result.toolCalls.first?.name, "SemanticSearch")
    }

    func testAccumulatorParsesCompletedResponse() {
        var accumulator = ResponsesStreamAccumulator()
        accumulator.consume(dataLine: #"data: {"type":"response.completed","response":{"id":"resp-99","status":"completed","output":[{"type":"message","content":[{"type":"output_text","text":"Final answer"}]}]}}"#)

        XCTAssertEqual(accumulator.result.responseID, "resp-99")
        XCTAssertEqual(accumulator.result.responseStatus, "completed")
        XCTAssertEqual(accumulator.result.finalOutputText, "Final answer")
        XCTAssertTrue(accumulator.result.hasOutputItems)
        XCTAssertTrue(accumulator.result.eventTypes.contains("response.completed"))
    }

    func testAccumulatorParsesFailedResponse() {
        var accumulator = ResponsesStreamAccumulator()
        accumulator.consume(dataLine: #"data: {"type":"response.failed","response":{"id":"resp-fail","status":"failed"}}"#)

        XCTAssertEqual(accumulator.result.responseID, "resp-fail")
        XCTAssertEqual(accumulator.result.responseStatus, "failed")
        XCTAssertTrue(accumulator.result.eventTypes.contains("response.failed"))
    }

    func testAccumulatorParsesRefusalDelta() {
        var accumulator = ResponsesStreamAccumulator()
        var deltas: [String] = []
        accumulator.consume(dataLine: #"data: {"type":"response.refusal.delta","delta":"Cannot"}"#) { delta in
            deltas.append(delta)
        }

        XCTAssertEqual(deltas, ["Cannot"])
    }

    func testJSONPreviewExtractsPartialMessage() {
        let extractor = JSONMessagePreviewExtractor()
        let preview = extractor.streamingDisplayText(from: #"{"message":"Hello wor"#)
        XCTAssertEqual(preview, "Hello wor")
    }

    func testJSONPreviewHidesIncompleteJSONObject() {
        let extractor = JSONMessagePreviewExtractor()
        XCTAssertEqual(extractor.streamingDisplayText(from: "{"), "")
    }

    @MainActor
    func testToolLoopExecutesToolAndContinues() async throws {
        let loop = ToolCallingConversationLoop(maxTurns: 4)
        let executor = MockToolExecutor(outputs: ["SemanticSearch": "{\"hits\":1}"])
        var previews: [String] = []

        let streamHandler: StreamTurnHandler = { input, onDelta, _ in
            if input.payload is [[String: Any]] {
                onDelta(#"{"message":"Done"}"#)
                return StreamTurnResult(responseID: "resp-2", finalOutputText: #"{"message":"Done"}"#)
            }
            return StreamTurnResult(
                responseID: "resp-1",
                toolCalls: [
                    StreamToolCall(callID: "c1", name: "SemanticSearch", argumentsJSON: #"{"query":"x"}"#)
                ]
            )
        }

        let result = try await loop.run(
            request: ConversationLoopRequest(
                initialInput: "Hi",
                instructions: "You are helpful."
            ),
            toolExecutor: executor,
            streamTurn: streamHandler,
            requestTurn: { _ in StreamTurnResult(finalOutputText: "fallback") },
            onStreamingPreview: { previews.append($0) },
            onRateLimitRetry: { _ in }
        )

        XCTAssertEqual(result.displayText, "Done")
        XCTAssertTrue(executor.callCount >= 1)
        XCTAssertFalse(previews.isEmpty)
    }

    @MainActor
    func testNeedsNonStreamingRecoveryWhenStreamEndsEmpty() {
        let loop = ToolCallingConversationLoop()
        let turn = StreamTurnResult(eventTypes: [])
        XCTAssertTrue(loop.needsNonStreamingRecovery(turn: turn, buffer: ""))
    }

    func testLineBufferSplitsChunks() {
        var buffer = SSELineBuffer()
        XCTAssertEqual(buffer.append("data: {}\n"), ["data: {}"])
        XCTAssertEqual(buffer.drain(), [])
    }
}

private final class MockToolExecutor: StreamToolExecuting, @unchecked Sendable {
    let outputs: [String: String]
    private(set) var callCount = 0

    init(outputs: [String: String]) {
        self.outputs = outputs
    }

    func execute(name: String, argumentsJSON: String) async -> String {
        callCount += 1
        return outputs[name] ?? "{}"
    }
}
