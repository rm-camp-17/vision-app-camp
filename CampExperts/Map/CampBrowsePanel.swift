//
//  CampBrowsePanel.swift
//  CampExperts
//
//  The second way in: camps grouped by the questions parents actually
//  ask, one column per question —
//
//    WHAT KIND?    Traditional (the heart of the catalog),
//                  with Sports and Arts as their own answers
//    HOW LONG?     Short & flexible sessions
//    WHAT VALUES?  Jewish values & traditions
//    WHO IS IT FOR? All-boys, all-girls, and brother-&-sister camps,
//                  each its own group — never mixed
//
//  A camp may appear under every question it answers; that's how
//  shopping works. Groups derive from catalog data, so corrections
//  sort themselves. Every name feeds the same focus-card flow as a
//  lens on the map.
//

import SwiftUI

struct CampBrowsePanel: View {

    @Environment(AppModel.self) private var model

    private struct Section {
        let title: (Lang) -> String
        let camps: [Camp]
    }

    private static let all = CampCatalog.all

    private static let traditional = Section(
        title: Loc.sectionTraditional,
        camps: all.filter { $0.style.localizedCaseInsensitiveContains("traditional") })
    private static let sports = Section(
        title: Loc.sectionSports,
        camps: all.filter {
            $0.style.localizedCaseInsensitiveContains("sport")
                || $0.style.localizedCaseInsensitiveContains("action") })
    private static let arts = Section(
        title: Loc.sectionArts,
        camps: all.filter {
            $0.style.localizedCaseInsensitiveContains("arts")
                || $0.style.localizedCaseInsensitiveContains("hybrid") })
    private static let short = Section(
        title: Loc.sectionShort,
        camps: all.filter {
            $0.sessions.hasPrefix("1") || $0.sessions.hasPrefix("2")
                || $0.sessions.localizedCaseInsensitiveContains("weekly") })
    private static let jewish = Section(
        title: Loc.sectionJewish,
        camps: all.filter { $0.religion.localizedCaseInsensitiveContains("jewish") })
    private static let boys = Section(
        title: Loc.sectionBoys,
        camps: all.filter { $0.gender == "All Boys" })
    private static let girls = Section(
        title: Loc.sectionGirls,
        camps: all.filter { $0.gender == "All Girls" })
    private static let siblings = Section(
        title: Loc.sectionSiblings,
        camps: all.filter { $0.gender == "Brother/Sister" })

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            // WHAT KIND — the heart of the catalog first.
            column { sectionBox(Self.traditional) }
            // HOW LONG.
            column { sectionBox(Self.short) }
            // INTERESTS & VALUES.
            column {
                sectionBox(Self.sports)
                sectionBox(Self.arts)
                sectionBox(Self.jewish)
            }
            // WHO IT'S FOR — three groups, never mixed.
            column {
                sectionBox(Self.boys)
                sectionBox(Self.girls)
                sectionBox(Self.siblings)
            }
        }
        .padding(28)
        .opacity(visible ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: visible)
        .allowsHitTesting(visible)
    }

    private var visible: Bool {
        model.browseMode == .attributes && model.mapVisible
            && model.focusedCamp == nil
    }

    private func column(@ViewBuilder _ content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            content()
            Spacer(minLength: 0)
        }
    }

    private func sectionBox(_ section: Section) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title(model.lang))
                .font(.system(size: 18, weight: .semibold))
                .tracking(2.6)
                .foregroundStyle(Design.labelSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.bottom, 2)
            ForEach(section.camps) { camp in
                Button {
                    model.lensTapped(id: camp.id)
                } label: {
                    Text(camp.name)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Design.labelPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .hoverEffect()
            }
        }
        .frame(width: 430, alignment: .topLeading)
        .padding(22)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Design.labelSecondary.opacity(0.18), lineWidth: 1))
    }
}
