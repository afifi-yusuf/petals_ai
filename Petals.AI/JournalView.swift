import SwiftUI
import SwiftData
import Speech

struct JournalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @State private var journalText: String = ""
    @State private var wordLimitReached: Bool = false
    @State private var showingSaveSuccess = false
    
    @State private var isRecording = false
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    @State private var request = SFSpeechAudioBufferRecognitionRequest()
    
    var body: some View {
        ZStack {
            backgroundGradient
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Journal Entry Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Today's Reflection")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Word count indicator
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(wordLimitReached ? Color.red : Color.green)
                                        .frame(width: 8, height: 8)
                                    Text("\(wordCount()) / 250")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(wordLimitReached ? .red : .secondary)
                                }
                            }
                            
                            // Enhanced Text Editor
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                
                                if journalText.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("How are you feeling today?")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                        Text("Share your thoughts, feelings, or any wellness insights...")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary.opacity(0.8))
                                    }
                                    .padding(20)
                                    .allowsHitTesting(false)
                                }
                                
                                TextEditor(text: $journalText)
                                    .padding(20)
                                    .background(Color.clear)
                                    .font(.body)
                                    .lineSpacing(4)
                                    .onChange(of: journalText) {
                                        limitTo250Words()
                                        limitTo1500Char()
                                    }
                            }
                            .frame(minHeight: 200)
                        }
                        .padding(.horizontal, 24)
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            // Voice Recording Button
                            Button(action: {
                                isRecording ? stopRecording() : startRecording()
                                isRecording.toggle()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(isRecording ? .red : .blue)
                                    
                                    Text(isRecording ? "Stop Recording" : "Voice to Text")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if isRecording {
                                        HStack(spacing: 4) {
                                            ForEach(0..<3) { index in
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 6, height: 6)
                                                    .scaleEffect(isRecording ? 1.2 : 0.8)
                                                    .animation(
                                                        Animation.easeInOut(duration: 0.6)
                                                            .repeatForever()
                                                            .delay(0.2 * Double(index)),
                                                        value: isRecording
                                                    )
                                            }
                                        }
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .shadow(color: isRecording ? .red.opacity(0.2) : .blue.opacity(0.2), radius: 8, x: 0, y: 4)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Save Button
                            Button(action: saveJournal) {
                                HStack(spacing: 12) {
                                    Image(systemName: "bookmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                    
                                    Text("Save Journal Entry")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(20)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                        }
                        .padding(.horizontal, 24)
                        
                        // Wellness Tips
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.orange)
                                    .font(.title3)
                                Text("Journaling Tips")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                TipRow(icon: "heart.fill", text: "Write about your emotions and how you're feeling")
                                TipRow(icon: "figure.walk", text: "Reflect on your physical activity and energy levels")
                                TipRow(icon: "brain.head.profile", text: "Note any stress, anxiety, or moments of peace")
                                TipRow(icon: "leaf.fill", text: "Document your wellness goals and progress")
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .orange.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.vertical, 24)
                }
            }
        }
        .alert("Journal Saved!", isPresented: $showingSaveSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your wellness reflection has been saved successfully.")
        }
    }

    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: colorScheme == .dark ? [
                Color.purple.opacity(0.2),
                Color.blue.opacity(0.1),
                Color.black
            ] : [
                Color.purple.opacity(0.1),
                Color.blue.opacity(0.05),
                Color.white
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    var header: some View {
        VStack(spacing: 20) {
            // Navigation Header
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Back")
                            .font(.headline)
                    }
                    .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            // Title Section
            VStack(spacing: 16) {
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    Text("Wellness Journal")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                    
                    Text(Date().formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Reflect on your wellness journey and track your progress")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
        }
    }
    
    func wordCount() -> Int {
        journalText.split { $0.isWhitespace || $0.isNewline }.count
    }
    
    func charCount() -> Int {
        return journalText.count
    }

    func limitTo250Words() {
        let words = journalText.split { $0.isWhitespace || $0.isNewline }
        wordLimitReached = words.count > 250
        if wordLimitReached {
            journalText = words.prefix(250).joined(separator: " ")
        }
    }

    func saveJournal() {
        guard !journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        let entry = JournalLogModel(text: journalText)
        modelContext.insert(entry)
        do {
            try modelContext.save()
            print("✅ Journal saved: \(entry.text.prefix(50))...")
            showingSaveSuccess = true
        } catch {
            print("❌ Failed to save journal: \(error.localizedDescription)")
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
                journalText = result.bestTranscription.formattedString
            }

            if let error = error {
                print("❌ Speech error: \(error.localizedDescription)")
                stopRecording()
            }
        }
    }
    
    func limitTo1500Char(){
        let charLimit = journalText.count > 1500
        journalText = charLimit ? String(journalText.prefix(1500)) : journalText
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

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.orange)
                .frame(width: 16)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}

#Preview {
    JournalView()
} 

