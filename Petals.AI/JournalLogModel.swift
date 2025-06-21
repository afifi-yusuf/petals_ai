//
//  JournalLogModel.swift
//  Petals.AI
//
//  Created by Rishi Hundia on 21/06/2025.
//
import Foundation
import SwiftData
@Model
class JournalLogModel {
    @Attribute(.unique) var id: UUID
    @Attribute var date: Date
    @Attribute private(set) var text: String
    
    init(text: String) {
            self.id = UUID()
            self.date = Date()
            self.text = JournalLogModel.trimmedText(text)
        }
    static func trimmedText(_ text: String) -> String {
        let words = text.split(separator: " ")
        if words.count < 250 && words.count > 5 {
            return text
        }
        else{
            let trimmedWords = words.prefix(250)
            return trimmedWords.joined(separator: " ")
        }
    }
}
