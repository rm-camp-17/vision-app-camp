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
        VStack(spacing: 16) {
            Group {
                if model.introHintVisible {
                    caption(Loc.skipHint(model.lang))
                } else if model.filmHintVisible {
                    caption(Loc.returnHint(model.lang))
                }
            }
            .allowsHitTesting(false)

            // The only way past the welcome reel: a deliberate look-and-pinch
            // on this button. Stray pinches (a new guest finding their hands)
            // do nothing, so every family sees the reel.
            if model.skipVisible && model.phase == .intro {
                Button { model.skipIntro() } label: {
                    Text(Loc.skipButton(model.lang))
                        .font(.system(size: 22, weight: .semibold))
                        .tracking(3)
                        .foregroundStyle(Design.labelPrimary)
                        .padding(.horizontal, 34)
                        .padding(.vertical, 16)
                        .background(.black.opacity(0.55), in: Capsule())
                        .overlay(Capsule().stroke(Design.ember.opacity(0.5), lineWidth: 1))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .hoverEffect()
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.7),
                   value: model.introHintVisible || model.filmHintVisible)
        .animation(.easeInOut(duration: 0.7), value: model.skipVisible)
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
