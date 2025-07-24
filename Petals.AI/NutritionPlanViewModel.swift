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
    @Guide(description: "A brief summary of the day's nutritional focus (e.g., 'High-Protein Energy', 'Anti-Inflammatory Recovery', 'Balanced Variety').")
    var focus: String
    var meals: [Meal]
    @Guide(description: "A daily hydration goal specific to this day's activities (e.g., '2.5 liters - extra water for workout day').")
    var hydrationGoal: String
    @Guide(description: "Any special notes for the day (e.g., 'Great day for meal prep', 'Pack snacks for busy schedule').")
    var notes: String
    @Guide(description: "Estimated total calories for all meals combined (e.g., '1850-2050 calories').")
    var dailyCalorieEstimate: String
    @Guide(description: "Key nutrients emphasized today (e.g., 'High in protein, vitamin C, omega-3s').")
    var keyNutrients: String
}

@Generable()
struct Meal: Codable, Identifiable {
    var id: String = UUID().uuidString
    var mealType: String
    var name: String
    var ingredients: String
    var notes: String
    @Guide(description: "Brief preparation instructions or cooking method (e.g., 'Sauté for 5 mins', 'Blend until smooth').")
    var prepInstructions: String
    @Guide(description: "Estimated calories for this meal (e.g., '350-400').")
    var calorieEstimate: String
    @Guide(description: "Estimated prep time in minutes (e.g., '15').")
    var prepTime: String
}

@Generable()
struct NutritionExtras: Codable {
    @Guide(description: "A personalized daily calorie range based on the user's profile, goals, and activity level (e.g., '1800-2200 calories').")
    var calorieRange: String
    @Guide(description: "A list of 5-6 specific, actionable nutrition tips tailored to the user's dietary approach and goals.")
    var nutritionTips: [String]
    @Guide(description: "A list of 3 important safety guidelines, disclaimers, and when to consult professionals.")
    var safetyGuidelines: [String]
    @Guide(description: "A list of 4 practical meal prep tips that work with the user's time constraints and cooking preferences.")
    var mealPrepTips: [String]
    @Guide(description: "A comprehensive weekly shopping list organized by food categories (produce, proteins, pantry items, etc.).")
    var weeklyShoppingList: [String]
    @Guide(description: "Personalized hydration guidance based on activity level and goals (e.g., 'Aim for 2.5-3L daily, more on workout days').")
    var hydrationGuidance: String
    @Guide(description: "Evidence-based supplement suggestions relevant to the user's goals and dietary approach, with safety notes.")
    var supplementSuggestions: [String]
}

