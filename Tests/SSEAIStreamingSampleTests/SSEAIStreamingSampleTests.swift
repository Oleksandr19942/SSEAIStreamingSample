import XCTest
@testable import SSEAIStreamingSample

final class SSEAIStreamingSampleTests: XCTestCase {
    func testParsesTextDeltaEvent() {
        let parser = SSEAIStreamParser()
        let line = #"data: {"type":"response.output_text.delta","delta":"Hel"}"#

        guard case .textDelta(let value)? = parser.parse(dataLine: line) else {
            return XCTFail("Expected text delta")
        }
        XCTAssertEqual(value, "Hel")
    }

    func testParsesDoneMarker() {
        let parser = SSEAIStreamParser()
        XCTAssertEqual(parser.parse(dataLine: "data: [DONE]"), .completed)
    }

    func testLineBufferSplitsChunks() {
        var buffer = SSELineBuffer()
        let first = buffer.append("data: {\"a\":1}\n")
        let second = buffer.append("data: {\"b\":2}")
        let drained = buffer.drain()

        XCTAssertEqual(first, ["data: {\"a\":1}"])
        XCTAssertEqual(second, [])
        XCTAssertEqual(drained, ["data: {\"b\":2}"])
    }
}
