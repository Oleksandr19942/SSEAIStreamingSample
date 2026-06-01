import SwiftUI
import SSEAIStreamingSample

struct UploadRecoveryDemoView: View {
    @State private var s3Uploaded = true
    @State private var hasPaths = true
    @State private var inFlight = false
    @State private var batchCompleted = false
    @State private var startedAt = Date().addingTimeInterval(-200)
    @State private var decision: UploadRecoveryDecision = .skipTooRecent

    var body: some View {
        List {
            Section("Simulate medical upload job") {
                Toggle("S3 phase completed", isOn: $s3Uploaded)
                Toggle("Has S3 paths", isOn: $hasPaths)
                Toggle("GraphQL in flight", isOn: $inFlight)
                Toggle("Batch already completed", isOn: $batchCompleted)

                DatePicker("Job started", selection: $startedAt)
            }

            Section("Recovery decision") {
                Text(decisionLabel)
                    .font(.headline)
                Text(decisionHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Policies") {
                LabeledContent("Orphan timeout", value: "\(Int(UploadRecovery.orphanJobTimeout))s")
                LabeledContent("In-flight grace", value: "\(Int(UploadRecovery.inFlightGraphQLGracePeriod))s")
                LabeledContent("Batch TTL", value: "7 days")
            }
        }
        .onChange(of: s3Uploaded) { _, _ in recompute() }
        .onChange(of: hasPaths) { _, _ in recompute() }
        .onChange(of: inFlight) { _, _ in recompute() }
        .onChange(of: batchCompleted) { _, _ in recompute() }
        .onChange(of: startedAt) { _, _ in recompute() }
        .onAppear { recompute() }
    }

    private var decisionLabel: String {
        switch decision {
        case .recover: return "Recover"
        case .skipAlreadyCompleted: return "Skip — batch completed"
        case .skipInFlightGrace: return "Skip — in-flight grace"
        case .skipNoPaths: return "Skip — no paths"
        case .skipTooRecent: return "Skip — too recent"
        }
    }

    private var decisionHint: String {
        switch decision {
        case .recover:
            return "Matches production orphan recovery after S3 success or timeout."
        case .skipInFlightGrace:
            return "Avoids duplicate GraphQL while server request may still run."
        default:
            return "State machine guard from UploadBatchStateMachine."
        }
    }

    private func recompute() {
        let job = PendingUploadJob(
            s3Paths: hasPaths ? ["public/users/demo/scan.pdf"] : [],
            userId: "demo",
            startedAt: startedAt,
            s3UploadedAt: s3Uploaded ? Date() : nil
        )
        let phase: UploadBatchPhase? = {
            if batchCompleted { return .completed(at: Date()) }
            if inFlight { return .inFlight(startedAt: Date()) }
            return nil
        }()
        decision = UploadBatchStateMachine.recoveryDecision(job: job, phase: phase)
    }
}

#Preview {
    NavigationStack {
        UploadRecoveryDemoView()
    }
}
