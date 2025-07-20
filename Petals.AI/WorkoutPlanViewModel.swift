import SwiftUI
import FoundationModels

// MARK: - Data Models
struct ParsedWorkoutPlan {
    var fitnessLevel = ""
    var workoutType = ""
    var duration = ""
    var frequency = ""
    var goals = ""
    var dailyWorkouts: [DailyWorkout] = []
    var progressionTips: [String] = []
    var safetyGuidelines: [String] = []
    var recoveryNutrition: [String] = []
}

struct DailyWorkout: Identifiable {
    let id = UUID()
    var title = ""
    var focus = ""
    var exercises: [Exercise] = []
    var restPeriod = ""
    var notes = ""
    var isRestDay = false
}

struct Exercise: Identifiable {
    let id = UUID()
    var name: String
    var setsReps = ""
    var notes = ""
}

enum FitnessLevel: String, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    var id: Self { self }
}

enum WorkoutType: String, CaseIterable, Identifiable {
    case strength = "Strength Training"
    case cardio = "Cardio"
    case hiit = "HIIT"
    case yoga = "Yoga/Flexibility"
    case mixed = "Mixed Training"
    case bodyweight = "Bodyweight"
    var id: Self { self }
}

enum Equipment: String, CaseIterable, Identifiable {
    case none = "No Equipment"
    case basic = "Basic (Dumbbells, Bands)"
    case gym = "Full Gym Access"
    case home = "Home Gym Setup"
    var id: Self { self }
}


// MARK: - ViewModel
class WorkoutPlanViewModel: ObservableObject {
    @Published var fitnessLevel: FitnessLevel = .beginner
    @Published var workoutType: WorkoutType = .mixed
    @Published var duration: Double = 30
    @Published var daysPerWeek: Double = 3
    @Published var equipment: Equipment = .none
    @Published var customGoals = ""
    @Published var currentWeeklyPlan: String?
    @Published var parsedWorkoutPlan: ParsedWorkoutPlan?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showFullPlan = false
    @Published var showHealthDisclaimer = false
    
    private var currentSession: LanguageModelSession?
    private let userDefaults = UserDefaults.standard
    private let planKey = "weekly_workout_plan"
    private let planDateKey = "workout_plan_creation_date"
    private let disclaimerKey = "health_disclaimer_acknowledged"
    
    private let modelInstructions = """
    You are a fitness education assistant. Your role is strictly educational.
    **Guidelines:**
    1.  **Information Only:** Provide general fitness education, not medical advice.
    2.  **Safety First:** Emphasize proper form, gradual progression, and listening to one's body.
    3.  **Professional Consultation:** Remind users to consult a doctor before starting.
    4.  **Cautious Language:** Use phrases like "One might consider..." instead of direct commands.
    **Mandatory Output Format:**
    Your entire response must be in this exact Markdown format without extra conversational text.
    **Overview:**
    - **Level:** [User's Fitness Level]
    - **Type:** [User's Workout Type]
    - **Duration:** [User's Duration preference]
    - **Frequency:** [User's Days per Week]
    - **Goals:** [User's Goals]
    ### Day 1: [Day Title]
    - **Focus:** [e.g., Strength]
    - **Exercises:**
        - [Exercise 1 Name]: [Sets x Reps]
    - **Rest:** [e.g., 60-90 seconds]
    - **Notes:** [e.g., Focus on control.]
    (Repeat for all 7 days, using "Rest and Recovery" for non-workout days.)
    ### Progression Ideas
    - [Idea 1]
    ### Safety Reminders
    - [Reminder 1]
    ### Recovery & Wellness
    - [Tip 1]
    """

    var isPlanExpired: Bool {
        guard let date = userDefaults.object(forKey: planDateKey) as? Date else { return true }
        return Date().timeIntervalSince(date) > (7 * 24 * 60 * 60)
    }
    
