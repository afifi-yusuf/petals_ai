import SwiftUI
import FoundationModels

struct WorkoutPlanView: View {
    @StateObject private var viewModel = WorkoutPlanViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? [
                    Color.orange.opacity(0.2),
                    Color.red.opacity(0.1),
                    Color.black
                ] : [
                    Color.orange.opacity(0.1),
                    Color.red.opacity(0.05),
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
                            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)

                        Text("AI Workout Planner")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(.top, 20)

                    if let plan = viewModel.structuredWorkoutPlan, !viewModel.isPlanExpired {
                        existingPlanView(plan: plan)
                    } else {
                        configurationView
                    }

                    Spacer(minLength: 30)
                }
            }
        }
        .sheet(isPresented: $viewModel.showFullPlan) {
            if let plan = viewModel.structuredWorkoutPlan {
                WorkoutPlanDetailView(plan: plan)
            }
        }
        .onAppear {
            viewModel.loadSavedPlan()
        }
        .alert("Important Reminder", isPresented: $viewModel.showHealthDisclaimer) {
            Button("I Understand") { viewModel.acknowledgeDisclaimer() }
            Button("Cancel", role: .cancel) { viewModel.isLoading = false }
        } message: {
            Text("This AI provides general fitness information only. Always consult with healthcare professionals before starting any exercise program. Listen to your body and stop if you feel pain or discomfort.")
        }
    }

    private func existingPlanView(plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.checkmark")
                    .foregroundColor(.green)
                Text("Your Weekly Plan")
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
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("Your personalized workout guide is ready!")
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
                        Text("View Workout Guide")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(16)
                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal)

                Button(action: { viewModel.resetPlan() }) {
                    Text("Create New Guide")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
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
                        .foregroundColor(.orange)
                    Text("Configure Your Workout Guide")
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
                    Text("This tool provides educational fitness information only. Please consult healthcare professionals before starting any exercise program.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 20) {
                    formSection(title: "Experience Level", icon: "figure.strengthtraining.traditional") {
                        Picker("Experience Level", selection: $viewModel.fitnessLevel) {
                            ForEach(FitnessLevel.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    formSection(title: "Preferred Activity Type", icon: "dumbbell.fill") {
                        Picker("Activity Type", selection: $viewModel.workoutType) {
                            ForEach(WorkoutType.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                    }
                    formSection(title: "Target Duration: \(Int(viewModel.duration)) minutes", icon: "clock.fill") {
                        Slider(value: $viewModel.duration, in: 15...90, step: 15).accentColor(.orange)
                    }
                    formSection(title: "Sessions per week: \(Int(viewModel.daysPerWeek))", icon: "calendar") {
                        Slider(value: $viewModel.daysPerWeek, in: 1...7, step: 1).accentColor(.orange)
                    }
                    formSection(title: "Available Equipment", icon: "wrench.and.screwdriver.fill") {
                        Picker("Equipment", selection: $viewModel.equipment) {
                            ForEach(Equipment.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                    }
                    formSection(title: "Fitness Interests", icon: "target") {
                        TextField("e.g., improve stamina, build strength", text: $viewModel.customGoals)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.horizontal)

                Button(action: { viewModel.generateWorkoutPlan() }) {
                    HStack(spacing: 12) {
                        if viewModel.isLoading {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles").font(.title2)
                        }
                        Text(viewModel.isLoading ? "Creating Your Guide..." : "Generate Workout Guide")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: viewModel.isLoading ? [.gray] : [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(16)
                    .shadow(color: viewModel.isLoading ? .clear : .orange.opacity(0.3), radius: 8, x: 0, y: 4)
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
                Image(systemName: icon).foregroundColor(.orange)
                Text(title).font(.headline).fontWeight(.medium)
            }
            content()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct WorkoutPlanDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let plan: WorkoutPlan

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ? [.orange.opacity(0.2), .red.opacity(0.1), .black] : [.orange.opacity(0.1), .red.opacity(0.05), .white]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header.padding([.top, .horizontal])
                        planOverviewSection(plan)
                        ForEach(plan.dailyWorkouts) { workout in
                            dailyWorkoutCard(workout)
                        }
                        if !plan.progressionTips.isEmpty { progressionSection(plan.progressionTips) }
                        if !plan.safetyGuidelines.isEmpty { safetySection(plan.safetyGuidelines) }
                        if !plan.recoveryNutrition.isEmpty { recoverySection(plan.recoveryNutrition) }
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
            Text("Your Workout Guide").font(.title2).fontWeight(.bold)
                .foregroundStyle(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing))
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
    private func planOverviewSection(_ plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Guide Overview")
                .font(.headline)
                .foregroundColor(.orange)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if !plan.fitnessLevel.isEmpty {
                    overviewCard(title: "Level", value: plan.fitnessLevel, icon: "figure.strengthtraining.traditional")
                }
                if !plan.workoutType.isEmpty {
                    overviewCard(title: "Type", value: plan.workoutType, icon: "dumbbell.fill")
                }
                if !plan.duration.isEmpty {
                    overviewCard(title: "Duration", value: plan.duration, icon: "clock.fill")
                }
                if !plan.frequency.isEmpty {
                    overviewCard(title: "Frequency", value: plan.frequency, icon: "calendar")
                }
                if !plan.goals.isEmpty {
                    overviewCard(title: "Goals", value: plan.goals, icon: "target")
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
                .foregroundColor(.orange)
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
    private func dailyWorkoutCard(_ workout: DailyWorkout) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.title)
                        .font(.headline)
                        .foregroundColor(.orange)
                    if !workout.focus.isEmpty {
                        Text("Focus: \(workout.focus)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()

                if workout.isRestDay {
                    Image(systemName: "bed.double.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
            }

            if !workout.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested Activities")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    ForEach(workout.exercises) { exercise in
                        exerciseRow(exercise)
                    }
                }
            }

            if !workout.restPeriod.isEmpty || !workout.notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if !workout.restPeriod.isEmpty {
                        HStack {
                            Image(systemName: "timer")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("Suggested rest: \(workout.restPeriod)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    if !workout.notes.isEmpty {
                        HStack(alignment: .top) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(workout.notes)
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
    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("") // For styling, add a bullet or badge if desired

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                if !exercise.setsReps.isEmpty {
                    Text("Suggested: \(exercise.setsReps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if !exercise.notes.isEmpty {
                    Text(exercise.notes)
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
    private func progressionSection(_ tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                    .foregroundColor(.green)
                Text("Progression Ideas")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            ForEach(tips.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
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
    private func recoverySection(_ recovery: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square")
                    .font(.headline)
                    .foregroundColor(.blue)
                Text("Recovery & Wellness")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            ForEach(recovery.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(recovery[index])
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
    WorkoutPlanView()
}

