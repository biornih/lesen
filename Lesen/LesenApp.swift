//  LesenApp.swift
//  Entry point, onboarding gate, tab bar.

import SwiftUI
#if os(iOS)
import UIKit
#endif

@main
struct LesenApp: App {
    @StateObject private var store   = ContentStore()
    @StateObject private var imports = ImportStore()

    init() {
        #if os(iOS)
        // The tab bar's selected item colour comes from UIKit appearance,
        // not from SwiftUI's .tint.
        UITabBar.appearance().tintColor = UIColor(Palette.brand)
        UINavigationBar.appearance().tintColor = UIColor(Palette.brand)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(imports)
                // macOS follows the user's system accent unless told otherwise,
                // so tint with an explicit colour to stay purple everywhere.
                .tint(Palette.brand)
        }
        #if os(macOS)
        .defaultSize(width: 1000, height: 720)
        .windowResizability(.contentMinSize)
        #endif
    }
}

struct RootView: View {
    @EnvironmentObject private var store: ContentStore
    @EnvironmentObject private var imports: ImportStore
    @State private var tab: Tab = .library

    enum Tab: Hashable { case library, reading, imported, settings }

    var body: some View {
        Group {
            if store.hasOnboarded {
                #if os(macOS)
                MacRootView()
                #else
                TabView(selection: $tab) {
                    LibraryView()
                        .tabItem { Label(store.s("tabLibrary"), systemImage: "books.vertical.fill") }
                        .tag(Tab.library)

                    ContinueView()
                        .tabItem { Label(store.s("tabContinue"), systemImage: "book.pages.fill") }
                        .tag(Tab.reading)

                    MyBooksView()
                        .tabItem { Label(store.s("tabMyBooks"), systemImage: "square.and.arrow.down.fill") }
                        .tag(Tab.imported)

                    SettingsView()
                        .tabItem { Label(store.s("tabSettings"), systemImage: "gearshape.fill") }
                        .tag(Tab.settings)
                }
                // Shrinks the bar to a single pill on scroll, like Apple Music.
                .modifier(MinimizingTabBar())
                .softSwap()
                #endif
            } else {
                OnboardingView()
                    .softSwap()
            }
        }
        .animation(.smooth(duration: 0.45), value: store.hasOnboarded)
        .onAppear { imports.language = store.targetLanguage }
        .onChange(of: store.targetLanguage) { _, new in imports.language = new }
    }
}

// MARK: - Continue

struct ContinueView: View {
    @EnvironmentObject private var store: ContentStore
    @EnvironmentObject private var imports: ImportStore

