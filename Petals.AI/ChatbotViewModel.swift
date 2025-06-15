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
    
    private var currentSession: LanguageModelSession?
    
    init() {
        // Add welcome message
        messages.append(ChatMessage(
            content: "Hello! I'm Petal, your health and wellness companion. How can I help you today?",
            isUser: false
        ))
        
        // Initialize session
        initializeSession()
    }
    
    private func initializeSession() {
        currentSession = LanguageModelSession(instructions: """
            You are a wellness and meditation coach. Provide guidance and support to the user. Keep responses concise and focused on wellness, meditation, and mental health.
            """)
    }
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessage(content: inputMessage, isUser: true)
        messages.append(userMessage)

        let currentInput = inputMessage
        inputMessage = ""
        isLoading = true

        Task {
            do {
                guard let session = currentSession else {
                    throw NSError(domain: "SessionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Session not initialized"])
                }
                
                let response = try await session.respond(to: Prompt(currentInput))
                let responseContent = response.content
                await MainActor.run {
                    messages.append(ChatMessage(content: responseContent, isUser: false))
                    isLoading = false
                }
            } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
                // Handle context limit exceeded
                print("Context window exceeded, creating new session with condensed history")
                
                // Create new session with condensed history
                currentSession = createNewSessionWithHistory(previousSession: currentSession!)
                
                // Retry with new session
                do {
                    let response = try await currentSession!.respond(to: Prompt(currentInput))
                    let responseContent = response.content
                    
                    await MainActor.run {
                        messages.append(ChatMessage(content: responseContent, isUser: false))
                        isLoading = false
                    }
                    
                } catch {
                    print("Error after session reset: \(error)")
                    await MainActor.run {
                        messages.append(ChatMessage(
                            content: "Sorry, I encountered an error. Please try again.",
                            isUser: false
                        ))
                        isLoading = false
                    }
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
        }
    }
    
    private func createNewSessionWithHistory(previousSession: LanguageModelSession) -> LanguageModelSession {
        let allEntries = previousSession.transcript.entries
        var condensedEntries = [Transcript.Entry]()
        
        // Keep the first entry (usually system instructions)
        if let firstEntry = allEntries.first {
            condensedEntries.append(firstEntry)
        }
        
        // Keep the last few entries to maintain some context
        let keepLastCount = min(4, allEntries.count - 1) // Keep last 4 entries (2 exchanges)
        if keepLastCount > 0 {
            let lastEntries = Array(allEntries.suffix(keepLastCount))
            condensedEntries.append(contentsOf: lastEntries)
        }
        
        let condensedTranscript = Transcript(entries: condensedEntries)
        
        // Note: transcript includes instructions
        return LanguageModelSession(transcript: condensedTranscript)
    }
    
}
