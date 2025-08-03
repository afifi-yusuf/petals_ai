import SwiftUI
import SwiftData
import Speech
import AVFoundation

// MARK: - JournalView
struct JournalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @State private var journalText: String = ""
    @State private var wordLimitReached: Bool = false
    @State private var showingSaveSuccess = false
    
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 30) {
                        header
                        VStack(spacing: 0) {
                            journalHeader
                            journalEditor
                            journalActionButtons
                        }
                        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal)
                        
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
                        journalingTips
                        Spacer()
                    }
                    .padding(.top)
                }
            }
        }
        .alert("Journal Saved!", isPresented: $showingSaveSuccess) {
            Button("OK") {
                journalText = ""
                wordLimitReached = false
            }
        } message: {
            Text("Your wellness reflection has been saved successfully.")
        }
        // Update journal with speech as the user speaks
        .onChange(of: speechRecognizer.recognizedText) { newValue in
            if speechRecognizer.isRecording {
                journalText = newValue
            }
        }
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
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 16)
                .lineSpacing(5)
                .font(.body)
                .frame(minHeight: 250)
                .onChange(of: journalText) { _ in
                    limitTo250Words()
                }
        }
    }

    var journalActionButtons: some View {
        HStack {
            Button {
                if speechRecognizer.isRecording {
                    speechRecognizer.stopRecording()
                } else {
                    speechRecognizer.startRecording()
                }
            } label: {
                Image(systemName: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title)
                    .foregroundColor(speechRecognizer.isRecording ? .red : .accentColor)
            }
            Spacer()
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
}

// Helper for tips
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