    var body: some View {
        NavShell {
            Group {
                if let last = store.lastRead, let book = store.book(id: last.bookID) {
                    let index = min(max(0, last.chapter - 1), book.chapters.count - 1)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(store.s("lastRead"))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(book.title)
                                    .font(.system(.largeTitle, design: .serif).weight(.medium))
                                Text("\(store.s("chapter")) \(book.chapters[index].number) · \(book.chapters[index].title)")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                            .staggered(0)

                            NavigationLink(value: ReaderRoute(bookID: book.id, chapter: index)) {
                                Label(store.s("keepReading"), systemImage: "book.pages")
                            }
                            .buttonStyle(.squircleProminent)
                            .staggered(1)

                            if index < book.chapters.count - 1 {
                                NavigationLink(value: ReaderRoute(bookID: book.id, chapter: index + 1)) {
                                    Label(store.s("nextChapter"), systemImage: "chevron.right")
                                }
                                .buttonStyle(.squircle)
                                .staggered(2)
                            }

                            tip
                                .staggered(3)
                        }
                        .readingWidth()
                        .frame(maxWidth: .infinity)
                        .padding(22)
                    }
                } else {
                    ContentUnavailableView(
                        store.s("nothingRead"),
                        systemImage: "book.closed",
                        description: Text(store.s("nothingReadHint"))
                    )
                }
            }
            .navigationTitle(store.s("tabContinue"))
            .navigationDestination(for: ReaderRoute.self) { route in
                readerDestination(route)
            }
        }
    }

    @ViewBuilder
    func readerDestination(_ route: ReaderRoute) -> some View {
        if route.imported,
           let b = imports.books.first(where: { $0.id == route.bookID }) {
            ReaderView(book: b.asBook, chapterIndex: route.chapter,
                       localGlossary: b.glossary)
        } else if let b = store.book(id: route.bookID) {
            ReaderView(book: b, chapterIndex: route.chapter)
        }
    }

    private var tip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(store.s("tip"), systemImage: "lightbulb")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)
            Text(store.s("tipBody"))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card, in: .rect(cornerRadius: 16))
        .padding(.top, 10)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject private var store: ContentStore

    /// A short line in the target language, for testing the voice.
    private var sampleLine: String {
        switch store.targetLanguage {
        case "fr": "La nuit est calme au bord du fleuve."
        case "es": "La noche está tranquila junto al río."
        case "it": "La notte è tranquilla lungo il fiume."
        case "ru": "Ночь у реки тихая."
        case "tr": "Nehir kıyısında gece sessiz."
        default:   "Die Nacht in Regensburg ist still."
        }
    }
    @AppStorage("fontSize")   private var fontSize: Double = 21
    @AppStorage("serif")      private var serif: Bool = true
    @AppStorage("speechRate") private var speechRate: Double = 0.45

    var body: some View {
        NavShell {
            Form {
                Section {
                    Picker(store.s("learning"), selection: $store.targetLanguage) {
                        ForEach(Languages.targets.filter(\.available)) { t in
                            Text(t.endonym).tag(t.code)
                        }
                    }
                    NavigationLink(value: SettingsRoute.motherTongue) {
                        LabeledContent(store.s("myLanguage"),
                                       value: Languages.motherTongue(code: store.motherTongue).endonym)
                    }
                    Toggle(store.s("immersion"), isOn: $store.immersionMode)
                } header: {
                    Text(store.s("languages"))
                } footer: {
                    Text(store.s("immersionHint"))
                }

                Section {
                    Picker(store.s("levelHeader"), selection: $store.level) {
                        ForEach(Level.allCases) { l in
                            Text("\(l.code) · \(l.title(store.uiLang))").tag(l)
                        }
                    }
                } header: {
                    Text(store.s("levelHeader"))
                } footer: {
                    Text(store.s("levelFooter"))
                }

                Section(store.s("readingHeader")) {
                    Slider(value: $fontSize, in: 15...30, step: 1) {
                        Text(store.s("textSize"))
                    } minimumValueLabel: {
                        Image(systemName: "textformat.size.smaller")
                            .foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Image(systemName: "textformat.size.larger")
                            .foregroundStyle(.secondary)
                    }
                    .labelsHidden()
                    Toggle(store.s("serifFont"), isOn: $serif)
                    Text(store.s("sampleSentence"))
                        .font(serif ? .system(size: fontSize, design: .serif)
                                    : .system(size: fontSize))
                        .padding(.vertical, 4)
                }

                Section {
                    Button {
                        store.hasOnboarded = false
                    } label: {
                        Label(store.s("replayOnboarding"), systemImage: "sparkles")
                    }
                } footer: {
                    Text(store.s("replayOnboardingHint"))
                }

                Section(store.s("speech")) {
                    Slider(value: $speechRate, in: 0.3...0.6) {
                        Text(store.s("speech"))
                    } minimumValueLabel: {
                        Image(systemName: "tortoise").foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Image(systemName: "hare").foregroundStyle(.secondary)
                    }
                    .labelsHidden()
                    Button {
                        Speaker.shared.say(sampleLine, rate: speechRate, language: store.targetLanguage)
                    } label: {
                        Label(store.s("listen"), systemImage: "speaker.wave.2")
                    }
                }
            }
            .formStyle(.grouped)
            // Form labels shouldn't pick up the accent tint — only controls should.
            .foregroundStyle(Color.primary)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .navigationTitle(store.s("tabSettings"))
            .navigationDestination(for: SettingsRoute.self) { _ in
                MotherTonguePicker()
            }
        }
    }
}

// MARK: - Mother tongue picker (Settings)

struct MotherTonguePicker: View {
    @EnvironmentObject private var store: ContentStore

    var body: some View {
        List(Languages.motherTongues) { m in
            Button {
                store.motherTongue = m.code
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(m.endonym)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.primary)
                        if m.endonym != m.english {
                            Text(m.english)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                    if m.code == store.motherTongue {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Palette.brand)
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(m.code == store.motherTongue
                              ? Palette.brand.opacity(0.18)
                              : Color.primary.opacity(0.05))
                )
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 2, leading: 14, bottom: 2, trailing: 14))
        }
        .navigationTitle(store.s("myLanguage"))
        .inlineTitle()
    }
}


// MARK: - Shrinking tab bar

/// iOS 26 minimises the tab bar to a single pill while you scroll,
/// the way Apple Music does. Older systems keep the standard bar.
struct MinimizingTabBar: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS) && !targetEnvironment(macCatalyst)
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
        #else
        content
        #endif
    }
}
