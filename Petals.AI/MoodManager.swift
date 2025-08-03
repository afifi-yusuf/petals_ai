import Foundation
import SwiftUI
import SwiftData

@MainActor
class MoodManager: ObservableObject {
    static let shared = MoodManager()
    
    @Published var todaysMood: MoodType?
    @Published var showingMoodPrompt = false
    @Published var currentStreak:Int = 0
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
    
    func setTodaysMood(_ mood: MoodType, in context: ModelContext) {
        todaysMood = mood
        userDefaults.set(mood.rawValue, forKey: moodKey)
        userDefaults.set(Date(), forKey: moodDateKey)
        showingMoodPrompt = false
        

        
        do{
            let logs = try context.fetch(FetchDescriptor<StreakLogModel>(sortBy: [.init(\.date, order: .reverse)]))
            let lastDate = logs.first?.date
            let curStreak = logs.first?.streak ?? 0
            
            let entry = StreakLogModel(lastDate: lastDate, lastStreak: curStreak)
            context.insert(entry)
            try context.save()
            print("SAVED MOOD 😄")
            currentStreak = entry.streak
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

