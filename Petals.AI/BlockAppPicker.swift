import SwiftUI
import FamilyControls

struct BlockAppPicker: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var model = AppSelectionModel()

    @AppStorage("windowStartMin") private var windowStartMin = 17 * 60
    @AppStorage("windowEndMin")   private var windowEndMin   = 20 * 60

    @State private var isPresented = false
    @State private var isSaving = false

    private var hasSelection: Bool { !model.selectionToDiscourage.applicationTokens.isEmpty }

    // Writable bindings bridging minutes <-> Date
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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Select Apps to Discourage") { isPresented = true }
                        .familyActivityPicker(isPresented: $isPresented,
                                              selection: $model.selectionToDiscourage)
                    // If you want immediate blocking, uncomment:
                    // .onChange(of: isPresented) { _, showing in if !showing { model.apply() } }
                }

                if hasSelection {
                    Section("Allowed window (daily)") {
                        DatePicker("Start", selection: startBinding, displayedComponents: .hourAndMinute)
                        DatePicker("End",   selection: endBinding,   displayedComponents: .hourAndMinute)

                        Button(isSaving ? "Saving…" : "Save window") {
                            isSaving = true
                            let start = DateComponents(hour: windowStartMin / 60, minute: windowStartMin % 60)
                            let end   = DateComponents(hour: windowEndMin / 60,   minute: windowEndMin % 60)
                            // Do this off the main thread to keep UI snappy
                            Task {
                                ScreenTimeManager.shared.startDailyWindow(start: start, end: end)
                                isSaving = false
                            }
                        }
                        .disabled(isSaving)
                    }
                }
            }
            .navigationTitle("Discourage Apps")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        HStack { Image(systemName: "chevron.left"); Text("Back") }
                    }
                }
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
