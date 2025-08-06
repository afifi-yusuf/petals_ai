import SwiftUI
import FamilyControls
import DeviceActivity

extension DeviceActivityReport.Context {
    static let pieChart = Self("Pie Chart")
}

// MARK: - Main View
struct BlockAppPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // MARK: State Management
    // Selections for each schedule
    @State private var morningSelection = FamilyActivitySelection()
    @State private var workSelection = FamilyActivitySelection()
    @State private var eveningSelection = FamilyActivitySelection()
    @State private var customSelection = FamilyActivitySelection()

    // Picker presentation states
    @State private var isMorningPickerPresented = false
    @State private var isWorkPickerPresented = false
    @State private var isEveningPickerPresented = false
    @State private var isCustomPickerPresented = false

    // Custom schedule time pickers
    @State private var customStartTime = Date()
    @State private var customEndTime = Date()

    // UI state
    @State private var showingHelpSheet = false
    @State private var isSaving = false

    // A single model instance to interact with the system's apply method
    private let systemAppModel = AppSelectionModel()
    
    // MARK: Computed Properties
    private var schedules: [Schedule] {
        [
            Schedule(name: "Morning", icon: "sunrise.fill", color: .orange, selection: $morningSelection, isPickerPresented: $isMorningPickerPresented),
            Schedule(name: "Work", icon: "briefcase.fill", color: .blue, selection: $workSelection, isPickerPresented: $isWorkPickerPresented),
            Schedule(name: "Evening", icon: "moon.fill", color: .indigo, selection: $eveningSelection, isPickerPresented: $isEveningPickerPresented),
            Schedule(name: "Custom", icon: "slider.horizontal.3", color: .green, selection: $customSelection, isPickerPresented: $isCustomPickerPresented, startTime: $customStartTime, endTime: $customEndTime)
        ]
    }
    
    // MARK: Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Main content
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            scheduleSections
                            
                            actionSection
                            
                            helpSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .sheet(isPresented: $showingHelpSheet) { helpSheet }
            .onAppear(perform: loadAllSettings)
        }
    }
}

// MARK: - View Components
private extension BlockAppPicker {
    var headerSection: some View {
        HStack {
            Image(systemName: "shield.fill")
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Text("App Restrictions")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    var scheduleSections: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Daily Schedules")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.top, 8)
            
            LazyVStack(spacing: 12) {
                ForEach(schedules, id: \.name) { schedule in
                    EnhancedSchedulePickerRow(schedule: schedule)
                }
            }
        }
    }

    var actionSection: some View {
        VStack(spacing: 16) {
            applyButton
            
            Text("Changes will take effect immediately and apply to all selected apps during their scheduled times.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }
    
    var applyButton: some View {
        Button(action: applyAllChanges) {
            HStack(spacing: 12) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                        .fontWeight(.medium)
                }
                
                Text(isSaving ? "Applying Changes..." : "Apply All Schedules")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: isSaving ? [.gray.opacity(0.6), .gray.opacity(0.8)] : [.purple, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isSaving)
        .animation(.easeInOut(duration: 0.2), value: isSaving)
    }

    var helpSection: some View {
        Button {
            showingHelpSheet = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("How Schedules Work")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Learn about app blocking schedules")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingHelpSheet = true
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                        .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                }
            }
        }
    }
    
    var helpSheet: some View {
        NavigationView {
            ZStack {
                AnimatedBackground()
                
                VStack(spacing: 0) {
                    // Header for help sheet
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                            .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Text("Schedule Help")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                        
                        Spacer()
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Understanding Schedule-Based App Blocking")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.top)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("How It Works")
                                    .font(.headline)
                                    .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                                
                                Text("Select specific apps to block during different parts of your day. When a schedule is active, the selected apps will be restricted and require Screen Time passcode to access.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Schedule Times")
                                    .font(.headline)
                                    .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Morning: 7:00 AM - 9:00 AM", systemImage: "sunrise.fill")
                                        .foregroundColor(.orange)
                                    Label("Work: 9:00 AM - 5:00 PM", systemImage: "briefcase.fill")
                                        .foregroundColor(.blue)
                                    Label("Evening: 8:00 PM - 10:00 PM", systemImage: "moon.fill")
                                        .foregroundColor(.indigo)
                                }
                                .font(.subheadline)
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingHelpSheet = false
                    }
                    .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                }
            }
        }
    }
}

