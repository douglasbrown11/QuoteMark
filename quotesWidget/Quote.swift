//
//  Quote.swift
//  quotesWidget
//

import Foundation

struct Quote: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var author: String
}

extension Array where Element == Quote {
    func quoteForDay(_ date: Date) -> Element? {
        guard !isEmpty else { return nil }
        let daysSince1970 = UInt64(Int(date.timeIntervalSince1970 / 86400))
        var state = daysSince1970 &* 6364136223846793005 &+ 1442695040888963407
        let index = Int(state % UInt64(count))
        return self[index]
    }
}
