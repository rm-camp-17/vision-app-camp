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
        VStack(spacing: 4) {
            Text(camp.name)
                .font(.system(size: 24, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Design.labelPrimary)
            Text(camp.place.uppercased())
                .font(.system(size: 14, weight: .medium))
                .tracking(2.6)
                .foregroundStyle(Design.labelSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(width: 340)
        .opacity(model.labelsVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.5), value: model.labelsVisible)
        .allowsHitTesting(false)
    }
}