// MARK: - Logic & Helper Methods
private extension BlockAppPicker {
    enum ScheduleType: String, CaseIterable {
        case morning, work, evening, custom
    }

    // MARK: Core Actions
    func applyAllChanges() {
        isSaving = true
        saveAllSettings()

        for scheduleType in ScheduleType.allCases {
            let selection = selection(for: scheduleType)
            let scheduleName = DeviceActivityName(rawValue: scheduleType.rawValue)
            let schedule = schedule(for: scheduleType)

            systemAppModel.selectionToDiscourage = selection
            systemAppModel.apply()

            let start = DateComponents(hour: schedule.start.hour, minute: schedule.start.minute)
            let end = DateComponents(hour: schedule.end.hour, minute: schedule.end.minute)

            Task {
                ScreenTimeManager.shared.startDailyWindow(start: start, end: end, activityName: scheduleName)
            }
        }

        Task {
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run { isSaving = false }
        }
    }

    func selection(for type: ScheduleType) -> FamilyActivitySelection {
        switch type {
        case .morning:
            return morningSelection
        case .work:
            return workSelection
        case .evening:
            return eveningSelection
        case .custom:
            return customSelection
        }
    }

    func schedule(for type: ScheduleType) -> (start: DateComponents, end: DateComponents) {
        switch type {
        case .morning:
            return (start: DateComponents(hour: 7, minute: 0), end: DateComponents(hour: 9, minute: 0))
        case .work:
            return (start: DateComponents(hour: 9, minute: 0), end: DateComponents(hour: 17, minute: 0))
        case .evening:
            return (start: DateComponents(hour: 20, minute: 0), end: DateComponents(hour: 22, minute: 0))
        case .custom:
            let start = Calendar.current.dateComponents([.hour, .minute], from: customStartTime)
            let end = Calendar.current.dateComponents([.hour, .minute], from: customEndTime)
            return (start: start, end: end)
        }
    }

    // MARK: Persistence
    func saveAllSettings() {
        ScheduleStore.save(morning: morningSelection, work: workSelection, evening: eveningSelection, custom: customSelection, customStartTime: customStartTime, customEndTime: customEndTime)
    }

    func loadAllSettings() {
        let schedules = ScheduleStore.load()
        morningSelection = schedules.morning
        workSelection = schedules.work
        eveningSelection = schedules.evening
        customSelection = schedules.custom
        customStartTime = schedules.customStartTime
        customEndTime = schedules.customEndTime
    }
}

// MARK: - Helper Structs
/// A helper struct to manage data for each schedule type.
private struct Schedule {
    let name: String
    let icon: String
    let color: Color
    var selection: Binding<FamilyActivitySelection>
    var isPickerPresented: Binding<Bool>
    var startTime: Binding<Date>?
    var endTime: Binding<Date>?
}

/// An enhanced schedule picker row with ChatbotView design consistency
private struct EnhancedSchedulePickerRow: View {
    let schedule: Schedule
    @Environment(\.colorScheme) private var colorScheme
    
    private var selectionCount: Int {
        schedule.selection.wrappedValue.applicationTokens.count
    }

    private var timeInterval: String {
        switch schedule.name {
        case "Morning":
            return "7:00 AM - 9:00 AM"
        case "Work":
            return "9:00 AM - 5:00 PM"
        case "Evening":
            return "8:00 PM - 10:00 PM"
        case "Custom":
            if let startTime = schedule.startTime?.wrappedValue, let endTime = schedule.endTime?.wrappedValue {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
            }
            return "Select time"
        default:
            return ""
        }
    }
    
