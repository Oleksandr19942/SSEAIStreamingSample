import Foundation

public enum StreamingHTTPClientError: Error, LocalizedError {
    case invalidResponse
    case httpStatus(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid HTTP response."
        case .httpStatus(let code):
            return "Unexpected HTTP status: \(code)."
        }
    }
}

/// Minimal URLSession-based SSE consumer for AI chat-style streaming APIs.
public struct StreamingHTTPClient: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Streams UTF-8 text chunks and surfaces parsed AI text deltas.
    public func stream(
        request: URLRequest,
        onEvent: @escaping @Sendable (SSEAIStreamEvent) -> Void
    ) async throws {
        var lineBuffer = SSELineBuffer()
        let parser = SSEAIStreamParser()

        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw StreamingHTTPClientError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw StreamingHTTPClientError.httpStatus(http.statusCode)
        }

        for try await chunk in bytes.lines {
            for line in lineBuffer.append(chunk) {
                guard line.hasPrefix("data:") else { continue }
                if let event = parser.parse(dataLine: line) {
                    onEvent(event)
                }
            }
        }

        for line in lineBuffer.drain() where line.hasPrefix("data:") {
            if let event = parser.parse(dataLine: line) {
                onEvent(event)
            }
        }
    }
}
