//  ReaderView.swift
//  The core mechanic:
//    • tap a word            -> popover with its translation (+ listen)
//    • tap the sentence's .  -> full sentence translation slides in on top
//  Nothing is tracked. You just read.

import SwiftUI
import AVFoundation

// MARK: - German speech

final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()

    private init() {
        // Without an active .playback session, speech is silenced by the
        // physical mute switch. macOS has no audio session at all.
        #if os(iOS) && !targetEnvironment(macCatalyst)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
        #endif
    }

    /// `language` is a BCP-47 code, e.g. "de".
    func say(_ text: String, rate: Double = 0.45, language: String = "de") {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Reactivate in case another app took the session in the meantime.
        #if os(iOS) && !targetEnvironment(macCatalyst)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        let u = AVSpeechUtterance(string: text)

        // Prefer an exact voice; fall back to any voice for that language,
        // then to the system default rather than going silent.
        let wanted = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(language) }
        u.voice = AVSpeechSynthesisVoice(language: "\(language)-\(language.uppercased())")
            ?? wanted.first
            ?? AVSpeechSynthesisVoice(language: language)

        // AVSpeechUtterance expects 0...1 around a default of 0.5.
        u.rate = Float(min(max(rate, 0.1), 1.0))
        u.preUtteranceDelay = 0.05

        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        synth.speak(u)
    }
}

// MARK: - Reader

struct ReaderView: View {
    let book: Book
    @State var chapterIndex: Int
    /// Imported books carry their own glossary; bundled books pass nil and
    /// fall back to the curated one in the store.
    var localGlossary: [String: String]? = nil

    @EnvironmentObject private var store: ContentStore
    @AppStorage("fontSize")   private var fontSize: Double = 21
    @AppStorage("serif")      private var serif: Bool = true
    @AppStorage("speechRate") private var speechRate: Double = 0.45

    @State private var openToken: Int?
    @State private var banner: (sentence: Int, en: String)?
    @State private var showChapterList = false

