//  ImportView.swift
//  Pick an .epub -> detect its language -> translate on-device -> read it.
//
//  Translation uses Apple's Translation framework: on-device, free, offline
//  once the language pack is downloaded, and nothing ever leaves the phone.
//  Requires iOS 18.

import SwiftUI
import UniformTypeIdentifiers
import Translation

// MARK: - Tab

struct MyBooksView: View {
    @EnvironmentObject private var imports: ImportStore
    @EnvironmentObject private var store: ContentStore
    @State private var showPicker = false
    @State private var pending: URL?

    var body: some View {
        NavShell {
            Group {
                if imports.books.isEmpty {
                    ContentUnavailableView {
                        Label(store.s("noImports"), systemImage: "square.and.arrow.down")
                    } description: {
                        Text(store.s("importHint"))
                    } actions: {
                        Button(store.s("chooseEpub")) { showPicker = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(imports.books) { book in
                            NavigationLink(value: ReaderRoute(bookID: book.id,
                                                              chapter: 0,
                                                              imported: true)) {
                                ImportedRow(book: book)
                            }
                        }
                        .onDelete { idx in
                            idx.map { imports.books[$0] }.forEach(imports.delete)
                        }
                    }
                }
            }
            .navigationTitle(store.s("tabMyBooks"))
            .navigationDestination(for: ReaderRoute.self) { route in
                if let b = imports.books.first(where: { $0.id == route.bookID }) {
                    ReaderView(book: b.asBook, chapterIndex: route.chapter,
                               localGlossary: b.glossary)
                }
            }
            .toolbar {
                if !imports.books.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button { showPicker = true } label: { Image(systemName: "plus") }
                    }
                }
            }
            .fileImporter(isPresented: $showPicker,
                          allowedContentTypes: [UTType(filenameExtension: "epub") ?? .data]) { result in
                if case .success(let url) = result { pending = url }
            }
            .sheet(item: $pending) { url in
                ImportFlowView(fileURL: url)
                    .environmentObject(imports)
                    .environmentObject(store)
            }
        }
    }
}

extension URL: @retroactive Identifiable { public var id: String { absoluteString } }

struct ImportedRow: View {
    @EnvironmentObject private var store: ContentStore
    let book: ImportedBook

    var body: some View {
        HStack(spacing: 14) {
            CoverArt(title: book.title,
                     level: book.germanIsMachineMade ? "MÜ" : "DE",
                     index: 0,
                     base: Color(red: 0.26, green: 0.30, blue: 0.38), width: 50)
            VStack(alignment: .leading, spacing: 3) {
                Text(book.title)
                    .font(.system(.headline, design: .serif))
                    .lineLimit(2)
                Text("\(book.chapters.count) \(store.s("chapters")) · \(book.chapters.reduce(0) { $0 + $1.sentences.count }) \(store.s("sentences"))")
                    .font(.caption).foregroundStyle(.secondary)
                if book.germanIsMachineMade {
                    Label(store.s("machineTranslated"), systemImage: "cpu")
                        .font(.caption2).foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Import flow

struct ImportFlowView: View {
    let fileURL: URL
    @EnvironmentObject private var imports: ImportStore
    @EnvironmentObject private var store: ContentStore
    @Environment(\.dismiss) private var dismiss

    @State private var phase: Phase = .reading
    @State private var parsed: ParsedEPUB?
    @State private var mode: ImportMode = .germanSource
    @State private var progress: Double = 0
    @State private var translated: [Int: String] = [:]     // global sentence index -> text
    @State private var wordGlossary: [String: String] = [:]
    @State private var pendingWords: [String] = []
    @State private var configuration: TranslationSession.Configuration?
    @State private var errorText: String?

    enum Phase { case reading, ready, translating, translatingWords, done, failed }

    /// Every sentence in the book, flattened, with a stable index.
    private var flatSentences: [String] {
        parsed?.chapters.flatMap(\.sentences) ?? []
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                switch phase {
                case .reading:
                    ProgressView("Datei wird gelesen…").padding(.top, 60)

                case .ready:
                    readyView

                case .translating, .translatingWords:
                    translatingView

                case .done:
                    doneView

                case .failed:
                    ContentUnavailableView(store.s("importFailed"),
                                           systemImage: "exclamationmark.triangle",
                                           description: Text(errorText ?? "Unbekannter Fehler"))
                }
                Spacer(minLength: 0)
            }
            .padding(22)
            .navigationTitle(store.s("importTitle"))
            .inlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(store.s("cancel")) { dismiss() }
                }
            }
            .task { await load() }
            // The translation session is driven by this modifier.
            .translationTask(configuration) { session in
                await runTranslation(session)
            }
        }
    }

    // MARK: Phases

    private var readyView: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(parsed?.title ?? "")
                    .font(.system(.title2, design: .serif).weight(.semibold))
                Text("\(parsed?.chapters.count ?? 0) Kapitel · \(flatSentences.count) Sätze")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            let lang = parsed?.language ?? "?"
            Label {
                if lang == "de" {
                    Text(String(format: store.s("detectedTarget"), languageName(lang)))
                } else {
                    Text(String(format: store.s("detectedOther"), languageName(lang)))
                }
            } icon: {
                Image(systemName: "character.book.closed")
            }
            .font(.callout)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.card, in: .rect(cornerRadius: 14))

