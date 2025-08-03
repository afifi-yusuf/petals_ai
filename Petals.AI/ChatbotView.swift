// In ChatbotView.swift
import SwiftUI
import Speech
import AVFoundation   // ← add this

struct ChatbotView: View {
    @StateObject private var viewModel = ChatbotViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var chatText: String = ""
    @State private var wordLimitReached: Bool = false
    @State private var showingSaveSuccess = false
    @State private var isRecording = false
    
    // Your speech recognition properties are also great.
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    @State private var request = SFSpeechAudioBufferRecognitionRequest()

    
    var body: some View {
        ZStack {
            AnimatedBackground() // Consistent background
            
            VStack(spacing: 0) {
                // Header with Logo and Blur Effect
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
                .padding()
                .background(.ultraThinMaterial)
                
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) { // Increased spacing
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
                
                // Refined Input area
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 16) {
                        TextField("Type a message...", text: $viewModel.inputMessage)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        Button {
                            isRecording ? stopRecording() : startRecording()
                        } label: {
                           Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                               .font(.system(size: 32))
                               .foregroundStyle(
                                   LinearGradient(colors: [.purple, .blue],
                                                  startPoint: .topLeading,
                                                  endPoint: .bottomTrailing)
                               )
                       }
                       .disabled(viewModel.isLoading)
                        
                        Button(action: {
                            viewModel.sendMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
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
        }
        .navigationTitle("AI Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { stopRecording() }
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
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(bubbleBackground(for: message))
                .foregroundColor(message.isUser ? .white : .primary)
                .clipShape(ChatBubbleShape(isFromCurrentUser: message.isUser))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private func bubbleBackground(for message: ChatMessage) -> some View {
        if message.isUser {
            LinearGradient(
                colors: [.purple, .blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            colorScheme == .dark ? Color(.systemGray5) : Color.white
        }
    }
}

// Custom shape for chat bubble with tail
struct ChatBubbleShape: Shape {
    let isFromCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                isFromCurrentUser ? .bottomLeft : .bottomRight
            ],
            cornerRadii: CGSize(width: 20, height: 20)
        )
        return Path(path.cgPath)
    }
}

struct TypingIndicator: View {
    @State private var animationOffset: CGFloat = 0
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.secondary)
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
        .background(colorScheme == .dark ? Color(.systemGray5) : Color.white)
        .clipShape(ChatBubbleShape(isFromCurrentUser: false))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .onAppear {
            animationOffset = -5
        }
    }
}

func startRecording() {
    requestPermissions()

    let audioSession = AVAudioSession.sharedInstance()
    try? audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
    try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)

    request = SFSpeechAudioBufferRecognitionRequest()

    let inputNode = audioEngine.inputNode
    let recordingFormat = inputNode.outputFormat(forBus: 0)

    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
        request.append(buffer)
    }

    audioEngine.prepare()
    try? audioEngine.start()

    recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
        if let result = result {
            chatText = result.bestTranscription.formattedString
        }

        if let error = error {
            print("❌ Speech error: \(error.localizedDescription)")
            stopRecording()
        }
    }
}

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request.endAudio()
        recognitionTask?.finish()
        recognitionTask = nil
    }

    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            if status != .authorized {
                print("❌ Speech recognition not authorized")
            }
        }

        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                print("❌ Microphone access not granted")
            }
        }
    }
}

#Preview {
    NavigationView {
        ChatbotView()
    }
}