    private var chapter: Chapter { book.chapters[chapterIndex] }
    private var tokens: [Token] { store.tokens(for: chapter) }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                            .staggered(0, fast: true)
                        FlowLayout(hSpacing: 5, vSpacing: 13) {
                            ForEach(tokens) { token in
                                tokenView(token)
                            }
                        }
                        .staggered(1, fast: true)
                        footer
                            .staggered(2, fast: true)
                    }
                    .readingWidth()
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                    .frame(maxWidth: .infinity)      // centre the column
                    .id("top")
                }
                .onChange(of: chapterIndex) { _, _ in
                    banner = nil; openToken = nil
                    withAnimation { proxy.scrollTo("top", anchor: .top) }
                }
            }

            if let b = banner {
                translationBanner(b.en)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .gesture(
                        DragGesture(minimumDistance: 12)
                            .onEnded { value in
                                if value.translation.height < -20 { banner = nil }
                            }
                    )
                    // Fades itself out; tapping another period resets the timer.
                    .task(id: b.sentence) {
                        try? await Task.sleep(for: .seconds(5))
                        if !Task.isCancelled { banner = nil }
                    }
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: banner?.sentence)
        .navigationTitle(book.title)
        .inlineTitle()
        // Reading is a full-screen mode: the tab bar goes away entirely rather
        // than sitting there minimised and swallowing the first tap.
        #if os(iOS)
        .toolbar(.hidden, for: .tabBar)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { showChapterList = true } label: {
                        Label(store.s("chooseChapter"), systemImage: "list.bullet")
                    }
                    Button { Speaker.shared.say(chapter.sentences.map(\.de).joined(separator: " "), rate: speechRate, language: store.targetLanguage) } label: {
                        Label(store.s("readAloud"), systemImage: "speaker.wave.2")
                    }
                    Divider()
                    Stepper(store.s("textSize"), value: $fontSize, in: 15...30, step: 1)
                    Toggle(store.s("serifFont"), isOn: $serif)
                } label: {
                    Image(systemName: "textformat.size")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .menuIndicator(.hidden)
                .tint(Color.primary)      // menu items keep their own colours
            }
        }
        .sheet(isPresented: $showChapterList) {
            ChapterPicker(book: book, current: $chapterIndex)
                .mediumSheet()
        }
        .onAppear { store.markRead(book: book, chapter: chapter.number) }
        .onChange(of: chapterIndex) { _, _ in store.markRead(book: book, chapter: chapter.number) }
    }

    // MARK: Pieces

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(store.s("chapter")) \(chapter.number)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)
            Text(chapter.title)
                .font(.system(.largeTitle, design: .serif).weight(.medium))
            Text(store.s("readerHint"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .padding(.bottom, 4)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if chapterIndex > 0 {
                Button {
                    chapterIndex -= 1
                } label: {
                    Label(store.s("back"), systemImage: "chevron.left")
                }
                .buttonStyle(.squircle)
            }
            if chapterIndex < book.chapters.count - 1 {
                Button {
                    chapterIndex += 1
                } label: {
                    Label(store.s("next"), systemImage: "chevron.right")
                }
                .buttonStyle(.squircleProminent)
            } else {
                Text(store.s("endOfVolume"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
        }
        .padding(.top, 26)
    }

    @ViewBuilder
    private func tokenView(_ token: Token) -> some View {
        let font: Font = serif
            ? .system(size: fontSize, design: .serif)
            : .system(size: fontSize)

        switch token.kind {
        case .word:
            Text(token.text)
                .font(font)
                .foregroundStyle(.primary)
                .contentShape(.rect)
                .onTapGesture {
                    banner = nil
                    openToken = token.id
                }
                .popover(isPresented: binding(for: token.id),
                         attachmentAnchor: .point(.top),
                         arrowEdge: .top) {
                    wordCard(token.text)
                        .asPopover()
                }

        case .sentenceEnd:
            Text(token.text)
                .font(font.weight(.semibold))
                .foregroundStyle(banner?.sentence == token.sentenceIndex ? Palette.brand : .primary)
                .padding(.horizontal, 3)
                .contentShape(.rect)
                .onTapGesture {
                    openToken = nil
                    let en = chapter.sentences[token.sentenceIndex].en
                    if banner?.sentence == token.sentenceIndex {
                        banner = nil
                    } else {
                        banner = (token.sentenceIndex, en)
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    }
                }
        }
    }

    private func wordCard(_ word: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 10) {
                Text(store.normalize(word))
                    .font(.system(.title3, design: .serif).weight(.semibold))
                Button {
                    Speaker.shared.say(word, rate: speechRate, language: store.targetLanguage)
                } label: {
                    Image(systemName: "speaker.wave.2.fill").font(.footnote)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
            if let g = glossLookup(word) {
                Text(g)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text(store.s("notInDictionary"))
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(15)
        .frame(minWidth: 170, maxWidth: 280, alignment: .leading)
    }

    private func translationBanner(_ en: String) -> some View {
        Text(en)
            .font(.system(size: 17, weight: .regular))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(.regularMaterial, in: .capsule)
            .overlay(Capsule().strokeBorder(.separator.opacity(0.6)))
            .padding(.horizontal, 16)
            .shadow(color: .black.opacity(0.16), radius: 20, y: 8)
    }

    /// Per-book glossary first, then the curated one.
    private func glossLookup(_ raw: String) -> String? {
        let w = store.normalize(raw)
        if let local = localGlossary {
            if let hit = local[w] { return hit }
            if w.count > 4 {
                for cut in [1, 2] where w.count - cut >= 3 {
                    if let hit = local[String(w.dropLast(cut))] { return hit }
                }
            }
        }
        return store.gloss(for: raw)
    }

    private func binding(for id: Int) -> Binding<Bool> {
        Binding(get: { openToken == id },
                set: { openToken = $0 ? id : nil })
    }
}

// MARK: - Chapter picker

struct ChapterPicker: View {
    @EnvironmentObject private var store: ContentStore
    let book: Book
    @Binding var current: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(book.chapters.enumerated()), id: \.element.number) { index, ch in
                    Button {
                        current = index
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Text("\(ch.number)")
                                .font(.footnote.monospacedDigit().weight(.semibold))
                                .foregroundStyle(Palette.brand)
                                .frame(width: 24, alignment: .trailing)
                            Text(ch.title)
                                .font(.system(.body, design: .serif))
                                .foregroundStyle(Color.primary)
                            Spacer(minLength: 0)
                            if index == current {
                                Image(systemName: "book.fill")
                                    .font(.caption)
                                    .foregroundStyle(Palette.brand)
                            }
                        }
                        .frame(height: 30)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(store.s("chooseChapter"))
            .inlineTitle()
        }
    }
}
