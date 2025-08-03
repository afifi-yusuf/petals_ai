import SwiftUI
import FamilyControls
import DeviceActivity

extension DeviceActivityReport.Context {
    static let pieChart = Self("Pie Chart")
}

// MARK: - Main View
struct BlockAppPicker: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: State Management
    // Selections for each schedule
    @State private var morningSelection = FamilyActivitySelection()
    @State private var workSelection = FamilyActivitySelection()
    @State private var eveningSelection = FamilyActivitySelection()

    // Picker presentation states
    @State private var isMorningPickerPresented = false
    @State private var isWorkPickerPresented = false
    @State private var isEveningPickerPresented = false

    // App-specific settings
    @State private var appStartTimes: [String: Int] = [:]
    @State private var appEndTimes: [String: Int] = [:]
    @State private var appEnabled: [String: Bool] = [:]
    @State private var appNames: [String: String] = [:]

    // UI state
    @State private var expandedApps = Set<String>()
    @State private var showingDeleteConfirmation = false
    @State private var showingHelpSheet = false
    @State private var isSaving = false

    // For nickname prompt
    @State private var newAppIdToName: String? = nil
    @State private var pendingAppName: String = ""

    // A single model instance to interact with the system's apply method
    private let systemAppModel = AppSelectionModel()
    
    // MARK: Computed Properties
    private var schedules: [Schedule] {
        [
            Schedule(name: "Morning", icon: "sunrise.fill", color: .orange, selection: $morningSelection, isPickerPresented: $isMorningPickerPresented),
            Schedule(name: "Work", icon: "briefcase.fill", color: .blue, selection: $workSelection, isPickerPresented: $isWorkPickerPresented),
            Schedule(name: "Evening", icon: "moon.fill", color: .indigo, selection: $eveningSelection, isPickerPresented: $isEveningPickerPresented)
        ]
    }
    
    private var allSelectedAppIds: Set<String> {
        let allTokens = morningSelection.applicationTokens
            .union(workSelection.applicationTokens)
            .union(eveningSelection.applicationTokens)
        return Set(allTokens.map { String($0.hashValue) })
    }

    private var hasAnySelection: Bool {
        !allSelectedAppIds.isEmpty
    }

    // MARK: Body
    var body: some View {
        NavigationStack {
            Form {
                appSelectionSections
                
                if hasAnySelection {
                    scheduledAppsSections
                    actionSection
                }
                
                helpSection
            }
            .navigationTitle("App Restrictions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarItems }
            .sheet(isPresented: $showingHelpSheet) { helpSheet }
            .sheet(item: $newAppIdToName) { appId in // Corrected .sheet syntax
                nicknamePrompt(for: appId)
            }
            .confirmationDialog("Remove All Restrictions", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                deleteAllButton
            } message: {
                Text("This will clear all schedules and remove all app restrictions.")
            }
            .onAppear(perform: loadAllSettings)
            .onChange(of: isMorningPickerPresented) { _, isPresented in handlePickerDismiss(isPresented: isPresented, for: .morning) }
            .onChange(of: isWorkPickerPresented) { _, isPresented in handlePickerDismiss(isPresented: isPresented, for: .work) }
            .onChange(of: isEveningPickerPresented) { _, isPresented in handlePickerDismiss(isPresented: isPresented, for: .evening) }
        }
    }
}

// MARK: - View Components
private extension BlockAppPicker {
    var appSelectionSections: some View {
        Section {
            ForEach(schedules, id: \.name) { schedule in
                SchedulePickerRow(schedule: schedule)
            }
        } header: {
            Text("Schedules")
        } footer: {
            Text("Select apps to restrict during different parts of your day.")
        }
    }

    var scheduledAppsSections: some View {
        ForEach(schedules.filter { !$0.selection.wrappedValue.applicationTokens.isEmpty }, id: \.name) { schedule in
            Section(header: Text("\(schedule.name) Schedule")) {
                let appIds = schedule.selection.wrappedValue.applicationTokens.map { String($0.hashValue) }
                ForEach(Array(appIds.enumerated()), id: \.element) { index, appId in
                    AppTimeRow(
                        appId: appId,
                        appName: appNames[appId] ?? "Unnamed App",
                        appIndex: index + 1,
                        isExpanded: expandedApps.contains(appId),
                        startMinutes: appStartTimes[appId] ?? (17 * 60),
                        endMinutes: appEndTimes[appId] ?? (20 * 60),
                        isEnabled: appEnabled[appId] ?? true,
                        onToggleExpansion: { toggleExpansion(for: appId) },
                        onTimeUpdate: { start, end in updateTime(for: appId, start: start, end: end) },
                        onToggleEnabled: { toggleEnabled(for: appId) }
                    )
                }
            }
        }
    }