    private var statusText: String {
        selectionCount == 0 ? "Tap to select apps" : "\(selectionCount) app\(selectionCount == 1 ? "" : "s") selected"
    }

    var body: some View {
        Button {
            schedule.isPickerPresented.wrappedValue = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    // Icon with background
                    ZStack {
                        Circle()
                            .fill(schedule.color.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: schedule.icon)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(schedule.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(schedule.name)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectionCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                    
                                    Text("\(selectionCount)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            LinearGradient(
                                                colors: [.purple.opacity(0.2), .blue.opacity(0.2)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .clipShape(Capsule())
                                        .foregroundStyle(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                                }
                            }
                        }
                        
                        Text(timeInterval)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(
                                selectionCount == 0 ?
                                LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [.green], startPoint: .leading, endPoint: .trailing)
                            )
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.tertiary)
                }
                
                if schedule.name == "Custom", let startTime = schedule.startTime, let endTime = schedule.endTime {
                    HStack {
                        DatePicker("Start Time", selection: startTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        
                        Text("-")
                        
                        DatePicker("End Time", selection: endTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                        
                        Spacer()
                    }
                    .padding(.leading, 66) // Align with text above
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .familyActivityPicker(isPresented: schedule.isPickerPresented, selection: schedule.selection)
        .animation(.easeInOut(duration: 0.2), value: selectionCount)
    }
}

/// A data store for saving and loading the three schedule selections.
private enum ScheduleStore {
    // IMPORTANT: Use your actual App Group name from your project settings
    static let suiteName = "group.com.example.YourApp"
    static let morningKey = "morningSelectionV2"
    static let workKey = "workSelectionV2"
    static let eveningKey = "eveningSelectionV2"
    static let customKey = "customSelectionV2"
    static let customStartTimeKey = "customStartTimeV2"
    static let customEndTimeKey = "customEndTimeV2"

    static func save(morning: FamilyActivitySelection, work: FamilyActivitySelection, evening: FamilyActivitySelection, custom: FamilyActivitySelection, customStartTime: Date, customEndTime: Date) {
        let defaults = UserDefaults(suiteName: suiteName)
        try? defaults?.set(JSONEncoder().encode(morning), forKey: morningKey)
        try? defaults?.set(JSONEncoder().encode(work), forKey: workKey)
        try? defaults?.set(JSONEncoder().encode(evening), forKey: eveningKey)
        try? defaults?.set(JSONEncoder().encode(custom), forKey: customKey)
        defaults?.set(customStartTime, forKey: customStartTimeKey)
        defaults?.set(customEndTime, forKey: customEndTimeKey)
    }

    static func load() -> (morning: FamilyActivitySelection, work: FamilyActivitySelection, evening: FamilyActivitySelection, custom: FamilyActivitySelection, customStartTime: Date, customEndTime: Date) {
        let defaults = UserDefaults(suiteName: suiteName)
        let morning = loadSelection(forKey: morningKey, from: defaults)
        let work = loadSelection(forKey: workKey, from: defaults)
        let evening = loadSelection(forKey: eveningKey, from: defaults)
        let custom = loadSelection(forKey: customKey, from: defaults)
        let customStartTime = defaults?.object(forKey: customStartTimeKey) as? Date ?? Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
        let customEndTime = defaults?.object(forKey: customEndTimeKey) as? Date ?? Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!
        return (morning, work, evening, custom, customStartTime, customEndTime)
    }

    private static func loadSelection(forKey key: String, from defaults: UserDefaults?) -> FamilyActivitySelection {
        guard let data = defaults?.data(forKey: key),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return FamilyActivitySelection()
        }
        return selection
    }
}

// MARK: - Required Extension for .sheet(item:)
extension String: Identifiable {
    public var id: String { self }
}
