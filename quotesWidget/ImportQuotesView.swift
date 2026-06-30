//
//  ImportQuotesView.swift
//  quotesWidget
//
//  Lets users paste a block of text (e.g. from iPhone Notes) and bulk-import
//  the detected quotes into QuoteStore.
//

import SwiftUI

struct ImportQuotesView: View {
    @EnvironmentObject var store: QuoteStore
    @Environment(\.dismiss) private var dismiss

    @State private var pastedText = ""
    @State private var parsed: [ParsedQuote] = []
    @State private var showPreview = false

    private var selectedCount: Int { parsed.filter(\.selected).count }

    var body: some View {
        NavigationStack {
            if showPreview {
                previewList
                    .navigationTitle("Review Quotes")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Back") { showPreview = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Import \(selectedCount)") { importSelected() }
                                .disabled(selectedCount == 0)
                        }
                    }
            } else {
                pasteArea
                    .navigationTitle("Import Quotes")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { dismiss() }
                        }
                    }
            }
        }
    }

    // MARK: - Paste screen

    private var pasteArea: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Paste a document or notes file containing quotes. Supported formats:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Group {
                    Text("\u{201C}Quote\u{201D} \u{2014} Author").monospaced()
                    Text("\u{201C}Quote\u{201D} - Author").monospaced()
                    Text("\u{201C}Quote\u{201D}  \u{2190} then Author on the next line").monospaced()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 12)

            TextEditor(text: $pastedText)
                .font(.body)
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .frame(maxHeight: .infinity)

            Button(action: parse) {
                Label("Find Quotes", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Preview screen

    private var previewList: some View {
        List {
            if parsed.isEmpty {
                Section {
                    Text("No quotes detected. Try a different format.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    Button {
                        let allOn = parsed.allSatisfy(\.selected)
                        for i in parsed.indices { parsed[i].selected = !allOn }
                    } label: {
                        Text(parsed.allSatisfy(\.selected) ? "Deselect all" : "Select all")
                            .font(.subheadline)
                    }
                }

                Section("Found \(parsed.count) quote\(parsed.count == 1 ? "" : "s")") {
                    ForEach($parsed) { $q in
                        Toggle(isOn: $q.selected) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\u{201C}\(q.text)\u{201D}")
                                    .lineLimit(3)
                                Text("— \(q.author)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func parse() {
        parsed = QuoteParser.parse(pastedText)
        showPreview = true
    }

    private func importSelected() {
        for q in parsed where q.selected {
            store.add(text: q.text, author: q.author)
        }
        dismiss()
    }
}

#Preview {
    ImportQuotesView().environmentObject(QuoteStore())
}
