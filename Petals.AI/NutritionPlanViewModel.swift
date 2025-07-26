import SwiftUI
import FoundationModels

// MARK: - Data Structures

@Generable()
struct NutritionPlan: Codable {
    var dietaryApproach: String
    var primaryGoal: String
    var activityLevel: String
    var mealsPerDay: String
    var calorieRange: String
    var dailyMealPlans: [DailyMealPlan]
    var nutritionTips: [String]
    var safetyGuidelines: [String]
    var mealPrepTips: [String]
    var weeklyShoppingList: [String]
    var hydrationGuidance: String
    var supplementSuggestions: [String]
}

@Generable()
struct DailyMealPlan: Codable, Identifiable {
    var id: String = UUID().uuidString
    var title: String // Manually set, not by AI
    @Guide(description: "A brief summary of the day's food theme.")
    var focus: String
    var meals: [Meal]
    @Guide(description: "A general water reminder for the day.")
    var hydrationGoal: String
    @Guide(description: "Simple cooking or timing notes.")
    var notes: String
    @Guide(description: "General food quantity estimate.")
    var dailyCalorieEstimate: String
    @Guide(description: "Key food types emphasized today.")
    var keyNutrients: String
}

@Generable()
struct Meal: Codable, Identifiable {
    var id: String = UUID().uuidString
    var mealType: String
    var name: String
    var ingredients: String
    var notes: String
    @Guide(description: "Simple cooking method.")
    var prepInstructions: String
    @Guide(description: "Approximate food quantity.")
    var calorieEstimate: String
    @Guide(description: "Time needed for cooking.")
    var prepTime: String
}

@Generable()
struct NutritionExtras: Codable {
    @Guide(description: "General food quantity information.")
    var calorieRange: String
    @Guide(description: "Basic cooking suggestions.")
    var nutritionTips: [String]
    @Guide(description: "General reminders about professional advice.")
    var safetyGuidelines: [String]
    @Guide(description: "Simple cooking preparation ideas.")
    var mealPrepTips: [String]
    @Guide(description: "Common grocery items organized by category.")
    var weeklyShoppingList: [String]
    @Guide(description: "Basic daily water suggestions.")
    var hydrationGuidance: String
    @Guide(description: "General information about common food additions.")
    var supplementSuggestions: [String]
}

// MARK: - Enums (unchanged)

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
    case intermittentFasting = "Intermittent Fasting"
    case antiInflammatory = "Anti-Inflammatory"
    case lowFodmap = "Low-FODMAP"
    
    var id: Self { self }
    
    var description: String {
        switch self {
        case .balanced: return "Includes all food groups in moderation"
        case .mediterranean: return "Emphasizes fruits, vegetables, whole grains, and healthy fats"
        case .plantBased: return "Focuses on foods from plants with minimal processing"
        case .lowCarb: return "Reduces carbohydrate intake, increases protein and fats"
        case .highProtein: return "Emphasizes protein-rich foods for muscle building and satiety"
        case .keto: return "Very low carb, high fat approach for ketosis"
        case .paleo: return "Based on foods available to Paleolithic humans"
        case .vegetarian: return "Plant-based with dairy and eggs, no meat"
        case .vegan: return "Exclusively plant-based foods"
        case .intermittentFasting: return "Eating within specific time windows"
        case .antiInflammatory: return "Foods that reduce inflammation in the body"
        case .lowFodmap: return "Reduces fermentable carbs for digestive health"
        }
    }
}

enum NutritionGoal: String, CaseIterable, Identifiable {
    case weightManagement = "Weight Management"
    case healthyLiving = "Healthy Living"
    case muscleSupport = "Muscle Support"
    case maintenance = "Maintenance"
    case energy = "Energy Support"
    case wellness = "General Wellness"
    case fitness = "Fitness Support"
    case digestiveWellness = "Digestive Wellness"
    case heartWellness = "Heart Wellness"
    case cognitiveSupport = "Cognitive Support"
    case immuneWellness = "Immune Wellness"
    case balance = "Hormonal Balance"
    
    var id: Self { self }
}

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary = "Sedentary"
    case lightlyActive = "Light"
    case moderatelyActive = "Moderate"
    case veryActive = "Very Active"
    
    var id: Self { self }
    
    var description: String {
        switch self {
        case .sedentary: return "Desk job, minimal exercise"
        case .lightlyActive: return "Light exercise 1-3 days/week"
        case .moderatelyActive: return "Moderate exercise 3-5 days/week"
        case .veryActive: return "Heavy exercise 6-7 days/week"
        }
    }
    
    var calorieMultiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive: return 1.725
        }
    }
}

// MARK: - Enhanced ViewModel

