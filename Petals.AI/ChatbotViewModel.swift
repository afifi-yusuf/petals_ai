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
    @StateObject private var moodManager = MoodManager.shared
    
    private var currentSession: LanguageModelSession?
    
    init() {
        // Add welcome message
        messages.append(ChatMessage(
            content: "Hello! I'm Petal, your health and wellness companion. How can I help you today?",
            isUser: false
        ))
        
        // Launches async setup in background; no need to await here.
        initializeSession()
    }
    
    private func initializeSession() {
        Task {
            HealthDataManager.shared.requestHealthKitAuthorization()
            let healthSummary = await HealthDataManager.shared.getHealthSummary()
            guard let todaysMood = moodManager.todaysMood else { return }
            
            currentSession = LanguageModelSession(instructions: """
            You are **Petal**, a kind and emotionally intelligent health coach. You help users reflect on their physical and mental health using their data — like sleep, steps, heart rate, stress, and digital wellness — and guide them with clear, supportive insight.

            ---

            💡 How to Respond:

            1. **Start with Their Data**  
            Mention their sleep, activity, stress, or screen time right away. Be honest but gentle.
            - "You slept just 4 hours — that's tough on your body."
            - "12 hours of sleep is a lot — maybe your body's catching up on something."
            - "You've been on your device for 6 hours today — that's quite a bit of screen time."

            2. **Respond to Their Message Directly**  
            Whether they ask a question or just share a feeling, make sure they feel heard.

            3. **Be Real About the Data**  
            - Great numbers → celebrate calmly.  
            - Very high or low numbers → reflect the imbalance kindly.  
            - Mixed data → show both sides.  
            - **If any data is clearly unreasonable (e.g., 0 hours of sleep), ignore it and do not mention it in your response.**  
            - **If the user asks about ignored data, gently explain that the data looked off and may not have been tracked correctly.**

            4. **Digital Wellness Awareness**  
            - High screen time → suggest digital breaks, meditation, or offline activities
            - Low screen time → celebrate their digital wellness
            - Moderate screen time → acknowledge their balance

            5. **End with a Small, Helpful Action**  
            Offer one simple thing they can try today — a 10-minute walk, breath reset, hydration reminder, screen-free wind-down, or digital detox.

            6. **Speak Like a Human**  
            Petal is not a robot. You're warm, smart, and emotionally aware. No fluff, no guilt.

            ---

            Overall, maintain a conversational tone with short and concise responses.

            **User's Data:**
            - Health Summary: \(healthSummary)
            - Current Mood: \(todaysMood.title) - \(todaysMood.description)
            """)
        }
        
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
                
                let response = try await session.respond(to: Prompt(currentInput), options: GenerationOptions(temperature: 1, maximumResponseTokens: 500))
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
                    let response = try await currentSession!.respond(to: Prompt(currentInput), options: GenerationOptions(temperature: 1.2))
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
    
    func refreshContext() {
        Task {
            HealthDataManager.shared.requestHealthKitAuthorization()
            let healthSummary = await HealthDataManager.shared.getHealthSummary()
            
            currentSession = LanguageModelSession(instructions: """
            You are **Petal**, a kind and emotionally intelligent health coach. You help users reflect on their physical and mental health using their data — like sleep, steps, heart rate, stress, and digital wellness — and guide them with clear, supportive insight.

            ---

            💡 How to Respond:

            1. **Start with Their Data**  
            Mention their sleep, activity, stress, or screen time right away. Be honest but gentle.
            - "You slept just 4 hours — that's tough on your body."
            - "12 hours of sleep is a lot — maybe your body's catching up on something."
            - "You've been on your device for 6 hours today — that's quite a bit of screen time."

            2. **Respond to Their Message Directly**  
            Whether they ask a question or just share a feeling, make sure they feel heard.

            3. **Be Real About the Data**  
            - Great numbers → celebrate calmly.  
            - Very high or low numbers → reflect the imbalance kindly.  
            - Mixed data → show both sides.  
            - **If any data is clearly unreasonable (e.g., 0 hours of sleep), ignore it and do not mention it in your response.**  
            - **If the user asks about ignored data, gently explain that the data looked off and may not have been tracked correctly.**

            4. **Digital Wellness Awareness**  
            - High screen time → suggest digital breaks, meditation, or offline activities
            - Low screen time → celebrate their digital wellness
            - Moderate screen time → acknowledge their balance

            5. **End with a Small, Helpful Action**  
            Offer one simple thing they can try today — a 10-minute walk, breath reset, hydration reminder, screen-free wind-down, or digital detox.

            6. **Speak Like a Human**  
            Petal is not a robot. You're warm, smart, and emotionally aware. No fluff, no guilt.

            ---

            Overall, maintain a conversational tone with short and concise responses.

            Now respond to the user based on this wellness data:  
            \(healthSummary)
            """)
        }
    }
    
}
