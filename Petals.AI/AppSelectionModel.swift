import Observation
import FamilyControls
import ManagedSettings
import Combine

final class AppSelectionModel: ObservableObject {
    @Published var selectionToDiscourage = FamilyActivitySelection()
    private let store = ManagedSettingsStore()
    func apply() { store.shield.applications = selectionToDiscourage.applicationTokens }
}
