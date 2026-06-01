import Foundation

@MainActor
final class ChatDemoViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published var draft = ""
    @Published private(set) var isStreaming = false
    @Published private(set) var statusText = "Ready"

    private var service: DemoConversationService

    init(service: DemoConversationService) {
        self.service = service
        messages = [
            ChatMessage(
                role: .assistant,
                text: "Ask about sleep, heart rate, or activity. The demo uses the same SSE accumulator and tool loop as production.",
                isStreaming: false
            )
        ]
    }

    func replaceService(_ service: DemoConversationService) {
        self.service = service
    }

    func send() async {
        let prompt = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isStreaming else { return }

        draft = ""
        messages.append(ChatMessage(role: .user, text: prompt, isStreaming: false))

        let assistantID = UUID()
        messages.append(ChatMessage(role: .assistant, text: "", isStreaming: true))
        isStreaming = true
        statusText = "Streaming SSE…"

        do {
            let finalText = try await service.runToolLoopDemo { [weak self] preview in
                guard let self else { return }
                updateAssistantMessage(id: assistantID, text: preview, isStreaming: true)
            }
            updateAssistantMessage(id: assistantID, text: finalText, isStreaming: false)
            statusText = "Completed"
        } catch {
            updateAssistantMessage(
                id: assistantID,
                text: "Stream failed: \(error.localizedDescription)",
                isStreaming: false
            )
            statusText = "Failed"
        }

        isStreaming = false
    }

    private func updateAssistantMessage(id: UUID, text: String, isStreaming: Bool) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index] = ChatMessage(id: id, role: .assistant, text: text, isStreaming: isStreaming)
    }
}
