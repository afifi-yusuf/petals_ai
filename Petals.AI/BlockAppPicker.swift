import SwiftUI
import FamilyControls

struct BlockAppPicker: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Objects
    @StateObject private var appModel = AppSelectionModel()
    
    // MARK: - AppStorage
    @AppStorage("windowStartMin", store: UserDefaults(suiteName: DiscouragedSelectionStore.suite)) private var windowStartMin = 17 * 60
    @AppStorage("windowEndMin", store: UserDefaults(suiteName: DiscouragedSelectionStore.suite)) private var windowEndMin = 20 * 60
    
    // MARK: - State
    @State private var isPickerPresented = false
    @State private var showingDeleteConfirmation = false
    @State private var showingHelpSheet = false
    @State private var isSaving = false
    
    // MARK: - Computed Properties
    private var hasSelection: Bool {
        !appModel.selectionToDiscourage.applicationTokens.isEmpty
    }
    
    private var selectedAppCount: Int {
        appModel.selectionToDiscourage.applicationTokens.count
    }
    
    private var startBinding: Binding<Date> {
        Binding(
            get: { Self.date(fromMinutes: windowStartMin) },
            set: { windowStartMin = Self.minutes(from: $0) }
        )
    }
    
    private var endBinding: Binding<Date> {
        Binding(
            get: { Self.date(fromMinutes: windowEndMin) },
            set: { windowEndMin = Self.minutes(from: $0) }
        )
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                appSelectionSection
                
                if hasSelection {
                    selectedAppsSection
                    timeWindowSection
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
            .sheet(isPresented: $showingHelpSheet) {
                helpSheet
            }
            .confirmationDialog(
                "Remove All Restrictions",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Remove All", role: .destructive) {
                    appModel.selectionToDiscourage = FamilyActivitySelection()
                    appModel.apply()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will remove all app restrictions and time windows.")
            }
            .onAppear {
                appModel.selectionToDiscourage = DiscouragedSelectionStore.load() ?? FamilyActivitySelection()
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
                            Text("Choose apps to discourage during focus time")
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
            .onChange(of: isPickerPresented) { _, isPresented in
                if !isPresented {
                    appModel.apply()
                }
            }
        } header: {
            Text("App Selection")
        } footer: {
            Text("Selected apps will be restricted during your configured time window.")
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
    
    private var timeWindowSection: some View {
        Section {
            VStack(spacing: 16) {
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
                
                Button {
                    isSaving = true
                    let start = DateComponents(hour: windowStartMin / 60, minute: windowStartMin % 60)
                    let end   = DateComponents(hour: windowEndMin / 60,   minute: windowEndMin % 60)
                    // Do this off the main thread to keep UI snappy
                    Task {
                        ScreenTimeManager.shared.startDailyWindow(start: start, end: end)
                        isSaving = false
                    }
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        
                        Text(isSaving ? "Applying..." : "Apply Time Window")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
        } header: {
            Text("Allowed Time Window")
        } footer: {
            Text("Apps will be accessible during this daily time window. Outside these hours, selected apps will be restricted.")
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
            Text("This will clear all selected apps and remove any time restrictions.")
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
                    
                    Text("How App Restrictions Work")
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
                        Image(systemName: "shield.checkerboard")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("App Restrictions")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Focus on what matters most")
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        helpItem(
                            icon: "app.badge.checkmark",
                            title: "Select Apps",
                            description: "Choose which apps you want to restrict during focus time."
                        )
                        
                        helpItem(
                            icon: "clock",
                            title: "Set Time Window",
                            description: "Define when the selected apps will be accessible each day."
                        )
                        
                        helpItem(
                            icon: "shield",
                            title: "Automatic Blocking",
                            description: "Apps are automatically restricted outside your allowed time window."
                        )
                        
                        helpItem(
                            icon: "bell.slash",
                            title: "Reduced Distractions",
                            description: "Stay focused by limiting access to distracting applications."
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
    
    // Helpers
    private static func date(fromMinutes m: Int) -> Date {
        Calendar.current.date(bySettingHour: m / 60, minute: m % 60, second: 0, of: Date()) ?? Date()
    }
    private static func minutes(from date: Date) -> Int {
        Calendar.current.component(.hour, from: date) * 60 +
        Calendar.current.component(.minute, from: date)
    }
}
