import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ChatDemoContainer()
                    .navigationTitle("AI Chat")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right")
            }

            NavigationStack {
                HealthKitDemoView()
                    .navigationTitle("Apple Health")
            }
            .tabItem {
                Label("Health", systemImage: "heart.text.square")
            }

            NavigationStack {
                UploadRecoveryDemoView()
                    .navigationTitle("Upload Recovery")
            }
            .tabItem {
                Label("Uploads", systemImage: "arrow.up.doc")
            }
        }
    }
}

private struct ChatDemoContainer: View {
    @EnvironmentObject private var dependencies: AppDependencies
    @StateObject private var viewModel = ChatDemoViewModel(service: DemoConversationService())

    var body: some View {
        ChatDemoView(viewModel: viewModel)
            .onAppear {
                viewModel.replaceService(dependencies.conversationService)
            }
    }
}
