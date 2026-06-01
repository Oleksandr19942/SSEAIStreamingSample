import Foundation

public struct RateLimitRetryExecutor: Sendable {
    public let maxRetries: Int

    public init(maxRetries: Int = 2) {
        self.maxRetries = maxRetries
    }

    public func run<T>(
        onRetry: (@Sendable () async -> Void)? = nil,
        operation: @Sendable () async throws -> T
    ) async throws -> T {
        var attempt = 0

        while true {
            do {
                return try await operation()
            } catch let error as StreamClientError {
                guard case .rateLimited(let retryAfter) = error, attempt < maxRetries else {
                    throw error
                }
                attempt += 1
                let delay = retryDelay(retryAfter: retryAfter, attempt: attempt)
                if let onRetry { await onRetry() }
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }

    private func retryDelay(retryAfter: TimeInterval?, attempt: Int) -> TimeInterval {
        if let retryAfter, retryAfter > 0 { return retryAfter }
        return min(8, pow(2.0, Double(attempt)))
    }
}
