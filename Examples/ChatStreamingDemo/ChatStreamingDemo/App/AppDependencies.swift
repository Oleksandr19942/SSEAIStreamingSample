import Foundation
import SSEAIStreamingSample

/// Lightweight dependency container (production uses `AppContainer`).
@MainActor
final class AppDependencies: ObservableObject {
    let conversationService = DemoConversationService()

    func makeChatViewModel() -> ChatDemoViewModel {
        ChatDemoViewModel(service: conversationService)
    }
}
