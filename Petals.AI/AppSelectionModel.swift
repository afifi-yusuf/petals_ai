import Combine
import FamilyControls
import ManagedSettings

final class AppSelectionModel: ObservableObject {
    @Published var selectionToDiscourage = FamilyActivitySelection() {
        didSet { DiscouragedSelectionStore.save(selectionToDiscourage) }
    }
    private let store = ManagedSettingsStore()

    func apply() {
        let tokens = selectionToDiscourage.applicationTokens
        store.shield.applications = tokens.isEmpty ? nil : tokens
        DiscouragedSelectionStore.save(selectionToDiscourage)
    }
}

