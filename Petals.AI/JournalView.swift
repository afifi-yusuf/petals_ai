import SwiftUI
import SwiftData
import Speech

struct JournalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @State private var journalText: String = ""
    @State private var wordLimitReached: Bool = false
    
    @State private var isRecording = false
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    @State private var request = SFSpeechAudioBufferRecognitionRequest()
    
    var body: some View {
        ZStack {
            backgroundGradient
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 24) {
                header
                
                VStack(spacing: 16) {
                    TextEditor(text: $journalText)
                        .padding()
                        .frame(minHeight: 200)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .onChange(of: journalText) {
                            limitTo250Words()
                            limitTo1500Char()
                        }

                    HStack {
                        Button(action: {
                            isRecording ? stopRecording() : startRecording()
                            isRecording.toggle()
                        }) {
                            Label(isRecording ? "Stop Recording" : "Start Speaking", systemImage: "mic")
                                .padding()
                                .background(isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                                .foregroundColor(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        if isRecording {
                            Text("🎙️ Listening...")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        Text("\(wordCount()) / 250 words")
                            .font(.caption)
                            .foregroundColor(wordLimitReached ? .red : .secondary)
                        Spacer()
                        Button("Save") {
                            saveJournal()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal)
                
                Spacer()
            }
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
        VStack(spacing: 16) {
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
            
            VStack(spacing: 8) {
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Text("Wellness Journal")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
    
                    )
                Text(Date().formatted(date: .long, time: .shortened))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                
                Text("Reflect on your wellness journey, track your mood, and document your progress.")
                       .font(.body)
                       .foregroundColor(.secondary)
                       .multilineTextAlignment(.center)
                       .padding(.horizontal)

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
            print("wise")
            return
        }
        let entry = JournalLogModel(text: journalText)
        modelContext.insert(entry)
        do {
            try modelContext.save()
            print("✅ Journal saved: \(entry.text.prefix(50))...")
            dismiss()
        } catch{
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
                // Append transcribed text to existing journalText
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


#Preview {
    JournalView()
} 

