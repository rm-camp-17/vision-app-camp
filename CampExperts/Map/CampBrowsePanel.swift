//
//  CampBrowsePanel.swift
//  CampExperts
//
//  The second way in: camps grouped by the traits parents actually shop
//  by — kind of camp, session rhythm, who it's for, values. Geography
//  stays the default; this panel raises over a dimmed map when the
//  guest flips the toggle under the brand mark. Every name is a gaze
//  target feeding the same focus-card flow as a lens on the map.
//
//  Groups are derived from the catalog, so new camps and corrected
//  data sort themselves — nothing here is hand-maintained.
//

import SwiftUI

struct CampBrowsePanel: View {

    @Environment(AppModel.self) private var model

    private struct Section: Identifiable {
        let id: String        // title doubles as identity
        let title: String
        let camps: [Camp]
    }

    private static let sections: [Section] = {
        let all = CampCatalog.all
        func grab(_ title: String, _ include: (Camp) -> Bool) -> Section {
            Section(id: title, title: title, camps: all.filter(include))
        }
        let sports = grab("SPORTS & ACTION") {
            $0.style.localizedCaseInsensitiveContains("sport")
                || $0.style.localizedCaseInsensitiveContains("action")
        }
        let arts = grab("ARTS & CREATIVE") {
            $0.style.localizedCaseInsensitiveContains("arts")
                || $0.style.localizedCaseInsensitiveContains("hybrid")
        }
        let short = grab("SHORT & FLEXIBLE") {
            $0.sessions.hasPrefix("1") || $0.sessions.hasPrefix("2")
                || $0.sessions.localizedCaseInsensitiveContains("weekly")
        }
        let full = grab("FULL-SUMMER TRADITION") {
            $0.sessions.localizedCaseInsensitiveContains("full")
        }
        let single = grab("BOYS · GIRLS · SIBLINGS") { $0.gender != "Co-Ed" }
        let jewish = grab("JEWISH VALUES & TRADITIONS") {
            $0.religion.localizedCaseInsensitiveContains("jewish")
        }
        return [sports, arts, short, full, single, jewish]
    }()

    var body: some View {
        Grid(alignment: .topLeading, horizontalSpacing: 26, verticalSpacing: 26) {
            GridRow {
                ForEach(Self.sections.prefix(3)) { sectionBox($0) }
            }
            GridRow {
                ForEach(Self.sections.dropFirst(3)) { sectionBox($0) }
            }
        }
        .padding(30)
        .opacity(visible ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: visible)
        .allowsHitTesting(visible)
    }

    private var visible: Bool {
        model.browseMode == .attributes && model.mapVisible
            && model.focusedCamp == nil
    }

    private func sectionBox(_ section: Section) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.title)
                .font(.system(size: 19, weight: .semibold))
                .tracking(2.8)
                .foregroundStyle(Design.labelSecondary)
                .padding(.bottom, 2)
            ForEach(section.camps) { camp in
                Button {
                    model.lensTapped(id: camp.id)
                } label: {
                    Text(camp.name)
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(Design.labelPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .hoverEffect()
            }
        }
        .frame(width: 560, alignment: .topLeading)
        .padding(24)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Design.labelSecondary.opacity(0.18), lineWidth: 1))
    }
}
