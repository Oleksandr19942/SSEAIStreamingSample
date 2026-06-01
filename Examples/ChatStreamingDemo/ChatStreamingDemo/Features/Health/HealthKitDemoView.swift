import SwiftUI
import SSEAIStreamingSample

struct HealthKitDemoView: View {
    private let tool = AppleHealthAIToolDefinition.makeOpenAITool()

    var body: some View {
        List {
            Section("Production flow") {
                Label("HealthKit authorization + sample queries", systemImage: "checkmark.seal")
                Label("Typed payload sync to backend", systemImage: "arrow.triangle.2.circlepath")
                Label("AI tool: GetLatestAppleHealthRecords", systemImage: "function")
                Label("SemanticSearch includes AppleHealth", systemImage: "magnifyingglass")
            }

            Section("Synced domains") {
                ForEach(HealthDataDomain.allCases, id: \.self) { domain in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(domain.rawValue.capitalized)
                            .font(.headline)
                        Text(domain.productionExamples)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("AI tool (reference)") {
                LabeledContent("Name", value: tool["name"] as? String ?? "—")
                Text(tool["description"] as? String ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HealthKitDemoView()
    }
}