// MARK: - Enums

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
    case weightLoss = "Weight Loss"
    case weightGain = "Healthy Weight Gain"
    case muscleBuilding = "Muscle Building"
    case maintenance = "Weight Maintenance"
    case energy = "Boost Energy Levels"
    case health = "General Health & Wellness"
    case performance = "Athletic Performance"
    case digestiveHealth = "Digestive Health"
    case heartHealth = "Heart Health"
    case brainHealth = "Cognitive Function"
    case immuneSupport = "Immune Support"
    case hormonalBalance = "Hormonal Balance"
    
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
        "Monday": ("Energy Focus", "Start week with energizing meals", "🔋"),
        "Tuesday": ("Balanced Nutrition", "Steady energy throughout day", "⚖️"),
        "Wednesday": ("Colorful Variety", "Mix of different foods", "🌈"),
        "Thursday": ("Simple Prep", "Easy cooking methods", "👨‍🍳"),
        "Friday": ("Light Options", "Lighter meal choices", "🥗"),
        "Saturday": ("Fresh Ingredients", "Seasonal and fresh", "🌿"),
        "Sunday": ("Meal Prep", "Prepare for the week", "📦")
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
        // Simplified BMR calculation (Harris-Benedict)
        let bmr: Double
        if gender.lowercased() == "male" {
            bmr = 88.362 + (13.397 * (Double(currentWeight) ?? 70)) + (4.799 * (age * 2.54)) - (5.677 * age)
        } else {
            bmr = 447.593 + (9.247 * (Double(currentWeight) ?? 60)) + (3.098 * (age * 2.54)) - (4.330 * age)
        }
        
        let tdee = bmr * activityLevel.calorieMultiplier
        let lower = Int(tdee * 0.9)
        let upper = Int(tdee * 1.1)
        
        return "\(lower)-\(upper) calories"
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
        generationProgress = "Initializing..."
        
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
        print("Starting enhanced nutrition plan generation...")
        Task {
            do {
                await MainActor.run {
                    self.generationProgress = "Creating personalized daily meal plans..."
                }
                
                // Phase 1: Generate varied daily meal plans
                var dailyPlans: [DailyMealPlan] = []
                let daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
                
                for (index, day) in daysOfWeek.enumerated() {
                    await MainActor.run {
                        self.generationProgress = "Designing \(day)'s meals... (\(index + 1)/7)"
                    }
                    
                    let session = LanguageModelSession()
                    print("Generating enhanced plan for \(day) (day \(index + 1))...")
                    
                    let prompt = createEnhancedDailyMealPrompt(for: day, dayIndex: index)
                    let response = try await session.respond(to: prompt, generating: DailyMealPlan.self)
                    var plan = response.content
                    plan.title = day
                    dailyPlans.append(plan)
                    
                    // Reduced delay
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                }
                
                await MainActor.run {
                    self.generationProgress = "Generating nutrition guidance and shopping list..."
                }
                
                // Phase 2: Generate comprehensive extras
                print("Generating comprehensive nutrition extras...")
                let extrasSession = LanguageModelSession()
                let extrasPrompt = createComprehensiveExtrasPrompt()
                let extras = try await extrasSession.respond(to: extrasPrompt, generating: NutritionExtras.self).content
                
                await MainActor.run {
                    self.generationProgress = "Finalizing your personalized nutrition plan..."
                }
                
                // Phase 3: Assemble the comprehensive plan
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
                    print("Successfully generated and saved the comprehensive nutrition plan.")
                }
                
            } catch {
                await MainActor.run {
                    print("AI generation failed with error: \(error)")
                    self.errorMessage = "Failed to generate your nutrition plan. Please check your connection and try again."
                    self.isLoading = false
                    self.generationProgress = ""
                }
            }
        }
    }

    private func createEnhancedDailyMealPrompt(for day: String, dayIndex: Int) -> String {
        let (focus, _, _) = dailyThemes[day] ?? ("Balanced Nutrition", "Balanced meals", "🍽️")
        
        var prompt = """
        Create a meal plan for \(day). This is day \(dayIndex + 1) of a 7-day plan.
        
        User preferences:
        - Diet: \(dietaryApproach.rawValue)
        - Goal: \(primaryGoal.rawValue)
        - Activity: \(activityLevel.rawValue)
        - Meals per day: \(Int(mealsPerDay))
        - Cooking time: \(Int(cookingTime)) minutes
        """
        
        if !allergiesRestrictions.isEmpty {
            prompt += "\n- Avoid: \(allergiesRestrictions)"
        }
        
        if !customGoals.isEmpty {
            prompt += "\n- Focus: \(customGoals)"
        }
        
        prompt += """
        
        Day focus: \(focus)
        
        Please create varied meals that are different from other days. Include:
        - Different cooking methods each day
        - Varied ingredients and flavors
        - Appropriate portions and prep instructions
        """
        
        return prompt
    }
    
    private func createComprehensiveExtrasPrompt() -> String {
        var prompt = """
        Create nutrition guidance for this profile:
        
        Diet: \(dietaryApproach.rawValue)
        Goal: \(primaryGoal.rawValue)
        Activity: \(activityLevel.rawValue)
        Meals per day: \(Int(mealsPerDay))
        """
        
        if !allergiesRestrictions.isEmpty {
            prompt += "\nAvoid: \(allergiesRestrictions)"
        }
        
        if !customGoals.isEmpty {
            prompt += "\nFocus: \(customGoals)"
        }
        
        prompt += """
        
        Please provide:
        1. Daily calorie range
        2. 5 practical nutrition tips
        3. 3 safety reminders about consulting professionals
        4. 4 meal prep suggestions
        5. Weekly shopping list by category
        6. Daily water intake recommendation
        7. General supplement considerations with safety notes
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
        🍎 PERSONALIZED NUTRITION PLAN
        Generated: \(Date().formatted(date: .abbreviated, time: .omitted))
        
        📊 PROFILE OVERVIEW
        • Dietary Approach: \(plan.dietaryApproach)
        • Primary Goal: \(plan.primaryGoal)
        • Activity Level: \(plan.activityLevel)
        • Daily Calorie Range: \(plan.calorieRange)
        • Meals Per Day: \(plan.mealsPerDay)
        
        """
        
        // Add daily meal plans
        for dailyPlan in plan.dailyMealPlans {
            text += """
            
            📅 \(dailyPlan.title.uppercased())
            Focus: \(dailyPlan.focus)
            Daily Calories: \(dailyPlan.dailyCalorieEstimate)
            Key Nutrients: \(dailyPlan.keyNutrients)
            
            """
            
            for meal in dailyPlan.meals {
                text += """
                \(meal.mealType): \(meal.name)
                • Ingredients: \(meal.ingredients)
                • Prep: \(meal.prepInstructions) (\(meal.prepTime) min)
                • Calories: \(meal.calorieEstimate)
                \(meal.notes.isEmpty ? "" : "• Notes: \(meal.notes)")
                
                """
            }
            
            text += """
            💧 Hydration: \(dailyPlan.hydrationGoal)
            📝 Daily Notes: \(dailyPlan.notes)
            
            """
        }
        
        // Add additional sections
        if !plan.nutritionTips.isEmpty {
            text += "\n💡 NUTRITION TIPS\n"
            for (index, tip) in plan.nutritionTips.enumerated() {
                text += "\(index + 1). \(tip)\n"
            }
        }
        
        if !plan.weeklyShoppingList.isEmpty {
            text += "\n🛒 WEEKLY SHOPPING LIST\n"
            for item in plan.weeklyShoppingList {
                text += "• \(item)\n"
            }
        }
        
        return text
    }
}
