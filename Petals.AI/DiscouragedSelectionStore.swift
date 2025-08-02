//
//  DiscouragedSelectionStore.swift
//  Petals.AI
//
//  Created by Rishi Hundia on 01/08/2025.
//
import Foundation
import FamilyControls
import os


// MARK: - Your Existing Selection Store (Updated with Error Handling)
enum DiscouragedSelectionStore {
    static let suite = "group.com.petals.ai"
    static let key = "discouragedSelection"
    
    private static let logger = Logger(subsystem: "com.petals.ai.screentime", category: "SelectionStore")
    
    static func save(_ selection: FamilyActivitySelection) {
        do {
            let data = try JSONEncoder().encode(selection)
            guard let defaults = UserDefaults(suiteName: suite) else {
                logger.error("Failed to access App Group")
                return
            }
            defaults.set(data, forKey: key)
            logger.info("Successfully saved selection to App Group")
        } catch {
            logger.error("Failed to encode selection: \(error.localizedDescription)")
        }
    }
    
    static func load() -> FamilyActivitySelection {
        guard let defaults = UserDefaults(suiteName: suite) else {
            logger.error("Failed to access App Group")
            return FamilyActivitySelection()
        }
        
        guard let data = defaults.data(forKey: key) else {
            logger.info("No saved selection found, returning empty selection")
            return FamilyActivitySelection()
        }
        
        do {
            let selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            logger.info("Successfully loaded selection from App Group")
            return selection
        } catch {
            logger.error("Failed to decode selection: \(error.localizedDescription)")
            return FamilyActivitySelection()
        }
    }
    
    static func clear() {
        guard let defaults = UserDefaults(suiteName: suite) else {
            logger.error("Failed to access App Group for clearing")
            return
        }
        
        defaults.removeObject(forKey: key)
        logger.info("Cleared saved selection from App Group")
    }
}
