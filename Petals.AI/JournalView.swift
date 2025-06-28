import SwiftUI
import SwiftData
import Speech

struct JournalView: View {
    // Your existing state properties are perfect. No changes needed here.
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @State private var journalText: String = ""
    @State private var wordLimitReached: Bool = false
    @State private var showingSaveSuccess = false
    @State private var isRecording = false
    
    // Your speech recognition properties are also great.
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    @State private var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    @State private var request = SFSpeechAudioBufferRecognitionRequest()

    var body: some View {
        // We use a ZStack and Color to create a base background that works in both modes.
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        // Header remains the same
                        header
                        
                        // --- REFACTORED SECTION ---
                        // The "Today's Reflection" card is now the primary focus.
                        VStack(spacing: 0) {
                            journalHeader
                            
                            journalEditor
                            
                            journalActionButtons
                        }
                        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal)
                        
                        // --- REFACTORED SECTION ---
                        // "View Past Entries" is now its own distinct, secondary section.
                        NavigationLink(destination: PastLogView()) {
                            HStack {
                                Image(systemName: "book.closed.fill")
                                Text("View Past Entries")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding()
                            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .padding(.horizontal)
                        }
                        
                        // Your journaling tips section is great, no major changes needed.
                        journalingTips
                        
                        Spacer()
                    }
                    .padding(.top)
                }
            }
        }
        .alert("Journal Saved!", isPresented: $showingSaveSuccess) {
            Button("OK") { 
                // Clear the text after saving
                journalText = ""
                wordLimitReached = false
            }
        } message: {
            Text("Your wellness reflection has been saved successfully.")
        }
    }
    
    // MARK: - Subviews for Cleaner Code
    
    var header: some View {
        VStack(spacing: 16) {
            // Navigation Header with Back Button
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
            
            // Logo and Title Section
            VStack(spacing: 12) {
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 4) {
                    Text("Wellness Journal")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                    
                    Text(Date().formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    var journalHeader: some View {
        HStack {
            Text("Today's Reflection")
                .font(.title2.weight(.semibold))
            Spacer()
            // Word count indicator is cleaner and more modern.
            Text("\(wordCount()) / 250 words")
                .font(.caption.monospacedDigit())
                .foregroundColor(wordLimitReached ? .red : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((wordLimitReached ? Color.red : Color.green).opacity(0.1))
                .clipShape(Capsule())
        }
        .padding([.horizontal, .top])
        .padding(.bottom, 8)
    }

    var journalEditor: some View {
        // The TextEditor now has a nice placeholder and sits inside the card.
        ZStack(alignment: .topLeading) {
            if journalText.isEmpty {
                Text("How are you feeling today?\nShare your thoughts, feelings, or any wellness insights...")
                    .font(.body)
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
            }
            
            TextEditor(text: $journalText)
                .scrollContentBackground(.hidden) // Hides the default gray background
                .padding(.horizontal, 16)
                .lineSpacing(5)
                .font(.body)
                .frame(minHeight: 250)
                .onChange(of: journalText) {
                    limitTo250Words()
                }
        }
    }
    
    var journalActionButtons: some View {
        // Buttons are now grouped at the bottom of the card for clear actions.
        HStack {
            // The Voice button is a secondary action.
            Button {
                isRecording.toggle()
                isRecording ? startRecording() : stopRecording()
            } label: {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title)
                    .foregroundColor(isRecording ? .red : .accentColor)
            }
            
            Spacer()
            
            // The Save button is the primary action.
            Button(action: saveJournal) {
                Text("Save Entry")
                    .font(.headline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(.regularMaterial)
    }

    var journalingTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill").foregroundColor(.orange)
                Text("Journaling Tips").font(.headline.weight(.semibold))
            }
            TipRow(icon: "heart.fill", text: "Write about your emotions and how you're feeling")
            TipRow(icon: "figure.walk", text: "Reflect on your physical activity and energy levels")
            TipRow(icon: "brain.head.profile", text: "Note any stress, anxiety, or moments of peace")
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal)
    }
    
    // MARK: - Your Existing Functions (No Changes Needed)
    // All your functions like wordCount(), saveJournal(), startRecording(), etc.
    // are perfectly fine and do not need to be changed.
    
    func wordCount() -> Int {
        journalText.split { $0.isWhitespace || $0.isNewline }.count
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

// Your TipRow and other helper views are also fine.
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

#Preview{
    JournalView()
}
