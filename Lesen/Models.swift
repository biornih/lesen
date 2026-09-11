//  Models.swift
//  Lesen — graded German reading.
//
//  Content ships as books.json: four volumes, 50 chapters, ~2,000 aligned
//  sentence pairs, plus a glossary for tap-a-word lookups.

import Foundation
import SwiftUI
import Combine

// MARK: - Content

struct Library: Decodable {
    let series: String
    let books: [Book]
    let glossary: [String: String]
}

struct Book: Decodable, Identifiable, Hashable {
    let id: String
    let title: String
    let level: String
    let emoji: String
    let blurb: String
    let chapters: [Chapter]

    var sentenceCount: Int { chapters.reduce(0) { $0 + $1.sentences.count } }

    static func == (a: Book, b: Book) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

struct Chapter: Decodable, Identifiable, Hashable {
    let number: Int
    let title: String
    let sentences: [Sentence]

    var id: Int { number }
}

struct Sentence: Decodable, Hashable {
    let de: String
    let en: String
}

// MARK: - Tokens

enum TokenKind { case word, sentenceEnd }

struct Token: Identifiable {
    let id: Int
    let text: String
    let kind: TokenKind
    let sentenceIndex: Int
    let paragraphBreak: Bool   // render a gap after this token
}

// MARK: - Store

@MainActor
final class ContentStore: ObservableObject {

    @Published private(set) var books: [Book] = []
    private var glossary: [String: String] = [:]

    // reading progress: book id -> highest chapter number opened
    @Published var progress: [String: Int] = [:] {
        didSet { save() }
    }
    @Published var lastRead: (bookID: String, chapter: Int)? {
        didSet {
            guard let l = lastRead else { return }
            UserDefaults.standard.set(l.bookID, forKey: "lastBook.\(targetLanguage)")
            UserDefaults.standard.set(l.chapter, forKey: "lastChapter.\(targetLanguage)")
        }
    }

    /// The reader's own language — used for explanatory text.
    @Published var motherTongue: String = Languages.deviceDefault.code {
        didSet { UserDefaults.standard.set(motherTongue, forKey: "motherTongue") }
    }

    /// The language being learned. Progress is kept separately per language.
    @Published var targetLanguage: String = "de" {
        didSet {
            UserDefaults.standard.set(targetLanguage, forKey: "targetLanguage")
            restoreProgressForCurrentLanguage()
        }
    }

    /// Navigation labels in the target language rather than the reader's own.
    @Published var immersionMode: Bool = false {
        didSet { UserDefaults.standard.set(immersionMode, forKey: "immersionMode") }
    }

    /// The reader's current CEFR level. Sets which series are unlocked.
    @Published var level: Level = .a2 {
        didSet { UserDefaults.standard.set(level.rawValue, forKey: levelKey) }
    }

    /// Whether the first-launch setup has been completed.
    @Published var hasOnboarded: Bool = false {
        didSet { UserDefaults.standard.set(hasOnboarded, forKey: "hasOnboarded") }
    }

    // Keys are namespaced by target language so each language keeps its own
    // progress and level.
    private var levelKey: String { "level.\(targetLanguage)" }
    private var progressKey: String { "progress.\(targetLanguage)" }

    private func restoreProgressForCurrentLanguage() {
        progress = (UserDefaults.standard.dictionary(forKey: progressKey) as? [String: Int]) ?? [:]
        if UserDefaults.standard.object(forKey: levelKey) != nil {
            level = Level(rawValue: UserDefaults.standard.integer(forKey: levelKey)) ?? .a2
        }
    }

    init() {
        load()
        restore()
    }

    // MARK: Unlocking

    /// A series is open if the reader has reached its starting level.
    /// Series below their level stay available but are marked optional —
    /// nobody is forced back through the beginner ladder.
    func unlockState(for series: Series) -> UnlockState {
        if isComplete(series) { return .done }
        if level.rawValue < series.startLevel.rawValue { return .locked }
        if level.rawValue > series.endLevel.rawValue { return .easier }
        return .current
    }

    func isComplete(_ series: Series) -> Bool {
        guard !series.bookIDs.isEmpty else { return false }
        return series.bookIDs.allSatisfy { id in
            guard let b = book(id: id) else { return false }
            return chaptersRead(in: b) >= b.chapters.count
        }
    }

