//  LibraryView.swift
//  Genres → Series → Books.
//  Locking gates on LEVEL, not on "you finished this exact series", so a
//  B2 user isn't forced through the beginner ladder before anything opens.

import SwiftUI

// MARK: - Genres

struct LibraryView: View {
    @EnvironmentObject private var store: ContentStore

    var body: some View {
        NavShell {
            ScrollView {
                VStack(spacing: 14) {
                    levelBanner
                        .staggered(0)
                    ForEach(Array(Catalog.genres.enumerated()), id: \.element.id) { i, genre in
                        Group {
                            if genre.comingSoon {
                                GenreCard(genre: genre).opacity(0.45)
                            } else {
                                NavigationLink(value: genre) { GenreCard(genre: genre) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .staggered(i + 1)
                    }
                }
                .readingWidth()
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            .background(Palette.grouped)
            .navigationTitle(store.s("genres"))
            .navigationDestination(for: Genre.self) { SeriesListView(genre: $0) }
            .navigationDestination(for: Series.self) { SeriesDetailView(series: $0) }
            .navigationDestination(for: Book.self) { book in
                ReaderView(book: book, chapterIndex: max(0, store.chaptersRead(in: book) - 1))
            }
        }
    }

    private var levelBanner: some View {
        HStack(spacing: 12) {
            Text(store.level.code)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 36)
                .background(Palette.brand, in: .rect(cornerRadius: 9))
            VStack(alignment: .leading, spacing: 1) {
                Text(store.s("yourLevel")).font(.caption).foregroundStyle(.secondary)
                Text(store.level.title(store.uiLang)).font(.subheadline.weight(.medium))
            }
            Spacer()
        }
        .padding(14)
        .background(Palette.card, in: .rect(cornerRadius: 16))
        .padding(.bottom, 2)
    }
}

struct GenreCard: View {
    @EnvironmentObject private var store: ContentStore
    let genre: Genre

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: genre.symbol)
                .font(.system(size: 25))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(
                    LinearGradient(colors: [genre.tint, genre.tint.opacity(0.65)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: .rect(cornerRadius: 15)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(store.s(genre.name))
                    .font(.system(.title3, design: .serif).weight(.semibold))
                    .foregroundStyle(.primary)
                Text(genre.comingSoon ? store.s(genre.subtitle)
                                      : "\(genre.totalSeries) \(store.s("seriesCount")) · \(store.s(genre.subtitle))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if !genre.comingSoon {
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background(Palette.card, in: .rect(cornerRadius: 20))
    }
}

// MARK: - Series in a genre

struct SeriesListView: View {
    @EnvironmentObject private var store: ContentStore
    let genre: Genre
    @State private var pairingIndex = 0

    private var shownSeries: [Series] {
        genre.hasPairings ? genre.pairings[pairingIndex].series : genre.series
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                if genre.hasPairings {
                    pairingSelector
                }

                ForEach(Array(shownSeries.enumerated()), id: \.element.id) { i, series in
                    let state = store.unlockState(for: series)
                    Group {
                        if state == .locked {
                            SeriesCard(series: series, state: state)
                        } else {
                            NavigationLink(value: series) {
                                SeriesCard(series: series, state: state)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .staggered(i)
                }

                Text(store.s("levelFooter"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.top, 6)
            }
            .readingWidth()
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.grouped)
        .navigationTitle(store.s(genre.name))
        .largeTitle()
    }

    /// Romance opens on M / W; the menu swaps the shelf underneath.
    private var pairingSelector: some View {
        let pairing = genre.pairings[pairingIndex]
        return VStack(alignment: .leading, spacing: 6) {
            Menu {
                ForEach(Array(genre.pairings.enumerated()), id: \.element.id) { i, p in
                    Button {
                        withAnimation(.smooth(duration: 0.25)) { pairingIndex = i }
                    } label: {
                        if i == pairingIndex {
                            Label(p.label, systemImage: "checkmark")
                        } else {
                            Text(p.label)
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(pairing.label)
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Palette.brand)
                }
                .padding(.horizontal, 14)
                .frame(height: 40)
                .background(Palette.brand.opacity(0.12), in: .capsule)
            }
            .menuIndicator(.hidden)
            .tint(Color.primary)
            .buttonStyle(.plain)

            Text(store.s(pairing.descriptionKey))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
                .id(pairing.id)
                .transition(.opacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
}

enum UnlockState { case current, locked, easier, done }

struct SeriesCard: View {
    @EnvironmentObject private var store: ContentStore
    let series: Series
    let state: UnlockState

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 14) {
                CoverArt(title: series.title, level: series.levelRange, index: 0,
                         base: series.palette.first ?? .gray, width: 58)
                    .grayscale(state == .locked ? 1 : 0)
                    .opacity(state == .locked ? 0.5 : 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(series.title)
                        .font(.system(.title3, design: .serif).weight(.semibold))
                        .foregroundStyle(state == .locked ? .secondary : .primary)
                    Text(store.s(series.tagline))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                badge(series.levelRange, color: Palette.brand)
                switch state {
                case .locked:
                    badge(store.s("locked"), color: .secondary, icon: "lock.fill")
                case .easier:
                    badge(store.s("easierOptional"), color: .secondary)
                case .done:
                    badge(store.s("completed"), color: .green, icon: "checkmark")
                case .current:
                    if !series.available { badge(store.s("inProgress"), color: .orange) }
                }
                Spacer()
                if series.available, !series.bookIDs.isEmpty {
                    Text("\(series.bookIDs.count) \(store.s("volumes"))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            if state == .locked {
                Text(String(format: store.s("lockedHint"), series.startLevel.code))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Palette.card, in: .rect(cornerRadius: 20))
    }

    private func badge(_ text: String, color: Color, icon: String? = nil) -> some View {
        HStack(spacing: 4) {
            if let icon { Image(systemName: icon).font(.caption2) }
            Text(text).font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.14), in: .capsule)
        .foregroundStyle(color)
    }
}

// MARK: - Books in a series

struct SeriesDetailView: View {
    @EnvironmentObject private var store: ContentStore
    let series: Series
    @State private var confirmReset = false

    private var books: [Book] { series.bookIDs.compactMap { store.book(id: $0) } }

    private var hasProgress: Bool {
        books.contains { store.chaptersRead(in: $0) > 0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(store.s(series.tagline))
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Label(store.s("readInOrder"), systemImage: "arrow.down.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Palette.card, in: .rect(cornerRadius: 14))

                if books.isEmpty {
                    ContentUnavailableView(store.s("notWritten"), systemImage: "pencil.and.scribble",
                                           description: Text(store.s("inProgress")))
                        .padding(.top, 40)
                } else {
                    ForEach(Array(books.enumerated()), id: \.element.id) { i, book in
                        NavigationLink(value: book) {
                            BookRow(book: book, index: i,
                                    color: series.palette[min(i, series.palette.count - 1)])
                        }
                        .buttonStyle(.plain)
                        .staggered(i + 1)
                    }

                }
            }
            .readingWidth()
            .padding(.horizontal, 18)
            .padding(.bottom, 26)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.grouped)
        .navigationTitle(series.title)
        .largeTitle()
        .toolbar {
            if hasProgress {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(role: .destructive) {
                            confirmReset = true
                        } label: {
                            Text(store.s("resetSeries"))
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .menuIndicator(.hidden)
                    .tint(Color.primary)
                }
            }
        }
        // A system .alert renders its buttons with AppKit styling and ignores
        // .tint, so Cancel always came out accent-coloured. This is ours.
        .overlay {
            if confirmReset {
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { confirmReset = false }

                    VStack(spacing: 18) {
                        Text(store.s("resetConfirm"))
                            .font(.system(.headline, design: .serif))
                            .multilineTextAlignment(.center)

                        HStack(spacing: 12) {
                            Button(store.s("cancel")) {
                                confirmReset = false
                            }
                            .buttonStyle(SquircleButtonStyle(tint: .primary))

                            Button(store.s("reset")) {
                                for id in series.bookIDs { store.progress[id] = 0 }
                                if let last = store.lastRead,
                                   series.bookIDs.contains(last.bookID) {
                                    store.lastRead = nil
                                }
                                confirmReset = false
                            }
                            .buttonStyle(SquircleButtonStyle(prominent: true, tint: .red))
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: 340)
                    .background(Palette.card, in: .rect(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 30, y: 12)
                }
                .transition(.opacity)
            }
        }
        .animation(.smooth(duration: 0.2), value: confirmReset)
    }
}

struct BookRow: View {
    @EnvironmentObject private var store: ContentStore
    let book: Book
    let index: Int
    let color: Color

    /// Falls back to the German blurb from books.json if no translation exists.
    private var localizedBlurb: String {
        let key = "blurb_\(book.id)"
        let hit = store.s(key)
        return hit == key ? book.blurb : hit
    }

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            CoverArt(title: book.title, level: book.level, index: index, base: color, width: 68)

            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(.primary)
                Text(localizedBlurb)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                let read = store.chaptersRead(in: book)
                HStack(spacing: 9) {
                    ProgressView(value: store.fraction(of: book)).tint(Palette.brand)
                    Text(read == 0 ? "\(book.chapters.count) \(store.s("chapters"))"
                                   : "\(read)/\(book.chapters.count)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Palette.card, in: .rect(cornerRadius: 18))
    }
}
