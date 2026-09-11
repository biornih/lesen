//  EPUBImporter.swift
//  Turns a user's .epub into the same Book shape the bundled series uses,
//  so the reader works on it unchanged.
//
//  An EPUB is a ZIP containing XHTML:
//    META-INF/container.xml  ->  points at the .opf
//    content.opf             ->  manifest (files) + spine (reading order)
//    *.xhtml                 ->  the actual chapters
//
//  Requires the ZIPFoundation package (see README).

import Foundation
import NaturalLanguage
import ZIPFoundation

// MARK: - Errors

enum ImportError: LocalizedError {
    case notAnEPUB, unreadable, noContent, noLanguage

    var errorDescription: String? {
        switch self {
        case .notAnEPUB:  "Das scheint keine gültige EPUB-Datei zu sein."
        case .unreadable: "Die Datei konnte nicht gelesen werden."
        case .noContent:  "In dieser Datei wurde kein Text gefunden."
        case .noLanguage: "Die Sprache des Buches konnte nicht erkannt werden."
        }
    }
}

// MARK: - Parsed result

struct ParsedEPUB {
    let title: String
    let language: String            // BCP-47, e.g. "en", "de"
    let chapters: [ParsedChapter]

    var sentenceCount: Int { chapters.reduce(0) { $0 + $1.sentences.count } }
}

struct ParsedChapter {
    let title: String
    let sentences: [String]         // source-language sentences
}

// MARK: - Importer

enum EPUBImporter {

    /// Parse an .epub at `url` into chapters of sentences.
    static func parse(url: URL) throws -> ParsedEPUB {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let archive: Archive
        do {
            archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw ImportError.notAnEPUB
        }

        // 1. container.xml -> path of the .opf
        guard let containerData = try? data(in: archive, path: "META-INF/container.xml"),
              let containerXML = String(data: containerData, encoding: .utf8),
              let opfPath = firstMatch(in: containerXML, pattern: #"full-path="([^"]+)""#)
        else { throw ImportError.notAnEPUB }

        guard let opfData = try? data(in: archive, path: opfPath),
              let opf = String(data: opfData, encoding: .utf8)
        else { throw ImportError.unreadable }

        let root = (opfPath as NSString).deletingLastPathComponent

        // 2. metadata
        let title = firstMatch(in: opf, pattern: #"<dc:title[^>]*>([^<]+)</dc:title>"#)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? url.deletingPathExtension().lastPathComponent
        let declaredLang = firstMatch(in: opf, pattern: #"<dc:language[^>]*>([^<]+)</dc:language>"#)?
            .prefix(2).lowercased()

        // 3. manifest: id -> href (only XHTML documents)
        var manifest: [String: String] = [:]
        for item in matches(in: opf, pattern: #"<item\b[^>]*>"#) {
            guard let id = firstMatch(in: item, pattern: #"id="([^"]+)""#),
                  let href = firstMatch(in: item, pattern: #"href="([^"]+)""#),
                  let type = firstMatch(in: item, pattern: #"media-type="([^"]+)""#),
                  type.contains("xhtml") || type.contains("html")
            else { continue }
            manifest[id] = href
        }

        // 4. spine: reading order
        var hrefs: [String] = []
        for ref in matches(in: opf, pattern: #"<itemref\b[^>]*>"#) {
            guard let idref = firstMatch(in: ref, pattern: #"idref="([^"]+)""#),
                  let href = manifest[idref] else { continue }
            hrefs.append(href)
        }
        if hrefs.isEmpty { hrefs = Array(manifest.values) }

        // 5. extract text from each document
        var chapters: [ParsedChapter] = []
        for (i, href) in hrefs.enumerated() {
            let full = root.isEmpty ? href : "\(root)/\(href)"
            guard let d = try? data(in: archive, path: full.removingPercentEncoding ?? full),
                  let html = String(data: d, encoding: .utf8) ?? String(data: d, encoding: .isoLatin1)
            else { continue }

            let rawHeading = firstMatch(in: html, pattern: #"<h[1-3][^>]*>([\s\S]*?)</h[1-3]>"#)
            let heading = rawHeading.map { stripTags($0) }?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let text = stripTags(html)
            guard text.count > 200 else { continue }   // skip covers, TOC, colophon

            let sentences = splitSentences(text)
            guard !sentences.isEmpty else { continue }

            let name = (heading?.isEmpty == false ? heading! : "Kapitel \(chapters.count + 1)")
            chapters.append(ParsedChapter(title: name, sentences: sentences))
            _ = i
        }

        guard !chapters.isEmpty else { throw ImportError.noContent }

        // 6. language: trust detection over the declaration
        let sample = chapters.prefix(3).flatMap(\.sentences).prefix(40).joined(separator: " ")
        let detected = detectLanguage(sample) ?? declaredLang
        guard let language = detected else { throw ImportError.noLanguage }

        return ParsedEPUB(title: title, language: language, chapters: chapters)
    }

    // MARK: Helpers

    private static func data(in archive: Archive, path: String) throws -> Data {
        guard let entry = archive[path] else { throw ImportError.unreadable }
        var out = Data()
        _ = try archive.extract(entry) { out.append($0) }
        return out
    }

    /// Strip tags, drop script/style, decode the common entities, collapse whitespace.
    static func stripTags(_ html: String) -> String {
        var s = html
        for tag in ["script", "style", "head"] {
            s = s.replacingOccurrences(
                of: "<\(tag)[\\s\\S]*?</\(tag)>",
                with: " ", options: [.regularExpression, .caseInsensitive])
        }
        // block elements become paragraph breaks
        s = s.replacingOccurrences(of: "</(p|div|h[1-6]|li|br)[^>]*>",
                                   with: "\n", options: [.regularExpression, .caseInsensitive])
        s = s.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let entities = ["&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">",
                        "&quot;": "\"", "&#39;": "'", "&rsquo;": "’", "&lsquo;": "‘",
                        "&ldquo;": "“", "&rdquo;": "”", "&mdash;": "—", "&ndash;": "–",
                        "&hellip;": "…", "&auml;": "ä", "&ouml;": "ö", "&uuml;": "ü",
                        "&Auml;": "Ä", "&Ouml;": "Ö", "&Uuml;": "Ü", "&szlig;": "ß"]
        for (k, v) in entities { s = s.replacingOccurrences(of: k, with: v) }
        s = s.replacingOccurrences(of: "&#[0-9]+;", with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: "\n{2,}", with: "\n", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Apple's tokenizer handles abbreviations and quotes far better than a regex.
    static func splitSentences(_ text: String) -> [String] {
        let tk = NLTokenizer(unit: .sentence)
        tk.string = text
        var out: [String] = []
        tk.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let s = text[range].trimmingCharacters(in: .whitespacesAndNewlines)
            if s.count > 1 { out.append(s) }
            return true
        }
        return out
    }

    static func detectLanguage(_ text: String) -> String? {
        let r = NLLanguageRecognizer()
        r.processString(text)
        return r.dominantLanguage?.rawValue
    }

    private static func matches(in s: String, pattern: String) -> [String] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return [] }
        let ns = s as NSString
        return re.matches(in: s, range: NSRange(location: 0, length: ns.length)).map {
            ns.substring(with: $0.range)
        }
    }

    private static func firstMatch(in s: String, pattern: String) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let ns = s as NSString
        guard let m = re.firstMatch(in: s, range: NSRange(location: 0, length: ns.length)),
              m.numberOfRanges > 1 else { return nil }
        return ns.substring(with: m.range(at: 1))
    }
}
