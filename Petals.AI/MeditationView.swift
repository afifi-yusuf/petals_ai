import SwiftUI
import FoundationModels
import AVFoundation

struct MeditationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var moodManager = MoodManager.shared
    @State private var showingSession = false
    @State private var generatedScript: String = ""
    @State private var isGeneratingScript: Bool = false
    @State private var showingVoiceSelection = false
    @State private var selectedVoiceIndex = 0
    @State private var backgroundAudioPlayer: AVAudioPlayer?
    @State private var speechDelegate: SpeechSynthesizerDelegate?
    @State private var backgroundVolume: Float = 0.5
    
    // Always use flow background audio
    private let backgroundAudioFileName = "flow"
    
    private let availableVoices: [AVSpeechSynthesisVoice] = {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        var englishVoices: [AVSpeechSynthesisVoice] = []
        
        // Include all English voices (both enhanced and default quality)
        for voice in allVoices {
            if voice.language.hasPrefix("en-") {
                englishVoices.append(voice)
            }
        }
        
        return englishVoices
    }()
    
    private var voiceNames: [String] {
        return availableVoices.map { voice in
            let qualityIndicator = voice.quality == .enhanced ? " ⭐️" : ""
            return "\(voice.name)\(qualityIndicator)"
        }
    }
    
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
                                
                                if isGeneratingScript {

                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                if isGeneratingScript {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Generating your personalized meditation...")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                                } else if !generatedScript.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.green)
                                        Text("Your session is ready.")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                                } else {
                                    Text("Welcome to your \(todaysMood.title.lowercased()) meditation. I can see you've had a busy day with 8,432 steps. Let's take a moment to find your center.\n\nFind a comfortable position and close your eyes. Take a deep breath in through your nose, counting to four. Hold for a moment, then exhale slowly through your mouth, counting to six. Feel the tension melting away with each breath.")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                        .lineSpacing(4)
                                }
                                
                                HStack {
                                    Spacer()
                                    
                                    if !isGeneratingScript && generatedScript.isEmpty {
                                        Button(action: {
                                            Task {
                                                await generateMeditationScript()
                                            }
                                        }) {
                                            Text("Generate AI Script")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.purple)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Color.purple.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                    }
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
                        VStack(spacing: 16) {
                            // Voice Selection Button
                            Button(action: { showingVoiceSelection = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "speaker.wave.2.circle.fill")
                                    Text("Voice: \(availableVoices[selectedVoiceIndex].name)")
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .font(.subheadline)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
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
                            .disabled(isGeneratingScript || generatedScript.isEmpty)
                            .opacity((isGeneratingScript || generatedScript.isEmpty) ? 0.5 : 1.0)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 30)
                }
            }
        }
        .fullScreenCover(isPresented: $showingSession) {
            MeditationSessionView(
                meditationScript: generatedScript, 
                selectedVoiceIndex: selectedVoiceIndex,
                backgroundAudioFileName: backgroundAudioFileName
            )
        }
        .onAppear {
            if let _ = moodManager.todaysMood, generatedScript.isEmpty {
                Task {
                    await generateMeditationScript()
                }
            }
        }
        .sheet(isPresented: $showingVoiceSelection) {
            VoiceSelectionView(
                selectedVoiceIndex: $selectedVoiceIndex,
                availableVoices: availableVoices,
                voiceNames: availableVoices.map { $0.name }
            )
        }
    }
    
    private func generateMeditationScript() async {
        guard let todaysMood = moodManager.todaysMood else { return }
        
        isGeneratingScript = true
        
        do {
            HealthDataManager.shared.requestHealthKitAuthorization()
            let healthSummary = await HealthDataManager.shared.getHealthSummary()
            
            let session = LanguageModelSession(instructions: """
            Write a gentle, imaginative story designed to help the listener relax and unwind.
            Personalize the story’s tone and setting based on the following context, but do not provide any health, wellness, or therapeutic advice.
            Do not mention or interpret the data as health advice.
            This is for entertainment and relaxation only. Your story will be read aloud.

            **Story Requirements:**
            - The story must be at least 700 words long. If you have not reached this length, continue the story until you do.
            - Fill the full 5 minutes with detailed, gentle narrative.
            - Start directly with the story content. Do NOT include any section headers, titles, or introductory phrases such as 'introduction', 'intro', or 'welcome to this story'.
            - Include natural pauses and breathing cues (e.g., "... and pause here for a moment ...", "Take a deep breath in... and release...")
            - Use conversational, warm, human-like language
            - Use gentle transitions and mindful pacing
            - End with a gentle closing and return to awareness
            - Tone: Calming, supportive, natural speech patterns

            **Personalization Context:**
            - Health Summary: \(healthSummary)
            - Current Mood: \(todaysMood.title) - \(todaysMood.description)

            **Structure (5 minutes total):**
            1. Welcome and settling (30 seconds) - ~75 words
            2. Breathing and relaxation guidance (1 minute) - ~150 words
            3. Gentle body scan or relaxing imagery (2 minutes) - ~300 words
            4. Mindfulness and presence (1 minute) - ~150 words
            5. Gentle closing (30 seconds) - ~75 words

            - Example of what NOT to do: Do not start with 'Introduction', 'Intro', 'Welcome to this story', or any similar phrase.
            - Start directly with the story content, as if the listener is already relaxed and ready.

            **BEGIN THE STORY NOW, starting immediately with the story content. Do NOT include any introductory phrases, titles, or headers. Avoid any health, wellness, or therapeutic advice. If you reach the end of your response and the story is not complete, continue the story in as much detail as possible.**
            """)
            
            let currentInput = "Generate meditation script."
            let options = GenerationOptions(
                temperature: 1.2,
                maximumResponseTokens: 2000
            )
            let response = try await session.respond(to: Prompt(currentInput), options: options)
            let responseContent = response.content
            generatedScript = responseContent
        } catch {
            generatedScript = "Unable to generate personalized script. Please try again."
        }
        
        isGeneratingScript = false
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
    @State private var totalTime: TimeInterval = 0
    @State private var synthesizer = AVSpeechSynthesizer()
    @State private var isAudioReady = false
    @State private var isGeneratingAudio = false
    @State private var timer: Timer?
    @State private var speechDelegate: SpeechSynthesizerDelegate?
    @State private var backgroundAudioPlayer: AVAudioPlayer?
    @State private var speechVolume: Float = 1.0
    @State private var backgroundVolume: Float = 1.0
    let meditationScript: String
    let selectedVoiceIndex: Int
    let backgroundAudioFileName: String
    
    private let availableVoices: [AVSpeechSynthesisVoice] = {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        var englishVoices: [AVSpeechSynthesisVoice] = []
        
        // Include all English voices (both enhanced and default quality)
        for voice in allVoices {
            if voice.language.hasPrefix("en-") {
                englishVoices.append(voice)
            }
        }
        
        return englishVoices
    }()
    
    init(meditationScript: String, selectedVoiceIndex: Int, backgroundAudioFileName: String) {
        self.meditationScript = meditationScript
        self.selectedVoiceIndex = selectedVoiceIndex
        self.backgroundAudioFileName = backgroundAudioFileName
    }
    
    var progress: Double {
        guard estimatedDuration > 0 else { return 0 }
        return min(currentTime / estimatedDuration, 1.0)
    }
    
    var formattedTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var estimatedDuration: TimeInterval {
        // Estimate duration based on word count and speech rate
        // Base rate: 150 words per minute at normal speed
        // With 0.7x rate: 150 * 0.7 = 105 words per minute
        // Add 20% for natural pauses, breathing, and meditation pacing
        let wordCount = meditationScript.split(separator: " ").count
        let wordsPerMinute = 150.0 * 0.7 * 0.8 // Account for 0.7x speech rate + 20% pause time
        let estimatedMinutes = Double(wordCount) / wordsPerMinute
        
        // Round to nearest half minute (0.5 minute intervals)
        let roundedMinutes = round(estimatedMinutes * 2.0) / 2.0
        return roundedMinutes * 60.0
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
                }
                .padding()
                
                Spacer()
                
                // Timer
                VStack(spacing: 8) {
                    Text(formattedTime)
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                // Calming Pulse Animation
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(isPlaying ? 1.1 : 1.0)
                        .opacity(isPlaying ? 0.8 : 0.6)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: isPlaying
                        )
                }
                
                // Audio Status
                if isGeneratingAudio {
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Preparing audio...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if !isAudioReady {
                    VStack(spacing: 8) {
                        Image(systemName: "speaker.slash")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Audio not ready")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Controls
                HStack(spacing: 40) {
                    Button(action: {
                        if isAudioReady {
                            togglePlayback()
                        } else {
                            Task {
                                await generateAudio()
                            }
                        }
                    }) {
                        Image(systemName: isAudioReady ? (isPlaying ? "pause.circle.fill" : "play.circle.fill") : "waveform.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .disabled(isGeneratingAudio)
                }
                
                // Background Volume Control
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "speaker.wave.1")
                            .foregroundColor(.blue)
                        Text("Background Volume")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    Slider(value: $backgroundVolume, in: 0...1) { _ in
                        backgroundAudioPlayer?.volume = backgroundVolume
                    }
                    .accentColor(.blue)
                }
                .padding(.horizontal, 40)
                
                // End Session Button
                Button(action: {
                    stopPlayback()
                    dismiss()
                }) {
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
        .onAppear {
            setupAudioSession()
            setupSpeechDelegate()
            setupBackgroundAudio()
            Task {
                await generateAudio()
            }
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    private func setupAudioSession() {
        do {
            // Configure audio session for mixing multiple audio sources
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session configured for mixing")
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func generateAudio() async {
        guard !meditationScript.isEmpty else {
            print("❌ Cannot generate audio: script is empty")
            return
        }
        
        print("🎵 Generating audio for meditation...")
        isGeneratingAudio = true
        
        await MainActor.run {
            self.isAudioReady = true
            self.isGeneratingAudio = false
            print("✅ Audio ready for playback")
        }
    }
    
    private func startPlayback() {
        guard !meditationScript.isEmpty else { 
            print("❌ Cannot start playback: script is empty")
            return 
        }
        
        print("🎵 Starting meditation playback...")
        
        // Ensure audio session is active
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session activated")
        } catch {
            print("❌ Failed to activate audio session: \(error)")
        }
        
        // Create speech utterance with proper configuration
        let utterance = AVSpeechUtterance(string: meditationScript)
        
        // Set the voice - ensure it's within bounds
        let voiceIndex = min(selectedVoiceIndex, availableVoices.count - 1)
        utterance.voice = availableVoices[voiceIndex]
        
        // Configure utterance properties according to Apple documentation
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.7 // More natural rate for meditation
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 1.0 // 1 second pause before starting
        utterance.postUtteranceDelay = 0.5 // 0.5 second pause after finishing
        
        print("🔊 Speech utterance created with voice: \(utterance.voice?.name ?? "Unknown")")
        print("🎤 Starting speech synthesis...")
        
        synthesizer.speak(utterance)
        isPlaying = true
        startTimer()
        startBackgroundAudio()
        print("✅ Playback started successfully")
    }
    
    private func pausePlayback() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
            isPlaying = false
            stopTimer()
            stopBackgroundAudio()
            print("⏸️ Playback paused")
        }
    }
    
    private func stopPlayback() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        stopTimer()
        stopBackgroundAudio()
        currentTime = 0
        print("⏹️ Playback stopped")
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func setupSpeechDelegate() {
        speechDelegate = SpeechSynthesizerDelegate(
            onStart: {
                print("🎵 Speech started")
            },
            onFinish: {
                DispatchQueue.main.async {
                    self.isPlaying = false
                    self.stopTimer()
                    self.stopBackgroundAudio()
                    print("✅ Speech finished - Total time: \(Int(self.currentTime)) seconds")
                }
            }
        )
        synthesizer.delegate = speechDelegate
    }
    
    private func setupBackgroundAudio() {
        guard let url = Bundle.main.url(forResource: backgroundAudioFileName, withExtension: "mp3") else {
            print("❌ Could not find background audio file: \(backgroundAudioFileName)")
            return
        }
        
        do {
            backgroundAudioPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundAudioPlayer?.numberOfLoops = -1 // Infinite loop
            backgroundAudioPlayer?.prepareToPlay()
            print("🎵 Background audio loaded successfully")
        } catch {
            print("❌ Failed to load background audio: \(error)")
        }
    }
    
    private func startBackgroundAudio() {
        backgroundAudioPlayer?.play()
        print("🎵 Background audio started")
    }
    
    private func stopBackgroundAudio() {
        backgroundAudioPlayer?.stop()
        print("🎵 Background audio stopped")
    }
    
    private func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            startPlayback()
        }
    }
}

// Helper class to handle speech synthesizer delegate
class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    let onStart: () -> Void
    let onFinish: () -> Void
    
    init(onStart: @escaping () -> Void, onFinish: @escaping () -> Void) {
        self.onStart = onStart
        self.onFinish = onFinish
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        onStart()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish()
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

struct VoiceSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedVoiceIndex: Int
    let availableVoices: [AVSpeechSynthesisVoice]
    let voiceNames: [String]
    
    private var enhancedVoices: [(index: Int, voice: AVSpeechSynthesisVoice)] {
        return availableVoices.enumerated()
            .filter { $0.element.quality == .enhanced }
            .map { (offset, element) in (index: offset, voice: element) }
    }
    
    private var standardVoices: [(index: Int, voice: AVSpeechSynthesisVoice)] {
        return availableVoices.enumerated()
            .filter { $0.element.quality == .default }
            .map { (offset, element) in (index: offset, voice: element) }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Voice")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if !availableVoices.isEmpty {
                            HStack {
                                Text(availableVoices[selectedVoiceIndex].name)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if availableVoices[selectedVoiceIndex].quality == .enhanced {
                                    Label("Premium", systemImage: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.yellow.opacity(0.2))
                                        .cornerRadius(12)
                                }
                            }
                        } else {
                            Text("No voices available")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Voice Settings")
                        .textCase(.uppercase)
                }
                
                if !enhancedVoices.isEmpty {
                    Section {
                        ForEach(enhancedVoices, id: \.voice.identifier) { index, voice in
                            VoiceRow(
                                name: voice.name,
                                language: voice.language,
                                isPremium: true,
                                isSelected: selectedVoiceIndex == index
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedVoiceIndex = index
                                dismiss()
                            }
                        }
                    } header: {
                        Text("Premium Voices")
                            .textCase(.uppercase)
                    } footer: {
                        Text("Enhanced quality voices for the best meditation experience")
                    }
                }
                
                if !standardVoices.isEmpty {
                    Section {
                        ForEach(standardVoices, id: \.voice.identifier) { index, voice in
                            VoiceRow(
                                name: voice.name,
                                language: voice.language,
                                isPremium: false,
                                isSelected: selectedVoiceIndex == index
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedVoiceIndex = index
                                dismiss()
                            }
                        }
                    } header: {
                        Text("Standard Voices")
                            .textCase(.uppercase)
                    }
                }
                
                if availableVoices.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("No Voices Available")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("To get voices for meditation:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("1. Open iOS Settings")
                                Text("2. Go to Accessibility > Spoken Content > Voices")
                                Text("3. Select English")
                                Text("4. Download any voices you prefer")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Voice Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct VoiceRow: View {
    let name: String
    let language: String
    let isPremium: Bool
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .foregroundColor(isSelected ? .purple : .primary)
                Text(language)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isPremium {
                Label("Premium", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(12)
            }
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.purple)
                    .padding(.leading, 4)
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    MeditationView()
} 