    var planExpirationDate: String {
        guard let date = userDefaults.object(forKey: planDateKey) as? Date else { return "N/A" }
        let expirationDate = date.addingTimeInterval(7 * 24 * 60 * 60)
        return expirationDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    init() {
        initializeSession()
    }
    
    private func initializeSession() {
        Task {
            currentSession = LanguageModelSession(instructions: modelInstructions)
            print("Session initialized successfully")
        }
    }
    
    func loadSavedPlan() {
        if !isPlanExpired, let plan = userDefaults.string(forKey: planKey) {
            currentWeeklyPlan = plan
            parsedWorkoutPlan = parseWorkoutPlan(plan)
        } else {
            clearSavedPlan()
        }
    }
    
    func generateWorkoutPlan() {
        isLoading = true
        errorMessage = nil
        if !userDefaults.bool(forKey: disclaimerKey) {
            showHealthDisclaimer = true
            return
        }
        proceedWithGeneration()
    }
    
    func acknowledgeDisclaimer() {
        userDefaults.set(true, forKey: disclaimerKey)
        proceedWithGeneration()
    }

    private func proceedWithGeneration() {
        let prompt = createPrompt()
        Task {
            do {
                guard let session = currentSession else {
                    throw URLError(.cannotCreateFile) // Or a custom error
                }
                let response = try await session.respond(to: Prompt(prompt), options: GenerationOptions(temperature: 0.7, maximumResponseTokens: 2000))
                let content = response.content
                await MainActor.run {
                    self.currentWeeklyPlan = content
                    self.parsedWorkoutPlan = self.parseWorkoutPlan(content)
                    self.userDefaults.set(content, forKey: self.planKey)
                    self.userDefaults.set(Date(), forKey: self.planDateKey)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "AI generation failed. Please check your connection and try again."
                    self.isLoading = false
                }
            }
        }
    }
    
    private func createPrompt() -> String {
        let goalText = customGoals.isEmpty ? "general fitness and well-being" : customGoals
        return """
        Provide an educational workout guide in a 7-day structure for this profile:
        - **Experience Level:** \(fitnessLevel.rawValue)
        - **Activity Type:** \(workoutType.rawValue)
        - **Session Duration:** \(Int(duration)) minutes
        - **Frequency:** \(Int(daysPerWeek)) sessions per week
        - **Equipment:** \(equipment.rawValue)
        - **Interests:** \(goalText)
        Present as an educational template, not a prescription. Balance workouts and rest days.
        """
    }
    
    func resetPlan() {
        currentWeeklyPlan = nil
        parsedWorkoutPlan = nil
        errorMessage = nil
        showFullPlan = false
        userDefaults.removeObject(forKey: planKey)
        userDefaults.removeObject(forKey: planDateKey)
    }

    // Omitted parsing logic for brevity - it is the same as the original file.
    private func parseWorkoutPlan(_ planText: String) -> ParsedWorkoutPlan {
        var parsed = ParsedWorkoutPlan()
        let lines = planText.components(separatedBy: .newlines)
        
        var currentSection = ""
        var currentDay: DailyWorkout?
        var dayCounter = 0
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines
            if trimmedLine.isEmpty { continue }
            
            // Parse plan overview info
            if trimmedLine.contains("Level:") || trimmedLine.contains("**Level:**") {
                parsed.fitnessLevel = extractValue(from: trimmedLine)
            } else if trimmedLine.contains("Type:") || trimmedLine.contains("**Type:**") {
                parsed.workoutType = extractValue(from: trimmedLine)
            } else if trimmedLine.contains("Duration:") || trimmedLine.contains("**Duration:**") {
                parsed.duration = extractValue(from: trimmedLine)
            } else if trimmedLine.contains("Frequency:") || trimmedLine.contains("**Frequency:**") {
                parsed.frequency = extractValue(from: trimmedLine)
            } else if trimmedLine.contains("Goals:") || trimmedLine.contains("**Goals:**") {
                parsed.goals = extractValue(from: trimmedLine)
            }
            
            // Parse daily workouts
            if trimmedLine.hasPrefix("### Day") || trimmedLine.hasPrefix("## Day") {
                // Save previous day if exists
                if let day = currentDay {
                    parsed.dailyWorkouts.append(day)
                }
                
                // Start new day
                currentDay = DailyWorkout()
                dayCounter += 1
                
                // Extract day title
                if let colonIndex = trimmedLine.firstIndex(of: ":") {
                    let title = String(trimmedLine[trimmedLine.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                    currentDay?.title = title
                }
                
                // Check if it's a rest day
                if trimmedLine.lowercased().contains("rest") || trimmedLine.lowercased().contains("recovery") {
                    currentDay?.isRestDay = true
                }
                
                currentSection = "day"
            } else if trimmedLine.hasPrefix("**Focus:**") {
                currentDay?.focus = extractValue(from: trimmedLine)
            } else if currentSection == "day" {
                // Parse exercises within a day
                if trimmedLine.hasPrefix("-") {
                    let exerciseText = String(trimmedLine.dropFirst()).trimmingCharacters(in: .whitespaces)
                    let exercise = parseExercise(exerciseText)
                    currentDay?.exercises.append(exercise)
                } else if trimmedLine.hasPrefix("**Rest:**") {
                    currentDay?.restPeriod = extractValue(from: trimmedLine)
                } else if !trimmedLine.hasPrefix("#") && !trimmedLine.hasPrefix("*") && !trimmedLine.isEmpty {
                    // Additional notes for the day
                    if currentDay?.notes.isEmpty == true {
                        currentDay?.notes = trimmedLine
                    } else {
                        currentDay?.notes += " " + trimmedLine
                    }
                }
            }
            
            // Parse other sections
            if trimmedLine.contains("Progression") || trimmedLine.contains("progression") {
                currentSection = "progression"
            } else if trimmedLine.contains("Safety") || trimmedLine.contains("safety") || trimmedLine.contains("Form") {
                currentSection = "safety"
            } else if trimmedLine.contains("Recovery") || trimmedLine.contains("Nutrition") || trimmedLine.contains("nutrition") {
                currentSection = "recovery"
            } else if currentSection == "progression" && trimmedLine.hasPrefix("-") {
                parsed.progressionTips.append(String(trimmedLine.dropFirst()).trimmingCharacters(in: .whitespaces))
            } else if currentSection == "safety" && trimmedLine.hasPrefix("-") {
                parsed.safetyGuidelines.append(String(trimmedLine.dropFirst()).trimmingCharacters(in: .whitespaces))
            } else if currentSection == "recovery" && trimmedLine.hasPrefix("-") {
                parsed.recoveryNutrition.append(String(trimmedLine.dropFirst()).trimmingCharacters(in: .whitespaces))
            }
        }
        
        // Add the last day if exists
        if let day = currentDay {
            parsed.dailyWorkouts.append(day)
        }
        
        return parsed
    }
    
    private func extractValue(from line: String) -> String {
        if let colonIndex = line.firstIndex(of: ":") {
            return String(line[line.index(after: colonIndex)...])
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "*", with: "")
        }
        return ""
    }
    
    private func parseExercise(_ exerciseText: String) -> Exercise {
        // Split exercise name from sets/reps info
        let components = exerciseText.components(separatedBy: ":")
        
        if components.count >= 2 {
            let name = components[0].trimmingCharacters(in: .whitespaces)
            let setsReps = components[1].trimmingCharacters(in: .whitespaces)
            return Exercise(name: name, setsReps: setsReps)
        } else {
            // Try to parse format like "Push-ups 3 sets of 8-12 reps"
            let words = exerciseText.components(separatedBy: .whitespaces)
            
            if let setsIndex = words.firstIndex(where: { $0.lowercased().contains("set") }) {
                let name = words[0..<setsIndex].joined(separator: " ")
                let setsReps = words[setsIndex...].joined(separator: " ")
                return Exercise(name: name, setsReps: setsReps)
            }
        }
        
        return Exercise(name: exerciseText)
    }
    
    private func clearSavedPlan() {
        userDefaults.removeObject(forKey: planKey)
        userDefaults.removeObject(forKey: planDateKey)
    }
}
