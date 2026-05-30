//
//  quotesWidgetApp.swift
//  quotesWidget
//
//  Created by Douglas Brown on 5/19/26.
//

import SwiftUI
import UserNotifications

@main
struct quotesWidgetApp: App {
    @StateObject private var store = QuoteStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear {
                    // Top up the notification queue if the user previously enabled
                    // daily reminders. iOS expires fired notifications, so we
                    // need to keep refilling the 60-day window on app launches.
                    if UserDefaults.standard.bool(forKey: QuoteNotifications.enabledKey) {
                        QuoteNotifications.refresh(with: store.quotes)
                    }
                }
        }
    }
}

enum QuoteNotifications {
    static let enabledKey = "dailyReminderEnabled"
    static let identifierPrefix = "quotemark.daily."
    static let hour = 9
    static let daysAhead = 60        // iOS caps pending local notifications at 64

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func refresh(with quotes: [Quote]) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
            guard !quotes.isEmpty else { return }
            schedule(quotes: quotes)
        }
    }

    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(identifierPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private static func schedule(quotes: [Quote]) {
        let calendar = Calendar.current
        let now = Date()
        var nineAM = calendar.dateComponents([.year, .month, .day], from: now)
        nineAM.hour = hour
        nineAM.minute = 0
        guard var firstFire = calendar.date(from: nineAM) else { return }
        if firstFire <= now {
            firstFire = calendar.date(byAdding: .day, value: 1, to: firstFire) ?? firstFire
        }

        let center = UNUserNotificationCenter.current()
        for i in 0..<daysAhead {
            guard let fireDate = calendar.date(byAdding: .day, value: i, to: firstFire),
                  let quote = quotes.quoteForDay(fireDate) else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Quote of the Day"
            content.body = quote.author.isEmpty
                ? "\u{201C}\(quote.text)\u{201D}"
                : "\u{201C}\(quote.text)\u{201D} — \(quote.author)"
            content.sound = .default
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let id = "\(identifierPrefix)\(Int(fireDate.timeIntervalSince1970))"
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }
}
