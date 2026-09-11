//  Catalog.swift
//  Genres → Series → Books, CEFR levels, unlock rules, and cover art.

import SwiftUI

// MARK: - Level

enum Level: Int, CaseIterable, Identifiable, Codable {
    case a1 = 0, a2, b1, b2, c1

    var id: Int { rawValue }

    var code: String {
        switch self {
        case .a1: "A1"; case .a2: "A2"; case .b1: "B1"; case .b2: "B2"; case .c1: "C1"
        }
    }

    private var key: String {
        switch self {
        case .a1: "a1"; case .a2: "a2"; case .b1: "b1"; case .b2: "b2"; case .c1: "c1"
        }
    }

    func title(_ lang: String) -> String { L.t("lvl_\(key)_title", lang) }
    func blurb(_ lang: String) -> String { L.t("lvl_\(key)_blurb", lang) }
}

// MARK: - Genre & Series

struct Genre: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let symbol: String          // SF Symbol
    let tint: Color
    let series: [Series]
    let comingSoon: Bool
    /// Romance splits by pairing; other genres leave this empty.
    var pairings: [Pairing] = []

    var hasPairings: Bool { !pairings.isEmpty }
    var totalSeries: Int { series.count + pairings.reduce(0) { $0 + $1.series.count } }
}

/// Who the love story is between. Each pairing has its own shelf of series.
struct Pairing: Identifiable, Hashable {
    let id: String
    let label: String           // "M / W"
    let descriptionKey: String  // explained under the selector
    let series: [Series]
}

struct Series: Identifiable, Hashable {
    let id: String
    let title: String
    let tagline: String
    let startLevel: Level
    let endLevel: Level
    let bookIDs: [String]
    let palette: [Color]        // one gradient pair per book
    let available: Bool

    var levelRange: String {
        startLevel == endLevel ? startLevel.code : "\(startLevel.code) → \(endLevel.code)"
    }

    static func == (a: Series, b: Series) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

// MARK: - The catalog

enum Catalog {

    static let genres: [Genre] = [romance, comingMystery, comingFantasy, comingSciFi, comingHorror]

    static let romance = Genre(
        id: "romance",
        name: "genre_romance",
        subtitle: "genre_romance_sub",
        symbol: "heart.text.square.fill",
        tint: Color(red: 0.62, green: 0.33, blue: 0.52),
        series: [],                       // series live under the pairings
        comingSoon: false,
        pairings: [
            Pairing(id: "mw", label: "M / W", descriptionKey: "pair_mw_desc",
                    series: [dieAndereSeite, mwPlaceholderB2, mwPlaceholderC1]),
            Pairing(id: "mm", label: "M / M", descriptionKey: "pair_mm_desc",
                    series: [zwischenUns, nachDerStadt, letzteSprache]),
            Pairing(id: "ww", label: "W / W", descriptionKey: "pair_ww_desc",
                    series: [wwPlaceholderA2, wwPlaceholderB2, wwPlaceholderC1]),
        ]
    )

    // ---- M/W shelf (not written yet) ----
    static let dieAndereSeite = Series(
        id: "die-andere-seite", title: "Die andere Seite",
        tagline: "series_tbw_tag", startLevel: .a2, endLevel: .b2,
        bookIDs: [], palette: [Color(red: 0.34, green: 0.20, blue: 0.26)],
        available: false)

    static let mwPlaceholderB2 = Series(
        id: "mw-b2", title: "Zweimal im Jahr",
        tagline: "series_tbw_tag", startLevel: .b2, endLevel: .c1,
        bookIDs: [], palette: [Color(red: 0.28, green: 0.22, blue: 0.30)],
        available: false)

    static let mwPlaceholderC1 = Series(
        id: "mw-c1", title: "Was niemand sagt",
        tagline: "series_tbw_tag", startLevel: .c1, endLevel: .c1,
        bookIDs: [], palette: [Color(red: 0.24, green: 0.18, blue: 0.24)],
        available: false)

    // ---- W/W shelf (not written yet) ----
    static let wwPlaceholderA2 = Series(
        id: "ww-a2", title: "Der lange Sommer",
        tagline: "series_tbw_tag", startLevel: .a2, endLevel: .b2,
        bookIDs: [], palette: [Color(red: 0.20, green: 0.26, blue: 0.34)],
        available: false)

    static let wwPlaceholderB2 = Series(
        id: "ww-b2", title: "Nordlicht",
        tagline: "series_tbw_tag", startLevel: .b2, endLevel: .c1,
        bookIDs: [], palette: [Color(red: 0.18, green: 0.24, blue: 0.30)],
        available: false)

