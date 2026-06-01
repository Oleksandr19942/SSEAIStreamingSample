import Foundation

struct ChatMessage: Identifiable, Equatable {
    enum Role: String {
        case user
        case assistant
    }

    let id: UUID
    let role: Role
    let text: String
    let isStreaming: Bool

    init(id: UUID = UUID(), role: Role, text: String, isStreaming: Bool) {
        self.id = id
        self.role = role
        self.text = text
        self.isStreaming = isStreaming
    }
}
