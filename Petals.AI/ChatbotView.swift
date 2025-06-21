// In ChatbotView.swift
import SwiftUI
struct ChatbotView: View {
    @StateObject private var viewModel = ChatbotViewModel()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Logo
            HStack {
                Image("icon")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Text("Petals AI")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                        }
                        if viewModel.isLoading {
                            TypingIndicator()
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) {
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                    }
                }
            }
            
            // Input area
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $viewModel.inputMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isLoading)
                    
                    Button(action: {
                        viewModel.sendMessage()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
                .padding()
            }
            .background(.ultraThinMaterial)
        }
        .navigationTitle("AI Assistant")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.content)
                .padding()
                .background(
                    message.isUser 
                    ? LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [
                            Color(colorScheme == .dark ? .systemGray6 : .systemGray5),
                            Color(colorScheme == .dark ? .systemGray6 : .systemGray5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(20)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color(colorScheme == .dark ? .systemGray3 : .systemGray))
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(0.2 * Double(index)),
                        value: animationOffset
                    )
            }
        }
        .padding()
        .background(Color(colorScheme == .dark ? .systemGray6 : .systemGray5))
        .cornerRadius(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .onAppear {
            animationOffset = -5
        }
    }
}

#Preview {
    NavigationView {
        ChatbotView()
    }
}