    static let wwPlaceholderC1 = Series(
        id: "ww-c1", title: "Alles offen",
        tagline: "series_tbw_tag", startLevel: .c1, endLevel: .c1,
        bookIDs: [], palette: [Color(red: 0.16, green: 0.20, blue: 0.26)],
        available: false)

    /// Series 1 — the written foundation. M/M shelf.
    static let zwischenUns = Series(
        id: "zwischen-uns",
        title: "Zwischen uns",
        tagline: "series_zu_tag",
        startLevel: .a2, endLevel: .b2,
        bookIDs: ["b1", "b2", "b3", "b4"],
        palette: [
            Color(red: 0.16, green: 0.17, blue: 0.34),   // night indigo
            Color(red: 0.13, green: 0.28, blue: 0.29),   // river green
            Color(red: 0.36, green: 0.21, blue: 0.16),   // autumn amber
            Color(red: 0.28, green: 0.24, blue: 0.20),   // aged paper
        ],
        available: true)

    /// Series 2 — B2 → C1. Not written yet.
    static let nachDerStadt = Series(
        id: "nach-der-stadt",
        title: "Nach der Stadt",
        tagline: "series_nds_tag",
        startLevel: .b2, endLevel: .c1,
        bookIDs: [],
        palette: [Color(red: 0.20, green: 0.22, blue: 0.30)],
        available: false
    )

    /// Series 3 — C1 throughout. Not written yet.
    static let letzteSprache = Series(
        id: "letzte-sprache",
        title: "Die letzte Sprache",
        tagline: "series_lls_tag",
        startLevel: .c1, endLevel: .c1,
        bookIDs: [],
        palette: [Color(red: 0.24, green: 0.18, blue: 0.22)],
        available: false
    )

    static let comingMystery = Genre(
        id: "mystery", name: "genre_mystery", subtitle: "comingSoon",
        symbol: "magnifyingglass.circle.fill",
        tint: Color(red: 0.30, green: 0.36, blue: 0.48),
        series: [], comingSoon: true)

    static let comingFantasy = Genre(
        id: "fantasy", name: "genre_fantasy", subtitle: "comingSoon",
        symbol: "sparkles",
        tint: Color(red: 0.42, green: 0.30, blue: 0.52),
        series: [], comingSoon: true)

    static let comingSciFi = Genre(
        id: "scifi", name: "genre_scifi", subtitle: "comingSoon",
        symbol: "circle.hexagongrid.fill",
        tint: Color(red: 0.24, green: 0.40, blue: 0.46),
        series: [], comingSoon: true)

    static let comingHorror = Genre(
        id: "horror", name: "genre_horror", subtitle: "comingSoon",
        symbol: "moon.stars.fill",
        tint: Color(red: 0.34, green: 0.26, blue: 0.26),
        series: [], comingSoon: true)

    static func series(id: String) -> Series? {
        let flat = genres.flatMap(\.series) + genres.flatMap(\.pairings).flatMap(\.series)
        return flat.first { $0.id == id }
    }
}

// MARK: - Cover art (replaces the emoji)

struct CoverArt: View {
    let title: String
    let level: String
    let index: Int
    let base: Color
    var width: CGFloat = 66

    private var height: CGFloat { width * 1.48 }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [base.opacity(0.95), base.opacity(0.62)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            // faint spine line
            HStack {
                Rectangle()
                    .fill(.white.opacity(0.16))
                    .frame(width: 1.2)
                    .padding(.leading, width * 0.13)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 3) {
                Spacer(minLength: 0)
                Text(title)
                    .font(.system(size: width * 0.145, weight: .semibold, design: .serif))
                    .foregroundStyle(.white.opacity(0.96))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.7)
                Text(level)
                    .font(.system(size: width * 0.105, weight: .bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(.horizontal, width * 0.19)
            .padding(.vertical, width * 0.14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

            // roman numeral, top right
            Text(romanNumeral(index + 1))
                .font(.system(size: width * 0.15, weight: .medium, design: .serif))
                .foregroundStyle(.white.opacity(0.42))
                .padding(width * 0.13)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .frame(width: width, height: height)
        .clipShape(.rect(cornerRadius: width * 0.09))
        .overlay(
            RoundedRectangle(cornerRadius: width * 0.09)
                .strokeBorder(.white.opacity(0.14), lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.24), radius: 7, x: 0, y: 4)
    }

    private func romanNumeral(_ n: Int) -> String {
        ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII"][min(n, 8)]
    }
}
