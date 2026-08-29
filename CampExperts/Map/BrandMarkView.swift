//
//  BrandMarkView.swift
//  CampExperts
//
//  The quiet wordmark above the map. Present, never loud — the brand is
//  the host of the room, not a billboard in it. The second line doubles
//  as the only instruction the experience needs.
//

import SwiftUI

struct BrandMarkView: View {

    @Environment(AppModel.self) private var model

    private var isAttract: Bool { model.phase == .attract }

    var body: some View {
        VStack(spacing: 10) {
            Text("CAMP EXPERTS")
                .font(.system(size: 44, weight: .semibold))
                .tracking(14)
                .foregroundStyle(Design.labelPrimary)
            Text(isAttract ? "PINCH TO BEGIN" : "LOOK AT A CAMP  ·  PINCH TO VISIT")
                .font(.system(size: 17, weight: .medium))
                .tracking(4)
                .foregroundStyle(Design.labelSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(width: 900)
        // Full presence over the map; a faint ember while the space
        // waits for the next guest, so the booth never looks dead.
        .opacity(model.mapVisible ? 1 : (isAttract ? 0.25 : 0))
        .animation(.easeInOut(duration: 0.9), value: model.mapVisible)
        .animation(.easeInOut(duration: 1.6), value: isAttract)
        .allowsHitTesting(false)
    }
}
