//  OnboardingView.swift
//  Three steps: mother tongue -> target language -> level.
//
//  Step 1 needs no translation: languages are listed as endonyms, and the
//  device's language is pre-selected. From step 2 on, we know their language
//  and speak it.

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: ContentStore

    @State private var path: [Int] = []
    @State private var mother: MotherTongue = Languages.deviceDefault
    @State private var target: String = "de"
    @State private var level: Level?

    private var lang: String { mother.code }

    var body: some View {
        NavigationStack(path: $path) {
            motherStep
                .navigationDestination(for: Int.self) { step in
                    if step == 1 { targetStep } else { levelStep }
                }
        }
        .frame(maxWidth: 460)                 // keeps it narrow on a Mac window
        .frame(maxWidth: .infinity)           // …and centred
        .background(Palette.page)             // bar and page share one colour
    }

    // MARK: Step 1 — mother tongue

    private var motherStep: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 34))
                    .foregroundStyle(.tint)
                    .padding(.top, 26)
                Text("Lesen")
                    .font(.system(size: 34, weight: .medium, design: .serif))
                Text("Sprache · Language")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 14)

            List {
                ForEach(Languages.motherTongues) { m in
                    Button {
                        mother = m
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
                            if m.code == mother.code {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Palette.brand)
                            }
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(m.code == mother.code
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
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .blendedToolbar()
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                path.append(1)
            } label: {
                Text(L.t("continueBtn", lang))
            }
            .buttonStyle(.squircleProminent)
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .background(Palette.page)
        }
    }

    // MARK: Step 2 — target language

    private var targetStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.t("chooseTarget", lang))
                        .font(.system(.largeTitle, design: .serif).weight(.medium))
                    Text(L.t("tagline", lang))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 26)

                VStack(spacing: 10) {
                    ForEach(Languages.targets) { t in
                        targetRow(t)
                    }
                }

            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
        .blendedToolbar()
        .safeAreaInset(edge: .bottom) {
            Button {
                path.append(2)
            } label: {
                Text(L.t("continueBtn", lang))
            }
            .buttonStyle(.squircleProminent)
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .background(Palette.page)
        }
    }

    private func targetRow(_ t: TargetLanguage) -> some View {
        let selected = t.code == target
        return Button {
            guard t.available else { return }
            withAnimation(.snappy(duration: 0.2)) { target = t.code }
        } label: {
            HStack(spacing: 14) {
                FlagMark(code: t.code, width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(t.endonym)
                        .font(.body.weight(.medium))
                        .foregroundStyle(t.available ? .primary : .secondary)
                    Text(t.available ? t.english
                                     : "\(t.english) · \(L.t("comingSoon", lang))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                } else if !t.available {
                    Image(systemName: "lock.fill").font(.footnote).foregroundStyle(.tertiary)
                }
            }
            .padding(15)
            .background(Palette.card, in: .rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(selected ? Palette.brand : .clear, lineWidth: 1.5)
            )
            .opacity(t.available ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!t.available)
    }

    // MARK: Step 3 — level

    private var levelStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L.t("chooseLevel", lang))
                        .font(.system(.largeTitle, design: .serif).weight(.medium))
                    Text(L.t("levelHint", lang))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 26)

                VStack(spacing: 10) {
                    ForEach(Level.allCases) { l in levelRow(l) }
                }

            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
        .blendedToolbar()
        .safeAreaInset(edge: .bottom) {
            Button {
                guard let level else { return }
                store.motherTongue = mother.code
                store.targetLanguage = target
                store.level = level
                withAnimation(.snappy) { store.hasOnboarded = true }
            } label: {
                Text(L.t("start", lang))
            }
            .buttonStyle(.squircleProminent)
            .disabled(level == nil)
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .background(Palette.page)
        }
    }

    private func levelRow(_ l: Level) -> some View {
        let selected = level == l
        return Button {
            withAnimation(.snappy(duration: 0.2)) { level = l }
        } label: {
            HStack(spacing: 14) {
                Text(l.code)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(selected ? .white : .primary)
                    .frame(width: 46, height: 38)
                    .background(selected ? AnyShapeStyle(Palette.brand)
                                         : AnyShapeStyle(Palette.fill),
                                in: .rect(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(l.title(lang)).font(.body.weight(.medium))
                    Text(l.blurb(lang)).font(.footnote).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if selected { Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint) }
            }
            .padding(14)
            .background(Palette.card, in: .rect(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(selected ? Palette.brand : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
