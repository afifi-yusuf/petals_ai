//
//  StreakLogModel.swift
//  Petals.AI
//
//  Created by Rishi Hundia on 24/07/2025.
//

import Foundation
import SwiftData

@Model
class StreakLogModel {
    @Attribute(.unique) var id: UUID
    @Attribute var date: Date
    @Attribute var streak: Int
    
    init(id: UUID = UUID(), date: Date = Date(), lastDate: Date?, lastStreak: Int = 1) {
        self.id = id
        self.date = date
        let lastDate = lastDate ?? Date()
        self.streak = StreakLogModel.calculateStreak(lastDate: lastDate, currentDate: date, currentStreak: lastStreak )
    }
    
    static func calculateStreak(lastDate: Date?, currentDate: Date, currentStreak: Int) -> Int {
        print("Inside Streak Calculator 😄")
        print(lastDate ?? "nil", currentDate, currentStreak)
        guard let lastDate = lastDate else {
            return 1
        }
        let calendar = Calendar.current
        let startLast = calendar.startOfDay(for: lastDate)
        let startCurrent = calendar.startOfDay(for: currentDate)
        
        let daysBetween = calendar.dateComponents([.day], from: startLast, to: startCurrent).day ?? 0
        
        switch daysBetween {
        case 1:
            print("Returning case 1 -> (\(currentStreak + 1))")
            return currentStreak + 1
        case 0:
            print("Returning case 0: (\(currentStreak))")
            return currentStreak
        default:
            print("Returning default: 1")
            return 1
        }
    }
    
    
    
    
}
