import SwiftUI
import FoundationModels

@Generable()
struct WorkoutPlan: Codable {
    @Guide(description: "User's fitness experience level (Beginner, Intermediate, Advanced)")
    var fitnessLevel: String
    @Guide(description: "Primary workout type")
    var workoutType: String
    @Guide(description: "Duration per session (e.g., '30 min')")
    var duration: String
    @Guide(description: "Number of days per week (e.g., '3')")
    var frequency: String
    @Guide(description: "Stated fitness goals")
    var goals: String
    @Guide(description: "Array of daily workouts")
    var dailyWorkouts: [DailyWorkout]
    @Guide(description: "Progression tips")
    var progressionTips: [String]
    @Guide(description: "Safety guidelines")
    var safetyGuidelines: [String]
    @Guide(description: "Recovery and nutrition guidance")
    var recoveryNutrition: [String]
}

@Generable()
struct DailyWorkout: Codable, Identifiable {
    var id: String = UUID().uuidString
    @Guide(description: "Title for the day (e.g. 'Upper Body Strength', 'Rest')")
    var title: String
    @Guide(description: "Main focus for the workout (e.g., 'Strength', 'Mobility')")
    var focus: String
    var exercises: [Exercise]
    @Guide(description: "Rest period guidance")
    var restPeriod: String
    @Guide(description: "Coach's notes, tips, etc.")
    var notes: String
    @Guide(description: "Is this day a rest day?")
    var isRestDay: Bool
}

@Generable()
struct Exercise: Codable, Identifiable {
    var id: String = UUID().uuidString
    @Guide(description: "Exercise name (e.g., 'Squat')")
    var name: String
    @Guide(description: "Number of sets/reps, e.g., '3x12'")
    var setsReps: String
    @Guide(description: "Instructions, cues, etc.")
    var notes: String
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

class WorkoutPlanViewModel: ObservableObject {
    @Published var fitnessLevel: FitnessLevel = .beginner
    @Published var workoutType: WorkoutType = .mixed
    @Published var duration: Double = 30
    @Published var daysPerWeek: Double = 3
    @Published var equipment: Equipment = .none
    @Published var customGoals = ""
    @Published var currentWeeklyPlan: String?
    @Published var structuredWorkoutPlan: WorkoutPlan?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showFullPlan = false
    @Published var showHealthDisclaimer = false

    private var currentSession: LanguageModelSession?
    private let userDefaults = UserDefaults.standard
    private let planKey = "weekly_workout_plan"
    private let planDateKey = "workout_plan_creation_date"
    private let disclaimerKey = "health_disclaimer_acknowledged"

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
            self.currentSession = LanguageModelSession()
            print("Session initialized successfully")
        }
    }

    func loadSavedPlan() {
        if !isPlanExpired,
           let jsonString = userDefaults.string(forKey: planKey),
           let jsonData = jsonString.data(using: .utf8),
           let workoutPlan = try? JSONDecoder().decode(WorkoutPlan.self, from: jsonData)
        {
            self.currentWeeklyPlan = jsonString
            self.structuredWorkoutPlan = workoutPlan
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
                    throw URLError(.cannotCreateFile)
                }
                let response = try await session.respond(
                    to: prompt,
                    generating: WorkoutPlan.self
                )
                let generatedWorkoutPlan = response.content
                let jsonData = try? JSONEncoder().encode(generatedWorkoutPlan)
                let jsonString = jsonData != nil ? String(data: jsonData!, encoding: .utf8) : nil
                await MainActor.run {
                    self.structuredWorkoutPlan = generatedWorkoutPlan
                    if let jsonString = jsonString {
                        self.currentWeeklyPlan = jsonString
                        self.userDefaults.set(jsonString, forKey: self.planKey)
                        self.userDefaults.set(Date(), forKey: self.planDateKey)
                    }
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
        Create a 7-day structured educational workout plan for this user.
        User Profile:
        - Experience Level: \(fitnessLevel.rawValue)
        - Workout Type: \(workoutType.rawValue)
        - Session Duration: \(Int(duration)) minutes
        - Frequency: \(Int(daysPerWeek)) sessions per week
        - Equipment: \(equipment.rawValue)
        - Fitness Goals: \(goalText)

        Include a suitable mix of workout and rest days, safety advice, progression tips, and recovery/nutrition ideas.
        """
    }

    func resetPlan() {
        currentWeeklyPlan = nil
        structuredWorkoutPlan = nil
        errorMessage = nil
        showFullPlan = false
        userDefaults.removeObject(forKey: planKey)
        userDefaults.removeObject(forKey: planDateKey)
    }

    private func clearSavedPlan() {
        userDefaults.removeObject(forKey: planKey)
        userDefaults.removeObject(forKey: planDateKey)
    }
}