    var actionSection: some View {
        Section {
            applyButton
            removeButton
        }
    }
    
    var applyButton: some View {
        Button(action: applyAllChanges) {
            HStack {
                if isSaving {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: "clock.arrow.circlepath")
                }
                Text(isSaving ? "Applying..." : "Apply All Schedules")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isSaving)
    }

    var removeButton: some View {
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Remove All Restrictions")
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    var deleteAllButton: some View {
        Button("Remove All", role: .destructive) {
            morningSelection = FamilyActivitySelection()
            workSelection = FamilyActivitySelection()
            eveningSelection = FamilyActivitySelection()
            
            appStartTimes.removeAll()
            appEndTimes.removeAll()
            appEnabled.removeAll()
            appNames.removeAll()
            
            applyAllChanges()
        }
    }

    var helpSection: some View {
        Section {
            Button {
                showingHelpSheet = true
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle").foregroundStyle(.blue)
                    Text("How Schedules Work").foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(.tertiary).font(.caption)
                }
            }
        }
    }

    var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingHelpSheet = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
            }
        }
    }
    
    func nicknamePrompt(for appId: String) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Give this app a nickname:").font(.headline)
                TextField("App name", text: $pendingAppName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                Button("Save") {
                    saveNickname(for: appId)
                    findNextAppToName()
                }
                .buttonStyle(.borderedProminent)
                .disabled(pendingAppName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {
                        saveNickname(for: appId, isSkipped: true)
                        findNextAppToName()
                    }
                }
            }
        }
    }

    var helpSheet: some View {
        // The helpSheet view from your original code can be pasted here without changes.
        // For brevity, it's omitted but assumed to be present.
        Text("Help Content Goes Here")
            .padding()
    }
}


// MARK: - Logic & Helper Methods
private extension BlockAppPicker {
    enum ScheduleType { case morning, work, evening }

    func handlePickerDismiss(isPresented: Bool, for type: ScheduleType) {
        guard !isPresented else { return }
        
        ensureUniqueSelections(from: type)
        syncTimeWindowsWithSelections()
        saveAllSettings()
        findNextAppToName()
    }

    func ensureUniqueSelections(from updatedSchedule: ScheduleType) {
        switch updatedSchedule {
        case .morning:
            workSelection.applicationTokens.subtract(morningSelection.applicationTokens)
            eveningSelection.applicationTokens.subtract(morningSelection.applicationTokens)
        case .work:
            morningSelection.applicationTokens.subtract(workSelection.applicationTokens)
            eveningSelection.applicationTokens.subtract(workSelection.applicationTokens)
        case .evening:
            morningSelection.applicationTokens.subtract(eveningSelection.applicationTokens)
            workSelection.applicationTokens.subtract(eveningSelection.applicationTokens)
        }
    }

    func syncTimeWindowsWithSelections() {
        appStartTimes = appStartTimes.filter { allSelectedAppIds.contains($0.key) }
        appEndTimes = appEndTimes.filter { allSelectedAppIds.contains($0.key) }
        appEnabled = appEnabled.filter { allSelectedAppIds.contains($0.key) }
        appNames = appNames.filter { allSelectedAppIds.contains($0.key) }

        for id in allSelectedAppIds {
            if appStartTimes[id] == nil { appStartTimes[id] = 17 * 60 } // Default 5 PM
            if appEndTimes[id] == nil { appEndTimes[id] = 20 * 60 }   // Default 8 PM
            if appEnabled[id] == nil { appEnabled[id] = true }
        }
    }
    
    func findNextAppToName() {
        if let nextId = allSelectedAppIds.first(where: { appNames[$0] == nil }) {
            newAppIdToName = nextId
            pendingAppName = ""
        } else {
            newAppIdToName = nil
        }
    }
    
