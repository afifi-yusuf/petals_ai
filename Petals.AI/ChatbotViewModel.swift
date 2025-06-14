// In ChatbotViewModel.swift
import SwiftUI
import FoundationModels

// A single message in our chat history.
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

class ChatbotViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputMessage: String = ""
    @Published var isLoading: Bool = false
    
    init() {
        // Add welcome message
        messages.append(ChatMessage(
            content: "Hello! I'm Petal, your health and wellness companion. How can I help you today?",
            isUser: false
        ))
    }
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(content: inputMessage, isUser: true)
        messages.append(userMessage)

        let currentInput = inputMessage
        inputMessage = ""
        isLoading = true

        Task {
            if #available(iOS 26.0, *) {
                do {
                    let session = LanguageModelSession()
                    let response = try await session.respond(to: Prompt(currentInput))
                    let responseContent = response.content
                    await MainActor.run {
                        messages.append(ChatMessage(content: responseContent, isUser: false))
                        isLoading = false
                    }
                } catch {
                    print("Error: \(error)")
                    await MainActor.run {
                        messages.append(ChatMessage(
                            content: "Sorry, I encountered an error. Please try again.",
                            isUser: false
                        ))
                        isLoading = false
                    }
                }
            } else {
                // Fallback for iOS versions earlier than 26.0
                let reply = generateResponse(to: currentInput)
                await MainActor.run {
                    messages.append(ChatMessage(content: reply, isUser: false))
                    isLoading = false
                }
            }
        }
    }
    
    private func generateResponse(to message: String) -> String {
        let lowercasedMessage = message.lowercased()
        
        if lowercasedMessage.contains("hello") || lowercasedMessage.contains("hi") {
            return "Hello! How can I help you today?"
        } else if lowercasedMessage.contains("meditation") {
            return "I can help you with meditation techniques. Would you like to try a guided session?"
        } else if lowercasedMessage.contains("stress") {
            return "I understand you're feeling stressed. Let's try some deep breathing exercises together."
        } else if lowercasedMessage.contains("health") {
            return "I can help you track your health metrics and provide personalized recommendations."
        } else if lowercasedMessage.contains("thank") {
            return "You're welcome! Is there anything else I can help you with?"
        } else if lowercasedMessage.contains("bye") || lowercasedMessage.contains("goodbye") {
            return "Take care! Remember to stay hydrated and take breaks when needed."
        } else {
            return "I'm here to help with your health and wellness journey. What would you like to know more about?"
        }
    }
}