    /// Called after a chapter is read: finishing a series raises the reader's level.
    private func promoteIfSeriesFinished() {
        for genre in Catalog.genres {
            for series in genre.series where isComplete(series) {
                if level.rawValue < series.endLevel.rawValue {
                    level = series.endLevel
                }
            }
        }
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "books", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let lib = try? JSONDecoder().decode(Library.self, from: data)
        else {
            assertionFailure("books.json missing from bundle — add it to Target ▸ Build Phases ▸ Copy Bundle Resources")
            return
        }
        books = lib.books
        glossary = lib.glossary
    }

    private func restore() {
        motherTongue   = UserDefaults.standard.string(forKey: "motherTongue") ?? Languages.deviceDefault.code
        targetLanguage = UserDefaults.standard.string(forKey: "targetLanguage") ?? "de"
        immersionMode  = UserDefaults.standard.bool(forKey: "immersionMode")

        if let raw = UserDefaults.standard.dictionary(forKey: progressKey) as? [String: Int] {
            progress = raw
        }
        if let b = UserDefaults.standard.string(forKey: "lastBook.\(targetLanguage)") {
            lastRead = (b, UserDefaults.standard.integer(forKey: "lastChapter.\(targetLanguage)"))
        }
        hasOnboarded = UserDefaults.standard.bool(forKey: "hasOnboarded")
        if UserDefaults.standard.object(forKey: levelKey) != nil {
            level = Level(rawValue: UserDefaults.standard.integer(forKey: levelKey)) ?? .a2
        }
    }

    /// UI text: the reader's own language, or the target language in
    /// immersion mode. Book content is never touched by this.
    func s(_ key: String) -> String { L.t(key, uiLang) }

    /// Which language the interface speaks right now.
    var uiLang: String { immersionMode ? targetLanguage : motherTongue }

    private func save() {
        UserDefaults.standard.set(progress, forKey: progressKey)
    }

    // MARK: Lookup

    /// Strip punctuation and case for glossary matching.
    func normalize(_ raw: String) -> String {
        raw.lowercased().trimmingCharacters(
            in: CharacterSet(charactersIn: ".,!?;:„“\"'»«()—–…*")
        )
    }

    /// Translation for a tapped word, or nil if it isn't in the glossary.
    func gloss(for raw: String) -> String? {
        let w = normalize(raw)
        if let hit = glossary[w] { return hit }
        // try without a trailing inflection (e.g. "warmen" -> "warme" -> "warm")
        if w.count > 4 {
            for cut in [1, 2] where w.count - cut >= 3 {
                let stem = String(w.dropLast(cut))
                if let hit = glossary[stem] { return hit }
            }
        }
        return nil
    }

    // MARK: Progress

    func book(id: String) -> Book? { books.first { $0.id == id } }

    func markRead(book: Book, chapter: Int) {
        progress[book.id] = max(progress[book.id] ?? 0, chapter)
        lastRead = (book.id, chapter)
        promoteIfSeriesFinished()
    }

    func chaptersRead(in book: Book) -> Int { progress[book.id] ?? 0 }

    func fraction(of book: Book) -> Double {
        guard !book.chapters.isEmpty else { return 0 }
        return min(1, Double(chaptersRead(in: book)) / Double(book.chapters.count))
    }

    // MARK: Tokenizing

    private static let terminators: Set<Character> = [".", "!", "?", "…"]

    /// Flatten a chapter into a tappable token stream.
    func tokens(for chapter: Chapter) -> [Token] {
        var out: [Token] = []
        var id = 0
        for (i, s) in chapter.sentences.enumerated() {
            let words = s.de.split(separator: " ").map(String.init)
            for (j, w) in words.enumerated() {
                let isLast = j == words.count - 1
                // split a trailing terminator into its own tappable token
                if isLast, let last = w.last, Self.terminators.contains(last) {
                    var core = w
                    var tail = ""
                    while let c = core.last, Self.terminators.contains(c) || c == "\"" || c == "“" {
                        tail.insert(c, at: tail.startIndex)
                        core.removeLast()
                    }
                    if !core.isEmpty {
                        out.append(Token(id: id, text: core, kind: .word,
                                         sentenceIndex: i, paragraphBreak: false)); id += 1
                    }
                    out.append(Token(id: id, text: tail, kind: .sentenceEnd,
                                     sentenceIndex: i, paragraphBreak: false)); id += 1
                } else {
                    out.append(Token(id: id, text: w, kind: .word,
                                     sentenceIndex: i, paragraphBreak: false)); id += 1
                }
            }
        }
        return out
    }
}
