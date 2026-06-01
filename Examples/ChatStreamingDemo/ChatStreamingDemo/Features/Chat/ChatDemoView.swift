import SwiftUI

struct ChatDemoView: View {
    @ObservedObject var viewModel: ChatDemoViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Ask about your health data…", text: $viewModel.draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)

                Button {
                    Task { await viewModel.send() }
                } label: {
                    Image(systemName: viewModel.isStreaming ? "hourglass" : "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(viewModel.isStreaming || viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()

            Text(viewModel.statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
    }
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.text.isEmpty && message.isStreaming ? "…" : message.text)
                    .padding(12)
                    .background(message.role == .user ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                if message.isStreaming {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }
}

#Preview {
    NavigationStack {
        ChatDemoView(viewModel: ChatDemoViewModel(service: DemoConversationService()))
    }
}
