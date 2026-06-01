import XCTest
@testable import SSEAIStreamingSample

final class ProductionPatternsTests: XCTestCase {
    func testAppleHealthToolDefinitionName() {
        let tool = AppleHealthAIToolDefinition.makeOpenAITool()
        XCTAssertEqual(tool["name"] as? String, "GetLatestAppleHealthRecords")
        XCTAssertEqual(tool["strict"] as? Bool, true)
    }

    func testSemanticSearchIncludesAppleHealthScope() {
        XCTAssertTrue(SemanticSearchScope.allCases.contains(.appleHealth))
    }

    func testAIToolCatalogHasSevenTools() {
        XCTAssertEqual(AIToolCatalog.allCases.count, 7)
        XCTAssertTrue(AIToolCatalog.allCases.map(\.name).contains("GetLatestAppleHealthRecords"))
    }

    func testRecoveryDecisionWhenBatchCompletedSkips() {
        let job = PendingUploadJob(s3Paths: ["path"], userId: "u", startedAt: Date(), s3UploadedAt: Date())
        let decision = UploadBatchStateMachine.recoveryDecision(
            job: job,
            phase: .completed(at: Date())
        )
        XCTAssertEqual(decision, .skipAlreadyCompleted)
    }

    func testRecoveryDecisionWhenS3UploadedRecovers() {
        let job = PendingUploadJob(s3Paths: ["a.pdf"], userId: "u", startedAt: Date(), s3UploadedAt: Date())
        XCTAssertEqual(
            UploadBatchStateMachine.recoveryDecision(job: job, phase: nil),
            .recover
        )
    }

    func testRecoveryDecisionRespectsInFlightGrace() {
        let job = PendingUploadJob(s3Paths: ["path"], userId: "u", startedAt: Date(), s3UploadedAt: Date())
        let decision = UploadBatchStateMachine.recoveryDecision(
            job: job,
            phase: .inFlight(startedAt: Date())
        )
        XCTAssertEqual(decision, .skipInFlightGrace)
    }

    func testPruneRemovesExpiredBatches() {
        let expired = Date().addingTimeInterval(-(UploadRecovery.batchTTL + 60))
        let fresh = Date()
        let records = [
            UploadBatchRecord(batchKey: "old", phase: .completed(at: expired), updatedAt: expired),
            UploadBatchRecord(batchKey: "new", phase: .completed(at: fresh), updatedAt: fresh)
        ]
        let pruned = UploadBatchStateMachine.prune(records: records, now: Date())
        XCTAssertEqual(pruned.map(\.batchKey), ["new"])
    }

    func testPruneKeepsMaxStoredBatches() {
        let now = Date()
        let records = (0..<UploadRecovery.maxStoredBatches + 10).map { index in
            UploadBatchRecord(
                batchKey: "batch-\(index)",
                phase: .completed(at: now),
                updatedAt: now.addingTimeInterval(TimeInterval(-index))
            )
        }
        let pruned = UploadBatchStateMachine.prune(records: records, now: now)
        XCTAssertEqual(pruned.count, UploadRecovery.maxStoredBatches)
        XCTAssertEqual(pruned.first?.batchKey, "batch-0")
    }
}
