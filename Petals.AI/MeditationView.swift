import SwiftUI

struct MeditationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var moodManager = MoodManager.shared
    @State private var showingSession = false
    
    var body: some View {
        ZStack {
            // Background gradient - dark mode compatible
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
            
            // Solid background overlay to prevent transparency
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with back button
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
                    
                    // Header
                    VStack(spacing: 16) {
                        Image("icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Text("Personalized Meditation")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(.top, 20)
                    
                    // Today's Mood Display
                    if let todaysMood = moodManager.todaysMood {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                Text("Today's Mood")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            HStack(spacing: 16) {
                                Image(systemName: todaysMood.icon)
                                    .font(.title2)
                                    .foregroundColor(todaysMood.color)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(todaysMood.title)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text(todaysMood.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    } else {
                        // No mood set for today
                        VStack(spacing: 16) {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("No Mood Set Today")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Please set your mood for today to get personalized meditation sessions.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Generated Script Preview
                    if let todaysMood = moodManager.todaysMood {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                Text("Your Personalized Session")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Welcome to your \(todaysMood.title.lowercased()) meditation. I can see you've had a busy day with 8,432 steps. Let's take a moment to find your center.\n\nFind a comfortable position and close your eyes. Take a deep breath in through your nose, counting to four. Hold for a moment, then exhale slowly through your mouth, counting to six. Feel the tension melting away with each breath.")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(4)
                                
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.secondary)
                                    Text("10 minutes")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }
                    
                    // Start Session Button
                    if moodManager.todaysMood != nil {
                        Button(action: {
                            showingSession = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.title2)
                                Text("Start Meditation Session")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
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
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 30)
                }
            }
        }
        .fullScreenCover(isPresented: $showingSession) {
            MeditationSessionView()
        }
    }
}

struct MoodCard: View {
    let mood: MoodType
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: mood.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : mood.color)
                
                Text(mood.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(mood.description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? mood.color : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)))
                    .shadow(color: isSelected ? mood.color.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MeditationSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var totalTime: TimeInterval = 600 // 10 minutes
    
    var progress: Double {
        guard totalTime > 0 else { return 0 }
        return 1.0 - (currentTime / totalTime)
    }
    
    var formattedTime: String {
        let remaining = totalTime - currentTime
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        ZStack {
            // Background gradient - dark mode compatible
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? [
                    Color.purple.opacity(0.3),
                    Color.blue.opacity(0.2),
                    Color.black
                ] : [
                    Color.purple.opacity(0.2),
                    Color.blue.opacity(0.1),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Solid background overlay to prevent transparency
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Meditation Session")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Spacer()
                
                // Timer
                VStack(spacing: 8) {
                    Text(formattedTime)
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                }
                
                // Controls
                HStack(spacing: 40) {
                    Button(action: {}) {
                        Image(systemName: "gobackward.15")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: { isPlaying.toggle() }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "goforward.30")
                            .font(.title)
                            .foregroundColor(.primary)
                    }
                }
                
                // End Session Button
                Button(action: { dismiss() }) {
                    Text("End Session")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                Spacer()
            }
        }
    }
}

enum MoodType: String, CaseIterable {
    case stressed = "stressed"
    case tired = "tired"
    case anxious = "anxious"
    case calm = "calm"
    case energetic = "energetic"
    case focused = "focused"
    
    var title: String {
        switch self {
        case .stressed: return "Stressed"
        case .tired: return "Tired"
        case .anxious: return "Anxious"
        case .calm: return "Calm"
        case .energetic: return "Energetic"
        case .focused: return "Focused"
        }
    }
    
    var description: String {
        switch self {
        case .stressed: return "Feeling overwhelmed"
        case .tired: return "Need energy boost"
        case .anxious: return "Worried thoughts"
        case .calm: return "Peaceful state"
        case .energetic: return "High energy"
        case .focused: return "Clear mind"
        }
    }
    
    var icon: String {
        switch self {
        case .stressed: return "exclamationmark.triangle"
        case .tired: return "bed.double"
        case .anxious: return "heart.circle"
        case .calm: return "leaf"
        case .energetic: return "bolt"
        case .focused: return "brain.head.profile"
        }
    }
    
    var color: Color {
        switch self {
        case .stressed: return .orange
        case .tired: return .blue
        case .anxious: return .red
        case .calm: return .green
        case .energetic: return .yellow
        case .focused: return .purple
        }
    }
}

#Preview {
    MeditationView()
} 