    func saveNickname(for appId: String, isSkipped: Bool = false) {
        if isSkipped {
            appNames[appId] = "Unnamed App"
        } else {
            appNames[appId] = pendingAppName.isEmpty ? "Unnamed App" : pendingAppName
        }
        saveTimeWindowsToUserDefaults()
    }

    func toggleExpansion(for appId: String) {
        if expandedApps.contains(appId) {
            expandedApps.remove(appId)
        } else {
            expandedApps.insert(appId)
        }
    }

    func updateTime(for appId: String, start: Int, end: Int) {
        appStartTimes[appId] = start
        appEndTimes[appId] = end
        saveTimeWindowsToUserDefaults()
    }

    func toggleEnabled(for appId: String) {
        appEnabled[appId] = !(appEnabled[appId] ?? true)
        saveTimeWindowsToUserDefaults()
    }
    
    // MARK: Core Actions
    func applyAllChanges() {
        isSaving = true
        saveAllSettings()

        var combinedSelection = FamilyActivitySelection()
        combinedSelection.applicationTokens = morningSelection.applicationTokens.union(workSelection.applicationTokens).union(eveningSelection.applicationTokens)
        combinedSelection.categoryTokens = morningSelection.categoryTokens.union(workSelection.categoryTokens).union(eveningSelection.categoryTokens)
        combinedSelection.webDomainTokens = morningSelection.webDomainTokens.union(workSelection.webDomainTokens).union(eveningSelection.webDomainTokens)

        systemAppModel.selectionToDiscourage = combinedSelection
        systemAppModel.apply()

        for appId in allSelectedAppIds {
            guard appEnabled[appId] == true else { continue }
            let startMin = appStartTimes[appId] ?? (17 * 60)
            let endMin = appEndTimes[appId] ?? (20 * 60)
            let start = DateComponents(hour: startMin / 60, minute: startMin % 60)
            let end = DateComponents(hour: endMin / 60, minute: endMin % 60)
            Task {
                // ScreenTimeManager.shared.startDailyWindow(start: start, end: end)
            }
        }

        Task {
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run { isSaving = false }
        }
    }

    // MARK: Persistence
    func saveAllSettings() {
        ScheduleStore.save(morning: morningSelection, work: workSelection, evening: eveningSelection)
        saveTimeWindowsToUserDefaults()
    }

    func loadAllSettings() {
        let schedules = ScheduleStore.load()
        morningSelection = schedules.morning
        workSelection = schedules.work
        eveningSelection = schedules.evening
        loadTimeWindowsFromUserDefaults()
        syncTimeWindowsWithSelections()
    }

    func saveTimeWindowsToUserDefaults() {
        let suite = UserDefaults(suiteName: ScheduleStore.suiteName)
        suite?.set(appStartTimes, forKey: "appStartTimes")
        suite?.set(appEndTimes, forKey: "appEndTimes")
        suite?.set(appEnabled, forKey: "appEnabled")
        suite?.set(appNames, forKey: "appNames")
    }

    func loadTimeWindowsFromUserDefaults() {
        let suite = UserDefaults(suiteName: ScheduleStore.suiteName)
        appStartTimes = suite?.object(forKey: "appStartTimes") as? [String: Int] ?? [:]
        appEndTimes = suite?.object(forKey: "appEndTimes") as? [String: Int] ?? [:]
        appEnabled = suite?.object(forKey: "appEnabled") as? [String: Bool] ?? [:]
        appNames = suite?.object(forKey: "appNames") as? [String: String] ?? [:]
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
}

/// A reusable view for the row that presents the FamilyActivityPicker.
private struct SchedulePickerRow: View {
    let schedule: Schedule
    
    private var selectionCount: Int {
        schedule.selection.wrappedValue.applicationTokens.count
    }