            if mode.machineGeneratedGerman {
                Label("Maschinell erzeugtes Deutsch ist gut, aber nicht so natürlich wie die geschriebenen Reihen. Zum Lernen super — als Vorbild fürs eigene Schreiben mit Vorsicht.",
                      systemImage: "info.circle")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            Button {
                startTranslating()
            } label: {
                Label(store.s("translateAndAdd"), systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity).padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text(store.s("onDeviceNote"))
                .font(.caption).foregroundStyle(.tertiary)
        }
    }

    private var translatingView: some View {
        VStack(spacing: 18) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
            Text("\(Int(progress * 100)) %")
                .font(.title3.monospacedDigit().weight(.medium))
            Text(phase == .translatingWords
                 ? store.s("buildingGlossary")
                 : String(format: store.s("translatingN"), "\(flatSentences.count)"))
                .font(.footnote).foregroundStyle(.secondary)
            Text(store.s("longBookNote"))
                .font(.caption).foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 50)
    }

    private var doneView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48)).foregroundStyle(.green)
            Text(store.s("done")).font(.title2.weight(.semibold))
            Text("„\(parsed?.title ?? "")“ liegt jetzt unter „Meine Bücher“.")
                .font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(store.s("close")) { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(.top, 50)
    }

    // MARK: Work

    private func load() async {
        do {
            let p = try EPUBImporter.parse(url: fileURL)
            parsed = p
            mode = (p.language == store.targetLanguage) ? .germanSource : .translateToGerman(from: p.language)
            phase = .ready
        } catch {
            errorText = error.localizedDescription
            phase = .failed
        }
    }

    private func startTranslating() {
        phase = .translating
        configuration = TranslationSession.Configuration(
            source: Locale.Language(identifier: mode.sourceLanguage),
            target: Locale.Language(identifier: mode.targetLanguage)
        )
    }

    private func runTranslation(_ session: TranslationSession) async {
        switch phase {
        case .translating:      await translateSentences(session)
        case .translatingWords: await translateWords(session)
        default: return
        }
    }

    private func translateSentences(_ session: TranslationSession) async {
        guard let parsed else { return }
        let all = flatSentences
        guard !all.isEmpty else { return }

        do {
            let availability = LanguageAvailability()
            let status = await availability.status(
                from: Locale.Language(identifier: mode.sourceLanguage),
                to:   Locale.Language(identifier: mode.targetLanguage)
            )
            if status == .unsupported {
                errorText = "Language pair not supported."
                phase = .failed
                return
            }
            try await session.prepareTranslation()

            let chunkSize = 40
            for start in stride(from: 0, to: all.count, by: chunkSize) {
                let end = min(start + chunkSize, all.count)
                let requests = (start..<end).map {
                    TranslationSession.Request(sourceText: all[$0], clientIdentifier: String($0))
                }
                for try await response in session.translate(batch: requests) {
                    if let key = response.clientIdentifier, let i = Int(key) {
                        translated[i] = response.targetText
                    }
                }
                progress = Double(end) / Double(all.count) * 0.8   // sentences are 80% of the bar
            }

            assemble(parsed)
            startWordPass()
        } catch {
            errorText = "\(error)"
            phase = .failed
        }
    }

    /// Collect the unique words of the *reading* text and translate them into
    /// the reader's own language, so every word tap works in imported books.
    private func startWordPass() {
        var seen = Set<String>()
        for ch in assembledChapters {
            for s in ch.sentences {
                for raw in s.de.split(separator: " ") {
                    let w = raw.lowercased().trimmingCharacters(
                        in: CharacterSet(charactersIn: ".,!?;:„“\"'»«()—–…"))
                    if w.count > 1 { seen.insert(w) }
                }
            }
        }
        // cap it so a huge novel doesn't take forever
        pendingWords = Array(seen).sorted().prefix(6000).map { $0 }

        let readingLang = mode.machineGeneratedGerman ? mode.targetLanguage : mode.sourceLanguage
        let glossLang = store.motherTongue

        guard readingLang != glossLang, !pendingWords.isEmpty else {
            phase = .done
            progress = 1
            return
        }

        phase = .translatingWords
        configuration = TranslationSession.Configuration(
            source: Locale.Language(identifier: readingLang),
            target: Locale.Language(identifier: glossLang)
        )
    }

    private func translateWords(_ session: TranslationSession) async {
        let words = pendingWords
        guard !words.isEmpty else { phase = .done; return }
        do {
            try await session.prepareTranslation()
            let chunkSize = 100
            for start in stride(from: 0, to: words.count, by: chunkSize) {
                let end = min(start + chunkSize, words.count)
                let requests = (start..<end).map {
                    TranslationSession.Request(sourceText: words[$0], clientIdentifier: String($0))
                }
                for try await response in session.translate(batch: requests) {
                    if let key = response.clientIdentifier, let i = Int(key) {
                        wordGlossary[words[i]] = response.targetText
                    }
                }
                progress = 0.8 + Double(end) / Double(words.count) * 0.2
            }
            saveWithGlossary()
            phase = .done
        } catch {
            // A failed word pass shouldn't lose the book — save without it.
            saveWithGlossary()
            phase = .done
        }
    }

    @State private var assembledChapters: [Chapter] = []

    /// Rebuild chapters as reading/translation sentence pairs.
    private func assemble(_ parsed: ParsedEPUB) {
        var index = 0
        var chapters: [Chapter] = []

        for (n, ch) in parsed.chapters.enumerated() {
            var pairs: [Sentence] = []
            for source in ch.sentences {
                let output = translated[index] ?? ""
                switch mode {
                case .germanSource:
                    // read the original German, English underneath
                    pairs.append(Sentence(de: source, en: output))
                case .translateToGerman:
                    // read the generated German, original underneath
                    pairs.append(Sentence(de: output.isEmpty ? source : output, en: source))
                }
                index += 1
            }
            chapters.append(Chapter(number: n + 1, title: ch.title, sentences: pairs))
        }

        assembledChapters = chapters
    }

    private func saveWithGlossary() {
        guard let parsed else { return }
        imports.save(ImportedBook(
            id: UUID().uuidString,
            title: parsed.title,
            sourceLanguage: parsed.language,
            germanIsMachineMade: mode.machineGeneratedGerman,
            importedAt: .now,
            chapters: assembledChapters,
            glossary: wordGlossary
        ))
    }

    private func languageName(_ code: String) -> String {
        Locale(identifier: store.uiLang).localizedString(forLanguageCode: code) ?? code.uppercased()
    }
}
