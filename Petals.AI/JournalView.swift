import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @State private var journalText: String = ""
    @State private var wordLimitReached: Bool = false
    
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
                        .onChange(of: journalText) { _ in
                            limitTo250Words()
                        }

                    HStack {
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
}


#Preview {
    JournalView()
} 
