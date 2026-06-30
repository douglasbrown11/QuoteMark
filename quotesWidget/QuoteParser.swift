//
//  QuoteParser.swift
//  quotesWidget
//
//  Parses pasted text (e.g. from Notes) into Quote objects.
//  Supported formats:
//    "Quote text" — Author Name          (em/en dash)
//    "Quote text" - Author Name          (hyphen, requires quote marks)
//    "Quote text" ~ Author Name
//    Quote text — Author Name            (no surrounding quotes, em/en dash only)
//    "Quote text"                        (line 1)
//    — Author Name                       (line 2, with dash prefix)
//    "Quote text"                        (line 1)
//    Author Name                         (line 2, plain — only when quote marks present)
//    Bullet / numbered list prefixes (•, -, 1.) are stripped automatically.
//

import Foundation

struct ParsedQuote: Identifiable {
    let id = UUID()
    var text: String
    var author: String
    var selected: Bool = true
}

enum QuoteParser {

    // MARK: - Public API

    static func parse(_ input: String) -> [ParsedQuote] {
        let lines = input
            .components(separatedBy: .newlines)
            .map { stripListPrefix($0.trimmingCharacters(in: .whitespaces)) }

        var results: [ParsedQuote] = []
        var skip = Set<Int>()

        var i = 0
        while i < lines.count {
            let line = lines[i]

            if line.isEmpty { i += 1; continue }

            // 1. Try single-line patterns first
            if let q = parseSingleLine(line) {
                results.append(q)
                skip.insert(i)
                i += 1
                continue
            }

            // 2. Try two-line pattern: current line is the quote, next non-empty is the author
            let j = nextNonEmpty(after: i, in: lines)
            if let j, !skip.contains(j) {
                if let q = parseTwoLines(lines[i], lines[j]) {
                    results.append(q)
                    skip.insert(i)
                    skip.insert(j)
                    i = j + 1
                    continue
                }
            }

            i += 1
        }

        return deduplicated(results)
    }

    // MARK: - Single-line patterns

    private static func parseSingleLine(_ line: String) -> ParsedQuote? {
        // Pattern A: "Quote" [—–] Author  or  "Quote" - Author  or  "Quote" ~ Author
        // Requires surrounding curly or straight quotes
        let withQuotes: [(String)] = [
            // em/en dash or spaced hyphen or tilde, with surrounding quote chars
            #"^[\u{201C}"'](.+?)[\u{201D}"']\s*(?:—|–|\s*[-~]\s*)\s*(.+)$"#,
        ]
        for pattern in withQuotes {
            if let (text, author) = capture2(pattern, in: line) {
                return makeQuote(text, author)
            }
        }

        // Pattern B: Quote — Author  (no surrounding quotes, only em/en dash to be safe)
        let noQuotes = #"^(.+?)\s+(?:—|–)\s+(.+)$"#
        if let (text, author) = capture2(noQuotes, in: line) {
            // Sanity check: author shouldn't look like a long sentence
            if author.count < 80 && !author.contains("—") && !author.contains("–") {
                return makeQuote(text, author)
            }
        }

        return nil
    }

    // MARK: - Two-line patterns

    private static func parseTwoLines(_ quoteLine: String, _ authorLine: String) -> ParsedQuote? {
        let quoteText = strippedQuoteMarks(from: quoteLine)
        let hasQuoteMarks = quoteText != quoteLine   // marks were present

        // Author line starting with — or - or ~
        let dashPattern = #"^(?:—|–|[-~])\s*(.+)$"#
        if let (author, _) = capture1(dashPattern, in: authorLine) {
            if !quoteText.isEmpty {
                return makeQuote(quoteText, author)
            }
        }

        // Author line is plain text — only accept if the quote line had quote marks
        // and the "author" looks short and name-like (no sentence punctuation)
        if hasQuoteMarks {
            let looksLikeName = authorLine.count < 60
                && !authorLine.contains("\"")
                && !authorLine.hasPrefix("\u{201C}")
                && !authorLine.contains(".")   // avoid treating sentences as names
                && authorLine.split(separator: " ").count <= 6
            if looksLikeName, !quoteText.isEmpty {
                return makeQuote(quoteText, authorLine)
            }
        }

        return nil
    }

    // MARK: - Helpers

    private static func makeQuote(_ text: String, _ author: String) -> ParsedQuote? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = author.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !a.isEmpty else { return nil }
        return ParsedQuote(text: t, author: a)
    }

    /// Strips surrounding curly/straight single or double quote characters.
    private static func strippedQuoteMarks(from s: String) -> String {
        let quoteChars = CharacterSet(charactersIn: "\"\u{201C}\u{201D}\u{2018}\u{2019}'")
        let stripped = s.trimmingCharacters(in: quoteChars).trimmingCharacters(in: .whitespaces)
        // Return stripped only if the original actually started with a quote char
        let first = s.unicodeScalars.first.map { quoteChars.contains($0) } ?? false
        return first ? stripped : s
    }

    /// Strips common list prefixes: •, *, -, 1., 1)
    private static func stripListPrefix(_ s: String) -> String {
        // Numbered: "12. " or "12) "
        if let r = s.range(of: #"^\d+[.)]\s+"#, options: .regularExpression) {
            return String(s[r.upperBound...])
        }
        // Bullet: "• ", "* ", "- " (only if the rest of the line isn't a separator)
        if let r = s.range(of: #"^[•\*]\s+"#, options: .regularExpression) {
            return String(s[r.upperBound...])
        }
        return s
    }

    private static func nextNonEmpty(after i: Int, in lines: [String]) -> Int? {
        var j = i + 1
        while j < lines.count {
            if !lines[j].isEmpty { return j }
            j += 1
        }
        return nil
    }

    private static func deduplicated(_ quotes: [ParsedQuote]) -> [ParsedQuote] {
        var seen = Set<String>()
        return quotes.filter { q in
            let key = q.text.lowercased() + "|" + q.author.lowercased()
            return seen.insert(key).inserted
        }
    }

    // MARK: - Regex helpers

    /// Returns (group1, group2) for the first match.
    private static func capture2(_ pattern: String, in string: String) -> (String, String)? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = string as NSString
        guard let m = regex.firstMatch(in: string, range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges >= 3
        else { return nil }
        let r1 = m.range(at: 1), r2 = m.range(at: 2)
        guard r1.location != NSNotFound, r2.location != NSNotFound else { return nil }
        return (ns.substring(with: r1), ns.substring(with: r2))
    }

    /// Returns (group1, _) for the first match.
    private static func capture1(_ pattern: String, in string: String) -> (String, Void)? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = string as NSString
        guard let m = regex.firstMatch(in: string, range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges >= 2
        else { return nil }
        let r1 = m.range(at: 1)
        guard r1.location != NSNotFound else { return nil }
        return (ns.substring(with: r1), ())
    }
}
