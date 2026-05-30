//
//  QuotesWidgetExtension.swift
//  QuotesWidgetExtension
//
//  Created by Douglas Brown on 5/19/26.
//

import WidgetKit
import SwiftUI

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote
}

struct QuoteProvider: TimelineProvider {
    private let placeholder = Quote(
        text: "Add quotes in the app to see them here.",
        author: ""
    )

    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        let q = QuoteStore.loadQuotes().randomElement() ?? placeholder
        completion(QuoteEntry(date: Date(), quote: q))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let quotes = QuoteStore.loadQuotes()
        let now = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current

        // Today's 8 AM in the user's local time zone.
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 8
        components.minute = 0
        components.second = 0
        var anchor = calendar.date(from: components) ?? now

        // If today's 8 AM hasn't happened yet, the current quote is the one set
        // at yesterday's 8 AM; the next rotation is today at 8.
        if anchor > now {
            anchor = calendar.date(byAdding: .day, value: -1, to: anchor) ?? anchor
        }

        var entries: [QuoteEntry] = []
        for i in 0..<60 {                   // two months pre-rolled
            let date = calendar.date(byAdding: .day, value: i, to: anchor) ?? anchor
            let q = quotes.quoteForDay(date) ?? placeholder
            entries.append(QuoteEntry(date: date, quote: q))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct QuotesWidgetExtensionEntryView: View {
    var entry: QuoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\u{201C}\(entry.quote.text)\u{201D}")
                .font(.callout)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.leading)
            if !entry.quote.author.isEmpty {
                Text("— \(entry.quote.author)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct QuotesWidgetExtension: Widget {
    let kind: String = "QuotesWidgetExtension"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuotesWidgetExtensionEntryView(entry: entry)
        }
        .configurationDisplayName("QuoteMark")
        .description("Cycles through your authored quotes.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
