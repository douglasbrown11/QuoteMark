//
//  QuoteStore.swift
//  quotesWidget
//
//  Shared between the app and the widget extension via an App Group.
//

import Foundation
import Combine
import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

enum QuoteStoreConfig {
    static let appGroupID = "group.Dream-AI.quotesWidget"
    static let key = "quotes"
}

final class QuoteStore: ObservableObject {
    @Published var quotes: [Quote] = [] {
        didSet { save() }
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: QuoteStoreConfig.appGroupID) ?? .standard
    }

    init() { load() }

    func add(text: String, author: String) {
        quotes.append(Quote(text: text, author: author))
    }

    func delete(at offsets: IndexSet) {
        quotes.remove(atOffsets: offsets)
    }

    func update(_ quote: Quote) {
        guard let i = quotes.firstIndex(where: { $0.id == quote.id }) else { return }
        quotes[i] = quote
    }

    private func load() {
        guard let data = defaults.data(forKey: QuoteStoreConfig.key),
              let decoded = try? JSONDecoder().decode([Quote].self, from: data)
        else { return }
        quotes = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(quotes) {
            defaults.set(data, forKey: QuoteStoreConfig.key)
            #if canImport(WidgetKit)
            WidgetCenter.shared.reloadAllTimelines()
            #endif
        }
    }

    static func loadQuotes() -> [Quote] {
        guard let defaults = UserDefaults(suiteName: QuoteStoreConfig.appGroupID),
              let data = defaults.data(forKey: QuoteStoreConfig.key),
              let decoded = try? JSONDecoder().decode([Quote].self, from: data)
        else { return [] }
        return decoded
    }
}
