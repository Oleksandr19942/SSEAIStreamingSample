import Foundation

public struct PendingUploadJob: Codable, Equatable, Sendable {
    public var s3Paths: [String]
    public let userId: String
    public let startedAt: Date
    public var s3UploadedAt: Date?

    public init(
        s3Paths: [String],
        userId: String,
        startedAt: Date,
        s3UploadedAt: Date? = nil
    ) {
        self.s3Paths = s3Paths
        self.userId = userId
        self.startedAt = startedAt
        self.s3UploadedAt = s3UploadedAt
    }
}

public enum UploadBatchPhase: Equatable, Codable, Sendable {
    case inFlight(startedAt: Date)
    case completed(at: Date)
}

public struct UploadBatchRecord: Codable, Equatable, Sendable {
    public let batchKey: String
    public var phase: UploadBatchPhase
    public var updatedAt: Date

    public init(batchKey: String, phase: UploadBatchPhase, updatedAt: Date) {
        self.batchKey = batchKey
        self.phase = phase
        self.updatedAt = updatedAt
    }
}

public enum UploadRecoveryDecision: Equatable, Sendable {
    case skipAlreadyCompleted
    case skipInFlightGrace
    case skipNoPaths
    case skipTooRecent
    case recover
}
