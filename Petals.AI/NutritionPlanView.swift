import SwiftUI
import FoundationModels

struct NutritionPlanView: View {
    @StateObject private var viewModel = NutritionPlanViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? [
                    Color.green.opacity(0.2),
                    Color.blue.opacity(0.1),
                    Color.black
                ] : [
                    Color.green.opacity(0.1),
                    Color.blue.opacity(0.05),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
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
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    
                    VStack(spacing: 16) {
                        Image("icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)

                        Text("AI Nutrition Planner")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(.top, 20)

                    if let plan = viewModel.structuredNutritionPlan, !viewModel.isPlanExpired {
                        existingPlanView(plan: plan)
                    } else {
                        configurationView
                    }

                    Spacer(minLength: 30)
                }
            }
        }
        .sheet(isPresented: $viewModel.showFullPlan) {
            if let plan = viewModel.structuredNutritionPlan {
                NutritionPlanDetailView(plan: plan)
            }
        }
        .onAppear {
            viewModel.loadSavedPlan()
        }
        .alert("Important Reminder", isPresented: $viewModel.showHealthDisclaimer) {
            Button("I Understand") { viewModel.acknowledgeDisclaimer() }
            Button("Cancel", role: .cancel) { viewModel.isLoading = false }
        } message: {
            Text("This AI provides general nutrition information only. Always consult with healthcare professionals or registered dietitians before making significant dietary changes. Individual nutritional needs vary based on health conditions and other factors.")
        }
    }

    private func existingPlanView(plan: NutritionPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "leaf.circle.fill")
                    .foregroundColor(.green)
                Text("Your Nutrition Plan")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Expires")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.planExpirationDate)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("Your personalized nutrition guide is ready!")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal)

                Button(action: { viewModel.showFullPlan = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.fill")
                            .font(.title2)
                        Text("View Nutrition Guide")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)

                Button(action: { viewModel.resetPlan() }) {
                    Text("Create New Guide")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
        }
    }

    private var configurationView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.green)
                    Text("Configure Your Nutrition Guide")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.text.square")
                            .foregroundColor(.blue)
                        Text("Health & Safety")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    Text("This tool provides educational nutrition information only. Please consult healthcare professionals or registered dietitians before making dietary changes.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 20) {
                    formSection(title: "Dietary Approach", icon: "leaf.fill") {
                        Picker("Dietary Approach", selection: $viewModel.dietaryApproach) {
                            ForEach(DietaryApproach.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                    }
                    formSection(title: "Primary Goal", icon: "target") {
                        Picker("Goal", selection: $viewModel.primaryGoal) {
                            ForEach(NutritionGoal.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity)
                    }
                    formSection(title: "Activity Level", icon: "figure.run") {
                        Picker("Activity Level", selection: $viewModel.activityLevel) {
                            ForEach(ActivityLevel.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: .infinity)
                    }
                    formSection(title: "Meals per day: \(Int(viewModel.mealsPerDay))", icon: "fork.knife") {
                        Slider(value: $viewModel.mealsPerDay, in: 3...6, step: 1).accentColor(.green)
                        .frame(maxWidth: .infinity)
                    }
                    formSection(title: "Cooking Time: \(Int(viewModel.cookingTime)) minutes", icon: "timer") {
                        Slider(value: $viewModel.cookingTime, in: 10...60, step: 10).accentColor(.green)
                        .frame(maxWidth: .infinity)
                    }
                    formSection(title: "Food Allergies & Restrictions", icon: "exclamationmark.triangle.fill") {
                        TextField("e.g., nuts, dairy, gluten", text: $viewModel.allergiesRestrictions)
                            .textFieldStyle(.roundedBorder).frame(maxWidth: .infinity)
                    }
                    formSection(title: "Nutrition Focus", icon: "heart.fill") {
                        TextField("e.g., increase protein, reduce sugar", text: $viewModel.customGoals)
                            .textFieldStyle(.roundedBorder).frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)

                Button(action: { viewModel.generateNutritionPlan() }) {
                    HStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles").font(.title2)
                        }
                        Text(viewModel.isLoading ? "Creating Your Guide..." : "Generate Nutrition Guide")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: viewModel.isLoading ? [.gray] : [.green, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(16)
                    .shadow(color: viewModel.isLoading ? .clear : .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(viewModel.isLoading)
                .padding([.horizontal, .bottom])

                if let error = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                        Text(error).foregroundColor(.red)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    private func formSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(.green)
                Text(title).font(.headline).fontWeight(.medium)
            }
            content()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct NutritionPlanDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let plan: NutritionPlan

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ? [.green.opacity(0.2), .blue.opacity(0.1), .black] : [.green.opacity(0.1), .blue.opacity(0.05), .white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header.padding([.top, .horizontal])
                        planOverviewSection(plan)
                        ForEach(plan.dailyMealPlans) { mealPlan in
                            dailyMealPlanCard(mealPlan)
                        }
                        if !plan.nutritionTips.isEmpty { nutritionTipsSection(plan.nutritionTips) }
                        if !plan.safetyGuidelines.isEmpty { safetySection(plan.safetyGuidelines) }
                        if !plan.mealPrepTips.isEmpty { mealPrepSection(plan.mealPrepTips) }
                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) { closeButton }
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            Image("icon").resizable().scaledToFit().frame(width: 50, height: 50).clipShape(RoundedRectangle(cornerRadius: 12))
            Text("Your Nutrition Guide").font(.title2).fontWeight(.bold)
                .foregroundStyle(LinearGradient(colors: [.green, .blue], startPoint: .leading, endPoint: .trailing))
            HStack {
                Image(systemName: "info.circle.fill").foregroundColor(.blue)
                Text("Educational content - consult professionals for personalized advice").font(.caption).foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .foregroundColor(.secondary)
                .background(Circle().fill(Color(.systemBackground)))
        }
        .padding()
    }

    @ViewBuilder
    private func planOverviewSection(_ plan: NutritionPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plan Overview")
                .font(.headline)
                .foregroundColor(.green)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if !plan.dietaryApproach.isEmpty {
                    overviewCard(title: "Approach", value: plan.dietaryApproach, icon: "leaf.fill")
                }
                if !plan.primaryGoal.isEmpty {
                    overviewCard(title: "Goal", value: plan.primaryGoal, icon: "target")
                }
                if !plan.activityLevel.isEmpty {
                    overviewCard(title: "Activity", value: plan.activityLevel, icon: "figure.run")
                }
                if !plan.mealsPerDay.isEmpty {
                    overviewCard(title: "Meals", value: plan.mealsPerDay, icon: "fork.knife")
                }
                if !plan.calorieRange.isEmpty {
                    overviewCard(title: "Calories", value: plan.calorieRange, icon: "flame.fill")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func overviewCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func dailyMealPlanCard(_ mealPlan: DailyMealPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(mealPlan.title)
                        .font(.headline)
                        .foregroundColor(.green)
                    if !mealPlan.focus.isEmpty {
                        Text("Focus: \(mealPlan.focus)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()

                Image(systemName: "fork.knife.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }

            if !mealPlan.meals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Suggested Meals")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    ForEach(mealPlan.meals) { meal in
                        mealRow(meal)
                    }
                }
            }

            if !mealPlan.hydrationGoal.isEmpty || !mealPlan.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if !mealPlan.hydrationGoal.isEmpty {
                        HStack {
                            Image(systemName: "drop.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("Hydration goal: \(mealPlan.hydrationGoal)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    if !mealPlan.notes.isEmpty {
                        HStack(alignment: .top) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(mealPlan.notes)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func mealRow(_ meal: Meal) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("")

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(meal.mealType)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    
                    Spacer()
                }

                Text(meal.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if !meal.ingredients.isEmpty {
                    Text("Ingredients: \(meal.ingredients)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if !meal.notes.isEmpty {
                    Text(meal.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func nutritionTipsSection(_ tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.headline)
                    .foregroundColor(.green)
                Text("Nutrition Tips")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            ForEach(tips.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text(tips[index])
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func safetySection(_ guidelines: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.headline)
                    .foregroundColor(.red)
                Text("Safety Reminders")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            ForEach(guidelines.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text(guidelines[index])
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func mealPrepSection(_ tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                    .font(.headline)
                    .foregroundColor(.blue)
                Text("Meal Prep & Planning")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            ForEach(tips.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(tips[index])
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

#Preview {
    NutritionPlanView()
}
