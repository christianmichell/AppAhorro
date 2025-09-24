import SwiftUI

/// Conversational assistant view backed by the query engine and AI responses.
struct AssistantContainerView: View {
    @EnvironmentObject private var assistant: AssistantViewModel
    @State private var message: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(assistant.conversation) { entry in
                                MessageBubble(message: entry)
                                    .id(entry.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: assistant.conversation.count) { _ in
                        if let last = assistant.conversation.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                HStack {
                    TextField("Pregúntame sobre tus gastos...", text: $message)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        assistant.send(message)
                        message = ""
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .padding(8)
                    }
                    .disabled(message.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Asistente financiero")
        }
    }
}

private struct MessageBubble: View {
    let message: AssistantViewModel.Message

    var body: some View {
        HStack {
            if message.role == .assistant { Spacer() }
            Text(message.text)
                .padding(12)
                .background(message.role == .assistant ? Color.accentColor.opacity(0.2) : Color.blue.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if message.role == .user { Spacer() }
        }
        .frame(maxWidth: .infinity)
    }
}
