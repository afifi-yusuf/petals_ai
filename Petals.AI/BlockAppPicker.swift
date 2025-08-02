import SwiftUI
import FamilyControls
import DeviceActivity

extension DeviceActivityReport.Context {
    static let pieChart = Self("Pie Chart")
}

struct BlockAppPicker: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appModel = AppSelectionModel()
    @State private var isPickerPresented = false
    @State private var showingDeleteConfirmation = false
    @State private var showingHelpSheet = false
    @State private var isSaving = false
    @State private var expandedApps = Set<String>()
    
    private static var thisWeek: DateInterval {
        let calendar = Calendar.current
        let now = Date()
        return calendar.dateInterval(of: .weekOfYear, for: now)!
    }

    @State private var appStartTimes: [String: Int] = [:]
    @State private var appEndTimes: [String: Int] = [:]
    @State private var appEnabled: [String: Bool] = [:]
    @State private var appNames: [String: String] = [:] // For custom names
    @State private var context: DeviceActivityReport.Context = .pieChart
    @State private var filter = DeviceActivityFilter(segment: .daily(during: BlockAppPicker.thisWeek))

    // For nickname prompt
    @State private var newAppIdToName: String? = nil
    @State private var pendingAppName: String = ""

    private var hasSelection: Bool {
        !appModel.selectionToDiscourage.applicationTokens.isEmpty
    }

    private var selectedAppCount: Int {
        appModel.selectionToDiscourage.applicationTokens.count
    }

    private var selectedApps: [String] {
        appModel.selectionToDiscourage.applicationTokens.map { String($0.hashValue) }
    }

    var body: some View {
        GeometryReader{ geometry in
            VStack(alignment: .leading){
                DeviceActivityReport(context, filter: filter)
                    .frame(height: geometry.size.height * 0.6)
            }
            
        }
        NavigationStack {
            Form {
                appSelectionSection
                if hasSelection {
                    selectedAppsSection
                    individualTimeWindowsSection
                    actionSection
                }
                helpSection
            }
            .navigationTitle("App Restrictions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
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
            .sheet(isPresented: $showingHelpSheet) { helpSheet }
            .sheet(item: $newAppIdToName) { appId in
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("Give this app a nickname:")
                            .font(.headline)
                        TextField("App name", text: $pendingAppName)
                            .textFieldStyle(.roundedBorder)
                            .padding()
                        Button("Save") {
                            appNames[appId] = pendingAppName.isEmpty ? "Unnamed App" : pendingAppName
                            saveTimeWindows()
                            // Find next unnamed, if any
                            let currentIds = Set(selectedApps)
                            if let next = currentIds.first(where: { appNames[$0] == nil }) {
                                newAppIdToName = next
                                pendingAppName = ""
                            } else {
                                newAppIdToName = nil
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(pendingAppName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Cancel") {
                                appNames[appId] = "Unnamed App"
                                saveTimeWindows()
                                let currentIds = Set(selectedApps)
                                if let next = currentIds.first(where: { appNames[$0] == nil }) {
                                    newAppIdToName = next
                                    pendingAppName = ""
                                } else {
                                    newAppIdToName = nil
                                }
                            }
                        }
                    }
                }
            }
            .confirmationDialog(
                "Remove All Restrictions",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove All", role: .destructive) {
                    appModel.selectionToDiscourage = FamilyActivitySelection()
                    appStartTimes.removeAll()
                    appEndTimes.removeAll()
                    appEnabled.removeAll()
                    appNames.removeAll()
                    appModel.apply()
                    saveTimeWindows()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove all app restrictions and individual time windows.")
            }
            .onAppear {
                appModel.selectionToDiscourage = DiscouragedSelectionStore.load() ?? FamilyActivitySelection()
                loadTimeWindows()
                syncTimeWindows()
            }
            .onChange(of: isPickerPresented) { _, isPresented in
                if !isPresented {
                    syncTimeWindows()
                    appModel.apply()
                    saveTimeWindows()
                    // Find any new appId needing a name
                    let currentIds = Set(selectedApps)
                    for id in currentIds {
                        if appNames[id] == nil {
                            newAppIdToName = id
                            pendingAppName = ""
                            break
                        }
                    }
                }
            }
        }
    }

    // MARK: - View Components

    private var appSelectionSection: some View {
        Section {
            Button {
                isPickerPresented = true
            } label: {
                HStack {
                    Image(systemName: "app.badge.checkmark")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Select Apps to Restrict")
                            .foregroundStyle(.primary)
                        if hasSelection {
                            Text("\(selectedAppCount) app\(selectedAppCount == 1 ? "" : "s") selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Choose apps with individual time windows")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
            }
            .familyActivityPicker(
                isPresented: $isPickerPresented,
                selection: $appModel.selectionToDiscourage
            )
        } header: {
            Text("App Selection")
        } footer: {
            Text("Each selected app will have its own individual time window.")
        }
    }

    private var selectedAppsSection: some View {
        Section("Selected Apps") {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("\(selectedAppCount) app\(selectedAppCount == 1 ? "" : "s") will be restricted")
                Spacer()
                Button("Change") {
                    isPickerPresented = true
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
        }
    }

    private var individualTimeWindowsSection: some View {
        Section {
            ForEach(Array(selectedApps.enumerated()), id: \.element) { index, appId in
                AppTimeRow(
                    appId: appId,
                    appName: appNames[appId] ?? "Unnamed App",
                    appIndex: index + 1,
                    isExpanded: expandedApps.contains(appId),
                    startMinutes: appStartTimes[appId] ?? (17 * 60),
                    endMinutes: appEndTimes[appId] ?? (20 * 60),
                    isEnabled: appEnabled[appId] ?? true,
                    onToggleExpansion: {
                        if expandedApps.contains(appId) {
                            expandedApps.remove(appId)
                        } else {
                            expandedApps.insert(appId)
                        }
                    },
                    onTimeUpdate: { start, end in
                        appStartTimes[appId] = start
                        appEndTimes[appId] = end
                        saveTimeWindows()
                    },
                    onToggleEnabled: {
                        appEnabled[appId] = !(appEnabled[appId] ?? true)
                        saveTimeWindows()
                    }
                )
            }
            if !selectedApps.isEmpty {
                Button {
                    applyAllTimeWindows()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        Text(isSaving ? "Applying..." : "Apply All Time Windows")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
        } header: {
            Text("Individual Time Windows")
        } footer: {
            Text("Each app will be accessible during its specific time window. Outside these hours, the app will be restricted.")
        }
    }

    private var actionSection: some View {
        Section {
            Button {
                showingDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                    Text("Remove All Restrictions")
                        .foregroundStyle(.red)
                }
            }
        } footer: {
            Text("This will clear all selected apps and remove any individual time restrictions.")
        }
    }

    private var helpSection: some View {
        Section {
            Button {
                showingHelpSheet = true
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.blue)
                    Text("How Individual App Restrictions Work")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
            }
        }
    }

    private var helpSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text("Individual App Restrictions")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Custom time windows for each app")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        helpItem(
                            icon: "app.badge.checkmark",
                            title: "Select Apps",
                            description: "Choose which apps you want to restrict with individual schedules."
                        )
                        helpItem(
                            icon: "clock.arrow.2.circlepath",
                            title: "Individual Time Windows",
                            description: "Set unique allowed time windows for each selected app."
                        )
                        helpItem(
                            icon: "togglepower",
                            title: "Enable/Disable Apps",
                            description: "Toggle restrictions on or off for individual apps without removing them."
                        )
                        helpItem(
                            icon: "shield",
                            title: "Automatic Blocking",
                            description: "Each app is automatically restricted outside its specific time window."
                        )
                        helpItem(
                            icon: "bell.slash",
                            title: "Flexible Focus",
                            description: "Different apps can have different allowed times based on your needs."
                        )
                    }
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingHelpSheet = false
                    }
                }
            }
        }
    }

    private func helpItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    // MARK: - Helper Methods

    private func syncTimeWindows() {
        let selectedTokens = appModel.selectionToDiscourage.applicationTokens
        let selectedIds = Set(selectedTokens.map { String($0.hashValue) })
        appStartTimes = appStartTimes.filter { selectedIds.contains($0.key) }
        appEndTimes = appEndTimes.filter { selectedIds.contains($0.key) }
        appEnabled = appEnabled.filter { selectedIds.contains($0.key) }
        appNames = appNames.filter { selectedIds.contains($0.key) }
        for id in selectedIds {
            if appStartTimes[id] == nil { appStartTimes[id] = 17 * 60 }
            if appEndTimes[id] == nil { appEndTimes[id] = 20 * 60 }
            if appEnabled[id] == nil { appEnabled[id] = true }
        }
    }

    private func applyAllTimeWindows() {
        isSaving = true
        for appId in selectedApps {
            guard appEnabled[appId] == true else { continue }
            let startMin = appStartTimes[appId] ?? (17 * 60)
            let endMin = appEndTimes[appId] ?? (20 * 60)
            let start = DateComponents(hour: startMin / 60, minute: startMin % 60)
            let end = DateComponents(hour: endMin / 60, minute: endMin % 60)
            Task {
                ScreenTimeManager.shared.startDailyWindow(start: start, end: end)
            }
        }
        appModel.apply()
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run { isSaving = false }
        }
    }

    private func saveTimeWindows() {
        let suite = UserDefaults(suiteName: DiscouragedSelectionStore.suite)
        suite?.set(appStartTimes, forKey: "appStartTimes")
        suite?.set(appEndTimes, forKey: "appEndTimes")
        suite?.set(appEnabled, forKey: "appEnabled")
        suite?.set(appNames, forKey: "appNames")
    }

    private func loadTimeWindows() {
        let suite = UserDefaults(suiteName: DiscouragedSelectionStore.suite)
        if let startDict = suite?.object(forKey: "appStartTimes") as? [String: Int] {
            appStartTimes = startDict
        }
        if let endDict = suite?.object(forKey: "appEndTimes") as? [String: Int] {
            appEndTimes = endDict
        }
        if let enabledDict = suite?.object(forKey: "appEnabled") as? [String: Bool] {
            appEnabled = enabledDict
        }
        if let namesDict = suite?.object(forKey: "appNames") as? [String: String] {
            appNames = namesDict
        }
    }
}

// MARK: - Individual App Row Component

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

extension String: Identifiable {
    public var id: String { self }
}
