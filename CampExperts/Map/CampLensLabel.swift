//
//  CampLensLabel.swift
//  CampExperts
//
//  The two quiet lines beneath each lens. Always present, never loud —
//  the answer to a gaze is the lens itself brightening under the system's
//  hover effect, which runs out-of-process and never tells the app where
//  anyone is looking.
//

import SwiftUI

struct CampLensLabel: View {

    let camp: Camp
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 3) {
            Text(camp.name)
                .font(.system(size: 20, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(Design.labelPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(camp.place.uppercased())
                .font(.system(size: 12, weight: .medium))
                .tracking(2.2)
                .foregroundStyle(Design.labelSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .multilineTextAlignment(.center)
        .frame(width: 250)
        // Hidden while this camp is focused — the swelled lens would
        // dwarf it, and the card carries the identity instead.
        .opacity(model.labelsVisible && model.focusedCamp?.id != camp.id ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: model.labelsVisible)
        .animation(.easeInOut(duration: 0.3), value: model.focusedCamp)
        .allowsHitTesting(false)
    }
}
