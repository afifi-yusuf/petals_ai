import SwiftUI
import FoundationModels

@Generable()
struct NutritionPlan: Codable {
    @Guide(description: "User's dietary approach (Balanced, Mediterranean, Plant-Based, etc.)")
    var dietaryApproach: String
    @Guide(description: "Primary nutrition goal")
    var primaryGoal: String
    @Guide(description: "Activity level")
    var activityLevel: String
    @Guide(description: "Number of meals per day")
    var mealsPerDay: String
    @Guide(description: "Estimated daily calorie range (e.g., '1800-2000')")
    var calorieRange: String
    @Guide(description: "Array of daily meal plans")
    var dailyMealPlans: [DailyMealPlan]
    @Guide(description: "General nutrition tips")
    var nutritionTips: [String]
    @Guide(description: "Safety guidelines and disclaimers")
    var safetyGuidelines: [String]
    @Guide(description: "Meal prep and planning tips")
    var mealPrepTips: [String]
}

@Generable()
struct DailyMealPlan: Codable, Identifiable {
    var id: String = UUID().uuidString
    @Guide(description: "Title for the day (e.g. 'Monday - High Protein Day')")
    var title: String
    @Guide(description: "Main nutritional focus for the day")
    var focus: String
    var meals: [Meal]
    @Guide(description: "Daily hydration goal")
    var hydrationGoal: String
    @Guide(description: "Special notes for the day")
    var notes: String
}

@Generable()
struct Meal: Codable, Identifiable {
    var id: String = UUID().uuidString
    @Guide(description: "Meal type (Breakfast, Lunch, Dinner, Snack)")
    var mealType: String
    @Guide(description: "Meal name (e.g., 'Greek Yogurt Parfait')")
    var name: String
    @Guide(description: "Key ingredients list")
    var ingredients: String
    @Guide(description: "Preparation notes or nutritional highlights")
    var notes: String
}

enum DietaryApproach: String, CaseIterable, Identifiable {
    case balanced = "Balanced"
    case mediterranean = "Mediterranean"
    case plantBased = "Plant-Based"
    case lowCarb = "Low-Carb"
    case highProtein = "High-Protein"
    case keto = "Ketogenic"
    case paleo = "Paleo"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    var id: Self { self }
}

enum NutritionGoal: String, CaseIterable, Identifiable {
    case weightLoss = "Weight Loss"
    case weightGain = "Weight Gain"
    case muscleBuilding = "Muscle Building"
    case maintenance = "Weight Maintenance"
    case energy = "Boost Energy"
    case health = "General Health"
    case performance = "Athletic Performance"
    var id: Self { self }
}

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary = "Sedentary"
    case light = "Light"
    case moderate = "Moderate"
    case active = "Very Active"
    var id: Self { self }
}

class NutritionPlanViewModel: ObservableObject {
    @Published var dietaryApproach: DietaryApproach = .balanced
    @Published var primaryGoal: NutritionGoal = .maintenance
    @Published var activityLevel: ActivityLevel = .moderate
    @Published var mealsPerDay: Double = 3
    @Published var cookingTime: Double = 30
    @Published var allergiesRestrictions = ""
    @Published var customGoals = ""
    @Published var currentWeeklyPlan: String?
    @Published var structuredNutritionPlan: NutritionPlan?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showFullPlan = false
    @Published var showHealthDisclaimer = false

    private var currentSession: LanguageModelSession?
    private let userDefaults = UserDefaults.standard
    private let planKey = "weekly_nutrition_plan"
    private let planDateKey = "nutrition_plan_creation_date"
    private let disclaimerKey = "nutrition_disclaimer_acknowledged"

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
            print("Nutrition session initialized successfully")
        }
    }

    func loadSavedPlan() {
        if !isPlanExpired,
           let jsonString = userDefaults.string(forKey: planKey),
           let jsonData = jsonString.data(using: .utf8),
           let nutritionPlan = try? JSONDecoder().decode(NutritionPlan.self, from: jsonData)
        {
            self.currentWeeklyPlan = jsonString
            self.structuredNutritionPlan = nutritionPlan
        } else {
            clearSavedPlan()
        }
    }

    func generateNutritionPlan() {
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
                    generating: NutritionPlan.self
                )
                let generatedNutritionPlan = response.content
                let jsonData = try? JSONEncoder().encode(generatedNutritionPlan)
                let jsonString = jsonData != nil ? String(data: jsonData!, encoding: .utf8) : nil
                await MainActor.run {
                    self.structuredNutritionPlan = generatedNutritionPlan
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
        let goalText = customGoals.isEmpty ? "general health and wellness" : customGoals
        let restrictionsText = allergiesRestrictions.isEmpty ? "none specified" : allergiesRestrictions
        
        return """
        Create a 7-day structured educational nutrition plan for this user.
        User Profile:
        - Dietary Approach: \(dietaryApproach.rawValue)
        - Primary Goal: \(primaryGoal.rawValue)
        - Activity Level: \(activityLevel.rawValue)
        - Meals Per Day: \(Int(mealsPerDay))
        - Cooking Time Available: \(Int(cookingTime)) minutes
        - Food Allergies/Restrictions: \(restrictionsText)
        - Nutrition Focus: \(goalText)
        
        IMPORTANT Ensure exactly 7 days are included, Monday through Sunday
        Include balanced daily meal plans with variety, portion guidance, nutrition tips, safety reminders, and meal prep suggestions.
        Focus on practical, achievable recommendations that support the user's goals and dietary preferences.
        """
    }

    func resetPlan() {
        currentWeeklyPlan = nil
        structuredNutritionPlan = nil
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
