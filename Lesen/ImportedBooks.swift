//  ImportedBooks.swift
//  Persistence for user-imported books, and the two reading modes.

import Foundation
import SwiftUI
import Combine

/// What we do with an imported book, decided by its detected language.
enum ImportMode {
    /// Book is already German. Read the German, translate to English underneath.
    case germanSource
    /// Book is in another language. Translate INTO German (that's what you read),
    /// and use the ORIGINAL text as the translation layer — perfectly aligned,
    /// because the original is the source.
    case translateToGerman(from: String)

    var readingLanguage: String { "de" }

    var sourceLanguage: String {
        switch self {
        case .germanSource: "de"
        case .translateToGerman(let l): l
        }
    }

    var targetLanguage: String {
        switch self {
        case .germanSource: "en"          // German stays, English is generated
        case .translateToGerman: "de"     // German is generated, original is the layer
        }
    }

    var machineGeneratedGerman: Bool {
        if case .translateToGerman = self { return true }
        return false
    }
}

// MARK: - Stored model

struct ImportedBook: Codable, Identifiable, Hashable {
    let id: String
    var title: String
    var sourceLanguage: String
    var germanIsMachineMade: Bool
    var importedAt: Date
    var chapters: [Chapter]          // same shape as the bundled books

    /// Word-level translations built at import time, so tapping any word in
    /// an imported book works — the bundled glossary only covers the
    /// written series. Defaults empty for books imported before this existed.
    var glossary: [String: String] = [:]

    /// Adapt to the shape ReaderView expects.
    var asBook: Book {
        Book(id: id, title: title,
             level: germanIsMachineMade ? "Import · MÜ" : "Import",
             emoji: "", blurb: "", chapters: chapters)
    }
}

// Book/Chapter/Sentence are Decodable in Models.swift; imported books need
// to round-trip, so these add the encoding side.
extension Book: Encodable {
    enum CodingKeys: String, CodingKey { case id, title, level, emoji, blurb, chapters }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id); try c.encode(title, forKey: .title)
        try c.encode(level, forKey: .level); try c.encode(emoji, forKey: .emoji)
        try c.encode(blurb, forKey: .blurb); try c.encode(chapters, forKey: .chapters)
    }
}

extension Chapter: Encodable {
    enum CodingKeys: String, CodingKey { case number, title, sentences }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(number, forKey: .number); try c.encode(title, forKey: .title)
        try c.encode(sentences, forKey: .sentences)
    }
}

extension Sentence: Encodable {
    enum CodingKeys: String, CodingKey { case de, en }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(de, forKey: .de); try c.encode(en, forKey: .en)
    }
}

// MARK: - Store

@MainActor
final class ImportStore: ObservableObject {

    @Published private(set) var books: [ImportedBook] = []

    /// Imported books live in a folder per target language, so switching
    /// language switches which imports you see.
    @Published var language: String = "de" {
        didSet { reload() }
    }

    private var dir: URL {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Imported", isDirectory: true)
            .appendingPathComponent(language, isDirectory: true)
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }

    init() { reload() }

    func reload() {
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        books = files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> ImportedBook? in
                guard let d = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(ImportedBook.self, from: d)
            }
            .sorted { $0.importedAt > $1.importedAt }
    }

    func save(_ book: ImportedBook) {
        guard let d = try? JSONEncoder().encode(book) else { return }
        try? d.write(to: dir.appendingPathComponent("\(book.id).json"))
        reload()
    }

    func delete(_ book: ImportedBook) {
        try? FileManager.default.removeItem(at: dir.appendingPathComponent("\(book.id).json"))
        reload()
    }
}
