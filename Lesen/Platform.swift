//  Platform.swift
//  Everything that differs between iOS and macOS lives here, so the rest of
//  the app stays platform-agnostic.

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Colours
//
// The systemGroupedBackground family is UIKit-only. These map to the closest
// native AppKit equivalents on the Mac.

enum Palette {
    /// Page background behind cards.
    static var grouped: Color {
        #if os(macOS)
        Color(nsColor: .underPageBackgroundColor)
        #else
        Color(.systemGroupedBackground)
        #endif
    }

    /// Card / row surface.
    static var card: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(.secondarySystemGroupedBackground)
        #endif
    }

    /// Fully opaque page background — for bars that must not show content
    /// scrolling behind them.
    static var page: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(.systemBackground)
        #endif
    }

    /// Subtle fill for unselected chips.
    static var fill: Color {
        #if os(macOS)
        Color(nsColor: .quaternarySystemFill)
        #else
        Color(.tertiarySystemFill)
        #endif
    }

    /// The app's purple. macOS resolves `Color.accentColor` to the *user's*
    /// system accent, so every accent in the app comes from here instead.
    static let brand: Color = {
        #if os(macOS)
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(red: 0.60, green: 0.58, blue: 0.91, alpha: 1)   // 9A93E8
                : NSColor(red: 0.36, green: 0.33, blue: 0.62, alpha: 1)   // 5C549E
        })
        #else
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.60, green: 0.58, blue: 0.91, alpha: 1)
                : UIColor(red: 0.36, green: 0.33, blue: 0.62, alpha: 1)
        })
        #endif
    }()
}

// MARK: - Modifiers

extension View {
    /// navigationBarTitleDisplayMode doesn't exist on macOS.
    func inlineTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    func largeTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.large)
        #else
        self
        #endif
    }

    /// Popovers adapt to sheets on compact iOS; macOS shows them natively.
    func asPopover() -> some View {
        #if os(iOS)
        presentationCompactAdaptation(.popover)
        #else
        self
        #endif
    }

    /// Sheet sizing is an iOS concept.
    func mediumSheet() -> some View {
        #if os(iOS)
        presentationDetents([.medium, .large])
        #else
        frame(minWidth: 420, minHeight: 520)
        #endif
    }

    /// Removes the window toolbar's own background so it doesn't sit as a
    /// lighter band above the page. Tinting it to match never quite works —
    /// hiding it lets the window background show through uniformly.
    @ViewBuilder
    func blendedToolbar() -> some View {
        #if os(macOS)
        if #available(macOS 15.0, *) {
            self.toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        } else {
            self.toolbarBackground(.hidden, for: .windowToolbar)
        }
        #else
        self
        #endif
    }

    /// Keeps long-form text at a comfortable measure on wide windows.
    func readingWidth() -> some View {
        frame(maxWidth: 720, alignment: .leading)
    }
}

// MARK: - Routes
//
// Destination-based NavigationLink { … } pushes are invisible to
// NavigationPath, so clearing the path can't pop them. Every push in the app
// therefore carries a value instead.

enum SettingsRoute: Hashable { case motherTongue }

struct ReaderRoute: Hashable {
    let bookID: String
    let chapter: Int
    var imported: Bool = false
}

// MARK: - Navigation shell
//
// On iOS each screen owns its NavigationStack. On macOS the split view's
// detail column owns a single stack (in MacRootView) so the sidebar can clear
// it — nesting a second stack inside it leaves pushed views stranded.

struct NavShell<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        #if os(macOS)
        content
        #else
        NavigationStack { content }
        #endif
    }
}

// MARK: - macOS root (sidebar instead of a tab bar)

#if os(macOS)
struct MacRootView: View {
    @EnvironmentObject private var store: ContentStore
    @State private var section: Section? = .library
    /// Bumped on every sidebar click so the detail column is rebuilt from
    /// scratch — even when you tap the section you're already in.
    @State private var path = NavigationPath()

    enum Section: Hashable, CaseIterable, Identifiable {
        case library, reading, imported, settings
        var id: Self { self }

        var key: String {
            switch self {
            case .library:  "tabLibrary"
            case .reading:  "tabContinue"
            case .imported: "tabMyBooks"
            case .settings: "tabSettings"
            }
        }

        var symbol: String {
            switch self {
            case .library:  "books.vertical.fill"
            case .reading:  "book.pages.fill"
            case .imported: "square.and.arrow.down.fill"
            case .settings: "gearshape.fill"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            // No List at all — List on macOS drags in AppKit's selection
            // machinery, which paints with the system accent regardless of
            // .tint. A plain stack of buttons has no such behaviour.
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(Section.allCases) { s in
                        Button {
                            section = s
                            path = NavigationPath()   // drop any pushed chapter
                        } label: {
                            HStack(spacing: 9) {
                                Image(systemName: s.symbol)
                                    .frame(width: 18)
                                Text(store.s(s.key))
                                Spacer(minLength: 0)
                            }
                            .font(.system(size: 13, weight: section == s ? .semibold : .regular))
                            .foregroundStyle(section == s ? Palette.brand : Color.primary)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(section == s ? Palette.brand.opacity(0.16) : .clear)
                            )
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
            }
            .scrollContentBackground(.hidden)
            .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 280)
        } detail: {
            NavigationStack(path: $path) {
                Group {
                    switch section {
                    case .library:  LibraryView()
                    case .reading:  ContinueView()
                    case .imported: MyBooksView()
                    case .settings: SettingsView()
                    case .none:     LibraryView()
                    }
                }
            }
            // Each section needs its own identity, otherwise SwiftUI reuses the
            // same NavigationStack and a pushed chapter stays on screen when you
            // switch sections — which looks like the sidebar has stopped working.
            .transition(.opacity)
        }
        .animation(.smooth(duration: 0.25), value: section)
        .frame(minWidth: 860, minHeight: 620)
    }
}
#endif


// MARK: - Motion

/// Fades and lifts an item into place, offset slightly by its position in a
/// list, so a screen assembles itself instead of snapping in.
struct StaggeredAppear: ViewModifier {
    let index: Int
    /// Body text gets a quicker, blur-free entrance — a slow blur on a wall
    /// of small text is genuinely unpleasant to read into.
    var fast: Bool = false
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : (fast ? 6 : 16))
            .blur(radius: shown ? 0 : (fast ? 0 : 2))
            .task {
                try? await Task.sleep(for: .milliseconds((fast ? 20 : 55) * index))
                withAnimation(.smooth(duration: fast ? 0.2 : 0.45)) { shown = true }
            }
    }
}

// MARK: - Buttons

/// Fully rounded capsule buttons.
struct SquircleButtonStyle: ButtonStyle {
    var prominent = false
    var tint: Color = Palette.brand

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .background(
                prominent ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.12)),
                in: .capsule
            )
            .foregroundStyle(prominent ? AnyShapeStyle(.white) : AnyShapeStyle(tint))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == SquircleButtonStyle {
    static var squircle: SquircleButtonStyle { .init() }
    static var squircleProminent: SquircleButtonStyle { .init(prominent: true) }
    static func squircle(_ tint: Color) -> SquircleButtonStyle { .init(tint: tint) }
}

extension View {
    func staggered(_ index: Int, fast: Bool = false) -> some View {
        modifier(StaggeredAppear(index: index, fast: fast))
    }

    /// A soft push used when a screen replaces another wholesale.
    func softSwap() -> some View {
        transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.97)),
            removal:   .opacity.combined(with: .scale(scale: 1.02))
        ))
    }
}