class NutritionPlanViewModel: ObservableObject {
    @Published var dietaryApproach: DietaryApproach = .balanced
    @Published var primaryGoal: NutritionGoal = .maintenance
    @Published var activityLevel: ActivityLevel = .moderatelyActive
    @Published var mealsPerDay: Double = 3
    @Published var cookingTime: Double = 30
    @Published var allergiesRestrictions = ""
    @Published var customGoals = ""
    @Published var age: Double = 30
    @Published var gender: String = "Other"
    @Published var currentWeight: String = ""
    @Published var targetWeight: String = ""
    @Published var hasHealthConditions = false
    @Published var healthConditions = ""
    
    @Published var structuredNutritionPlan: NutritionPlan?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showFullPlan = false
    @Published var showHealthDisclaimer = false
    @Published var generationProgress: String = ""

    private let userDefaults = UserDefaults.standard
    private let planKey = "weekly_nutrition_plan"
    private let planDateKey = "nutrition_plan_creation_date"
    private let disclaimerKey = "nutrition_disclaimer_acknowledged"

    // Simplified daily themes for variety
    private let dailyThemes = [
        "Monday": ("Fresh Start", "Begin week with good food", "🔋"),
        "Tuesday": ("Mixed Variety", "Different food types", "⚖️"),
        "Wednesday": ("Colorful Foods", "Various ingredients", "🌈"),
        "Thursday": ("Simple Cooking", "Easy preparation", "👨‍🍳"),
        "Friday": ("Light Foods", "Lighter options", "🥗"),
        "Saturday": ("Seasonal Items", "Fresh ingredients", "🌿"),
        "Sunday": ("Food Planning", "Prepare for week", "📦")
    ]
    
    // Simple variety helpers
    private let cookingMethods = [
        "Monday": "grilled and baked",
        "Tuesday": "steamed and sautéed",
        "Wednesday": "raw and roasted",
        "Thursday": "stir-fried and boiled",
        "Friday": "fresh and blended",
        "Saturday": "slow-cooked and grilled",
        "Sunday": "batch-cooked and prepared"
    ]

    var isPlanExpired: Bool {
        guard let date = userDefaults.object(forKey: planDateKey) as? Date else { return true }
        return Date().timeIntervalSince(date) > (7 * 24 * 60 * 60) // 7 days
    }

