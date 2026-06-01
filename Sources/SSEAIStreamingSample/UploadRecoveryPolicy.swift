import Foundation

/// Timeouts and retention for medical-record upload recovery (production `UploadRecovery`).
public enum UploadRecovery {
    public static let orphanJobTimeout: TimeInterval = 180
    /// Do not retry GraphQL while a foreground request may still be in flight on the server.
    public static let inFlightGraphQLGracePeriod: TimeInterval = 120
    public static let batchTTL: TimeInterval = 7 * 24 * 60 * 60
    public static let maxStoredBatches = 50
}

/// Batch deduplication and orphan recovery decisions for S3 → GraphQL medical uploads.
public enum UploadBatchStateMachine {
    public static func batchKey(for paths: [String]) -> String {
        paths.sorted().joined(separator: "|")
    }

    public static func recoveryDecision(
        job: PendingUploadJob,
        phase: UploadBatchPhase?,
        now: Date = Date()
    ) -> UploadRecoveryDecision {
        if case .completed = phase {
            return .skipAlreadyCompleted
        }
        if case .inFlight(let startedAt) = phase,
           now.timeIntervalSince(startedAt) < UploadRecovery.inFlightGraphQLGracePeriod {
            return .skipInFlightGrace
        }
        if job.s3UploadedAt != nil {
            return job.s3Paths.isEmpty ? .skipNoPaths : .recover
        }
        if now.timeIntervalSince(job.startedAt) > UploadRecovery.orphanJobTimeout {
            return job.s3Paths.isEmpty ? .skipNoPaths : .recover
        }
        return .skipTooRecent
    }

    public static func prune(
        records: [UploadBatchRecord],
        now: Date = Date()
    ) -> [UploadBatchRecord] {
        let fresh = records.filter { now.timeIntervalSince($0.updatedAt) <= UploadRecovery.batchTTL }
        let sorted = fresh.sorted { $0.updatedAt > $1.updatedAt }
        if sorted.count <= UploadRecovery.maxStoredBatches {
            return sorted
        }
        return Array(sorted.prefix(UploadRecovery.maxStoredBatches))
    }

    public static func upsertPhase(
        _ phase: UploadBatchPhase,
        for paths: [String],
        in records: [UploadBatchRecord],
        now: Date = Date()
    ) -> [UploadBatchRecord] {
        guard !paths.isEmpty else { return records }
        let key = batchKey(for: paths)
        var updated = records.filter { $0.batchKey != key }
        updated.append(
            UploadBatchRecord(batchKey: key, phase: phase, updatedAt: now)
        )
        return prune(records: updated, now: now)
    }

    public static func phase(
        for paths: [String],
        in records: [UploadBatchRecord]
    ) -> UploadBatchPhase? {
        guard !paths.isEmpty else { return nil }
        let key = batchKey(for: paths)
        return records.first { $0.batchKey == key }?.phase
    }
}
