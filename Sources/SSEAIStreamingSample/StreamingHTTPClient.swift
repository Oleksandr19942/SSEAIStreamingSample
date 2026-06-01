import Foundation

public struct StreamingHTTPClient: Sendable {
    private let session: URLSession
    private let retryExecutor: RateLimitRetryExecutor

    public init(session: URLSession = .shared, maxRateLimitRetries: Int = 2) {
        self.session = session
        self.retryExecutor = RateLimitRetryExecutor(maxRetries: maxRateLimitRetries)
    }

    public func streamTurn(
        request: URLRequest,
        onFirstEvent: (@Sendable () async -> Void)? = nil,
        onRateLimitRetry: (@Sendable () async -> Void)? = nil,
        onTextDelta: (@Sendable (String) -> Void)? = nil
    ) async throws -> StreamTurnResult {
        try await retryExecutor.run(onRetry: onRateLimitRetry) {
            try await self.executeStream(
                request: request,
                onFirstEvent: onFirstEvent,
                onTextDelta: onTextDelta
            )
        }
    }

    private func executeStream(
        request: URLRequest,
        onFirstEvent: (@Sendable () async -> Void)?,
        onTextDelta: (@Sendable (String) -> Void)?
    ) async throws -> StreamTurnResult {
        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw StreamClientError.invalidResponse
        }

        if http.statusCode == 429 {
            let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
            throw StreamClientError.rateLimited(retryAfter: retryAfter)
        }

        guard (200..<300).contains(http.statusCode) else {
            throw StreamClientError.httpStatus(http.statusCode)
        }

        var accumulator = ResponsesStreamAccumulator()
        var didEmitFirst = false

        for try await line in bytes.lines {
            if Task.isCancelled { break }

            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("data:") else { continue }

            if !didEmitFirst {
                didEmitFirst = true
                if let onFirstEvent { await onFirstEvent() }
            }

            accumulator.consume(dataLine: trimmed, onTextDelta: onTextDelta)
        }

        return accumulator.result
    }
}