    var planExpirationDate: String {
        guard let date = userDefaults.object(forKey: planDateKey) as? Date else { return "N/A" }
        let expirationDate = date.addingTimeInterval(7 * 24 * 60 * 60)
        return expirationDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    var estimatedCalorieNeeds: String {
        // Simplified calculation for reference only
        let baseCalories = 1800.0
        let adjustment = activityLevel.calorieMultiplier - 1.0
        let adjusted = baseCalories + (baseCalories * adjustment * 0.2)
        let lower = Int(adjusted * 0.9)
        let upper = Int(adjusted * 1.1)
        
        return "\(lower)-\(upper) calories (estimate only)"
    }

    func loadSavedPlan() {
        if !isPlanExpired,
           let data = userDefaults.data(forKey: planKey),
           let plan = try? JSONDecoder().decode(NutritionPlan.self, from: data) {
            self.structuredNutritionPlan = plan
        } else {
            clearSavedPlan()
        }
    }

    func generateNutritionPlan() {
        isLoading = true
        errorMessage = nil
        generationProgress = "Starting..."
        
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
        print("Starting nutrition meal planning...")
        Task {
            do {
                await MainActor.run {
                    self.generationProgress = "Creating meal suggestions..."
                }
                
                // Phase 1: Generate daily meal suggestions with safer prompts
                var dailyPlans: [DailyMealPlan] = []
                let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
                
                for (index, day) in daysOfWeek.enumerated() {
                    await MainActor.run {
                        self.generationProgress = "Planning \(day) meals... (\(index + 1)/7)"
                    }
                    
                    let session = LanguageModelSession()
                    print("Creating meal suggestions for \(day)...")
                    
                    let prompt = createSafeDailyMealPrompt(for: day, dayIndex: index)
                    let response = try await session.respond(to: prompt, generating: DailyMealPlan.self)
                    var plan = response.content
                    plan.title = day
                    dailyPlans.append(plan)
                    
                    // Brief pause between requests
                    try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                }
                
                await MainActor.run {
                    self.generationProgress = "Adding nutrition guidance..."
                }
                
                // Phase 2: Generate general nutrition guidance
                print("Creating nutrition guidance...")
                let extrasSession = LanguageModelSession()
                let extrasPrompt = createSafeExtrasPrompt()
                let extras = try await extrasSession.respond(to: extrasPrompt, generating: NutritionExtras.self).content
                
                await MainActor.run {
                    self.generationProgress = "Finalizing meal plan..."
                }
                
                // Phase 3: Assemble the plan
                let finalPlan = NutritionPlan(
                    dietaryApproach: dietaryApproach.rawValue,
                    primaryGoal: primaryGoal.rawValue,
                    activityLevel: activityLevel.rawValue,
                    mealsPerDay: "\(Int(mealsPerDay))",
                    calorieRange: extras.calorieRange,
                    dailyMealPlans: dailyPlans,
                    nutritionTips: extras.nutritionTips,
                    safetyGuidelines: extras.safetyGuidelines,
                    mealPrepTips: extras.mealPrepTips,
                    weeklyShoppingList: extras.weeklyShoppingList,
                    hydrationGuidance: extras.hydrationGuidance,
                    supplementSuggestions: extras.supplementSuggestions
                )
                
                let jsonData = try JSONEncoder().encode(finalPlan)
                
                await MainActor.run {
                    self.structuredNutritionPlan = finalPlan
                    self.userDefaults.set(jsonData, forKey: self.planKey)
                    self.userDefaults.set(Date(), forKey: self.planDateKey)
                    self.isLoading = false
                    self.generationProgress = ""
                    print("Successfully created meal plan suggestions.")
                }
                
            } catch {
                await MainActor.run {
                    print("AI generation failed with error: \(error)")
                    self.errorMessage = "Failed to generate your nutrition plan. Please try again."
                    self.isLoading = false
                    self.generationProgress = ""
                }
            }
        }
    }

    private func createSafeDailyMealPrompt(for day: String, dayIndex: Int) -> String {
        let (focus, _, _) = dailyThemes[day] ?? ("Balanced Variety", "Mixed food groups", "🍽️")
        
        var prompt = """
        Suggest \(Int(mealsPerDay)) food ideas for \(day) with a theme of: \(focus).

        Food Style: \(dietaryApproach.rawValue)
        """
        
        if !allergiesRestrictions.isEmpty {
            prompt += "\nAvoid: \(allergiesRestrictions)"
        }
        
        prompt += """

        Provide a variety of ingredients and simple cooking methods.
        """
        
        return prompt
    }
    
    private func createSafeExtrasPrompt() -> String {
        let prompt = """
        Provide general food guidance for a \(dietaryApproach.rawValue) food style.

        Include basic cooking tips and common grocery items.
        """
        
        return prompt
    }
    
    func resetPlan() {
        structuredNutritionPlan = nil
        errorMessage = nil
        showFullPlan = false
        generationProgress = ""
        clearSavedPlan()
    }

    private func clearSavedPlan() {
        userDefaults.removeObject(forKey: planKey)
        userDefaults.removeObject(forKey: planDateKey)
    }
    
    func exportPlanToText() -> String {
        guard let plan = structuredNutritionPlan else { return "" }
        
        var text = """
        🍎 MEAL PLANNING SUGGESTIONS
        Generated: \(Date().formatted(date: .abbreviated, time: .omitted))
        
        📊 PREFERENCES OVERVIEW
        • Food Style: \(plan.dietaryApproach)
        • Primary Goal: \(plan.primaryGoal)
        • Activity Level: \(plan.activityLevel)
        • Calorie Reference: \(plan.calorieRange)
        • Meals Per Day: \(plan.mealsPerDay)
        
        """
        
        // Add daily meal suggestions
        for dailyPlan in plan.dailyMealPlans {
            text += """
            
            📅 \(dailyPlan.title.uppercased())
            Theme: \(dailyPlan.focus)
            Calorie Range: \(dailyPlan.dailyCalorieEstimate)
            Key Foods: \(dailyPlan.keyNutrients)
            
            """
            
            for meal in dailyPlan.meals {
                text += """
                \(meal.mealType): \(meal.name)
                • Ingredients: \(meal.ingredients)
                • Preparation: \(meal.prepInstructions) (\(meal.prepTime))
                • Calories: \(meal.calorieEstimate)
                \(meal.notes.isEmpty ? "" : "• Notes: \(meal.notes)")
                
                """
            }
            
            text += """
            💧 Hydration: \(dailyPlan.hydrationGoal)
            📝 Notes: \(dailyPlan.notes)
            
            """
        }
        
        // Add additional sections
        if !plan.nutritionTips.isEmpty {
            text += "\n💡 GENERAL NUTRITION SUGGESTIONS\n"
            for (index, tip) in plan.nutritionTips.enumerated() {
                text += "\(index + 1). \(tip)\n"
            }
        }
        
        if !plan.weeklyShoppingList.isEmpty {
            text += "\n🛒 SHOPPING SUGGESTIONS\n"
            for item in plan.weeklyShoppingList {
                text += "• \(item)\n"
            }
        }
        
        if !plan.safetyGuidelines.isEmpty {
            text += "\n⚠️ IMPORTANT REMINDERS\n"
            for guideline in plan.safetyGuidelines {
                text += "• \(guideline)\n"
            }
        }
        
        return text
    }
}
