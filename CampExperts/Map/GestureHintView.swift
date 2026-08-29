//
//  GestureHintView.swift
//  CampExperts
//
//  The only two sentences a first-time wearer ever needs, shown
//  briefly and never again in the same breath: how to skip the reel
//  (which is really a pinch lesson with a visible reward) and how to
//  come home from a film. Nobody at a camp expo knows what "pinch"
//  means — so say it in fingers, not jargon.
//

import SwiftUI

struct GestureHintView: View {

    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            if model.introHintVisible {
                caption("TRY IT — TAP YOUR THUMB AND FINGER TOGETHER TO SKIP AHEAD")
            } else if model.filmHintVisible {
                caption("TAP YOUR THUMB AND FINGER TOGETHER ANYTIME TO COME BACK")
            }
        }
        .animation(.easeInOut(duration: 0.7),
                   value: model.introHintVisible || model.filmHintVisible)
        .allowsHitTesting(false)
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 22, weight: .semibold))
            .tracking(2.0)
            .foregroundStyle(Design.labelPrimary)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(.black.opacity(0.55), in: Capsule())
            .transition(.opacity)
    }
}
