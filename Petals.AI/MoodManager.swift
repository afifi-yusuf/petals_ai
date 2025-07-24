import Foundation
import SwiftUI
import SwiftData

@MainActor
class MoodManager: ObservableObject {
    static let shared = MoodManager()
    
    @Published var todaysMood: MoodType?
    @Published var showingMoodPrompt = false
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StreakLogModel.date, order: .reverse) var logs: [StreakLogModel]
    
    private let userDefaults = UserDefaults.standard
    private let moodKey = "todaysMood"
    private let moodDateKey = "moodDate"
    
    private init() {
        checkAndSetMoodPrompt()
    }
    
    func checkAndSetMoodPrompt() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastMoodDate = userDefaults.object(forKey: moodDateKey) as? Date ?? Date.distantPast
        let lastMoodDateStart = Calendar.current.startOfDay(for: lastMoodDate)
        
        // If it's a new day and no mood has been set today
        if today > lastMoodDateStart {
            showingMoodPrompt = true
            todaysMood = nil
        } else {
            // Load today's mood if it exists
            if let moodRawValue = userDefaults.string(forKey: moodKey),
               let mood = MoodType(rawValue: moodRawValue) {
                todaysMood = mood
            }
        }
    }
    
    func setTodaysMood(_ mood: MoodType) {
        todaysMood = mood
        userDefaults.set(mood.rawValue, forKey: moodKey)
        userDefaults.set(Date(), forKey: moodDateKey)
        showingMoodPrompt = false
        
        if let lastDate = logs.first?.date,
           Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
            print("Already logged today")
            return
        }
        
        let lastDate = logs.first?.date
        let curStreak = logs.first?.streak
        let entry = StreakLogModel(lastDate: lastDate, lastStreak: curStreak ?? 0)
        modelContext.insert(entry)
        do{
            try modelContext.save()
            print("SAVED MOOD 😄")
            
        } catch {
            print("Unable to save mood: \(error)")
        }
        
    }
    
    func getTodaysMood() -> MoodType? {
        return todaysMood
    }
    
    func hasMoodForToday() -> Bool {
        return todaysMood != nil
    }
} 