    var body: some View {
        Button {
            schedule.isPickerPresented.wrappedValue = true
        } label: {
            HStack {
                Image(systemName: schedule.icon)
                    .font(.title3)
                    .foregroundStyle(schedule.color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(schedule.name).foregroundStyle(.primary)
                    Text(selectionCount == 0 ? "Select apps" : "\(selectionCount) app\(selectionCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary).font(.caption)
            }
        }
        .familyActivityPicker(isPresented: schedule.isPickerPresented, selection: schedule.selection)
    }
}

/// A data store for saving and loading the three schedule selections.
private enum ScheduleStore {
    // IMPORTANT: Use your actual App Group name from your project settings
    static let suiteName = "group.com.example.YourApp"
    static let morningKey = "morningSelectionV2"
    static let workKey = "workSelectionV2"
    static let eveningKey = "eveningSelectionV2"

    static func save(morning: FamilyActivitySelection, work: FamilyActivitySelection, evening: FamilyActivitySelection) {
        let defaults = UserDefaults(suiteName: suiteName)
        try? defaults?.set(JSONEncoder().encode(morning), forKey: morningKey)
        try? defaults?.set(JSONEncoder().encode(work), forKey: workKey)
        try? defaults?.set(JSONEncoder().encode(evening), forKey: eveningKey)
    }

    static func load() -> (morning: FamilyActivitySelection, work: FamilyActivitySelection, evening: FamilyActivitySelection) {
        let defaults = UserDefaults(suiteName: suiteName)
        let morning = loadSelection(forKey: morningKey, from: defaults)
        let work = loadSelection(forKey: workKey, from: defaults)
        let evening = loadSelection(forKey: eveningKey, from: defaults)
        return (morning, work, evening)
    }

    private static func loadSelection(forKey key: String, from defaults: UserDefaults?) -> FamilyActivitySelection {
        guard let data = defaults?.data(forKey: key),
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return FamilyActivitySelection()
        }
        return selection
    }
}

// MARK: - AppTimeRow (Restored from your original code)
struct AppTimeRow: View {
    let appId: String
    let appName: String
    let appIndex: Int
    let isExpanded: Bool
    let startMinutes: Int
    let endMinutes: Int
    let isEnabled: Bool
    let onToggleExpansion: () -> Void
    let onTimeUpdate: (Int, Int) -> Void
    let onToggleEnabled: () -> Void
     
    @State private var localStartMinutes: Int
    @State private var localEndMinutes: Int

    init(appId: String, appName: String, appIndex: Int, isExpanded: Bool, startMinutes: Int, endMinutes: Int, isEnabled: Bool, onToggleExpansion: @escaping () -> Void, onTimeUpdate: @escaping (Int, Int) -> Void, onToggleEnabled: @escaping () -> Void) {
        self.appId = appId
        self.appName = appName
        self.appIndex = appIndex
        self.isExpanded = isExpanded
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
        self.isEnabled = isEnabled
        self.onToggleExpansion = onToggleExpansion
        self.onTimeUpdate = onTimeUpdate
        self.onToggleEnabled = onToggleEnabled
        self._localStartMinutes = State(initialValue: startMinutes)
        self._localEndMinutes = State(initialValue: endMinutes)
    }
     
    private var startBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: localStartMinutes / 60, minute: localStartMinutes % 60, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                localStartMinutes = Calendar.current.component(.hour, from: date) * 60 + Calendar.current.component(.minute, from: date)
                onTimeUpdate(localStartMinutes, localEndMinutes)
            }
        )
    }
     
    private var endBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: localEndMinutes / 60, minute: localEndMinutes % 60, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                localEndMinutes = Calendar.current.component(.hour, from: date) * 60 + Calendar.current.component(.minute, from: date)
                onTimeUpdate(localStartMinutes, localEndMinutes)
            }
        )
    }
     
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggleExpansion) {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "app")
                                .foregroundStyle(.blue)
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(timeRangeText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: .constant(isEnabled))
                        .onTapGesture {
                            onToggleEnabled()
                        }
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()
                        .padding(.top, 8)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start Time")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            DatePicker(
                                "Start",
                                selection: startBinding,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("End Time")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            DatePicker(
                                "End",
                                selection: endBinding,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }
     
    private var timeRangeText: String {
        let startHour = localStartMinutes / 60
        let startMin = localStartMinutes % 60
        let endHour = localEndMinutes / 60
        let endMin = localEndMinutes % 60
        let status = isEnabled ? "Active" : "Disabled"
        let timeRange = String(format: "%02d:%02d - %02d:%02d", startHour, startMin, endHour, endMin)
        return "\(timeRange) • \(status)"
    }
}

// MARK: - Required Extension for .sheet(item:)
extension String: Identifiable {
    public var id: String { self }
}

