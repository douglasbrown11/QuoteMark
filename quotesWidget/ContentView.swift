//
//  ContentView.swift
//  quotesWidget
//
//  Created by Douglas Brown on 5/19/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: QuoteStore
    @State private var text = ""
    @State private var author = ""
    @AppStorage(QuoteNotifications.enabledKey) private var reminderEnabled = false

    var body: some View {
        NavigationStack {
            List {
                Section("Daily reminder") {
                    Toggle("9:00 AM notification", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, newValue in
                            Task { await handleReminderToggle(newValue) }
                        }
                }

                Section("New quote") {
                    TextField("Quote", text: $text, axis: .vertical)
                        .lineLimit(1...4)
                    TextField("Author", text: $author)
                    Button("Add") {
                        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        let a = author.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty, !a.isEmpty else { return }
                        store.add(text: t, author: a)
                        text = ""
                        author = ""
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Section("Your quotes (\(store.quotes.count))") {
                    if store.quotes.isEmpty {
                        Text("No quotes yet. Add one above.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.quotes) { q in
                            NavigationLink {
                                EditQuoteView(quote: q)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\u{201C}\(q.text)\u{201D}")
                                    Text("— \(q.author)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .onDelete(perform: store.delete)
                    }
                }
            }
            .navigationTitle("QuoteMark")
            .onChange(of: store.quotes) { _, newQuotes in
                if reminderEnabled {
                    QuoteNotifications.refresh(with: newQuotes)
                }
            }
        }
    }

    private func handleReminderToggle(_ enabled: Bool) async {
        if enabled {
            let granted = await QuoteNotifications.requestAuthorization()
            if granted {
                QuoteNotifications.refresh(with: store.quotes)
            } else {
                reminderEnabled = false
            }
        } else {
            QuoteNotifications.cancelAll()
        }
    }
}

struct EditQuoteView: View {
    @EnvironmentObject var store: QuoteStore
    @Environment(\.dismiss) private var dismiss

    let quote: Quote
    @State private var text: String
    @State private var author: String

    init(quote: Quote) {
        self.quote = quote
        _text = State(initialValue: quote.text)
        _author = State(initialValue: quote.author)
    }

    var body: some View {
        Form {
            Section("Quote") {
                TextField("Quote", text: $text, axis: .vertical)
                    .lineLimit(1...8)
            }
            Section("Author") {
                TextField("Author", text: $author)
            }
        }
        .navigationTitle("Edit Quote")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    let a = author.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !t.isEmpty, !a.isEmpty else { return }
                    var updated = quote
                    updated.text = t
                    updated.author = a
                    store.update(updated)
                    dismiss()
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                          || author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

#Preview {
    ContentView().environmentObject(QuoteStore())
}
