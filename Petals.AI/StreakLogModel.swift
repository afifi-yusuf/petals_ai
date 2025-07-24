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
    
    init(id: UUID = UUID(), date: Date = Date(), lastDate: Date?, lastStreak: Int = 0) {
        self.id = id
        self.date = date
        self.streak = StreakLogModel.calculateStreak(lastDate: lastDate, currentDate: date, currentStreak: lastStreak )
    }
    
    static func calculateStreak(lastDate: Date?, currentDate: Date, currentStreak: Int) -> Int {
        guard let lastDate = lastDate else {
            return 1
        }
        let calendar = Calendar.current
        let startLast = calendar.startOfDay(for: lastDate)
        let startCurrent = calendar.startOfDay(for: currentDate)
        
        let daysBetween = calendar.dateComponents([.day], from: startLast, to: startCurrent).day ?? 0
        
        switch daysBetween {
        case 1:
            return currentStreak + 1
        case 0:
            return currentStreak
        default:
            return 1
        }
    }
    
    
    
    
}
