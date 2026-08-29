//
//  CampFocusCard.swift
//  CampExperts
//
//  The pause before the plunge. A first pinch swells a camp's lens
//  forward and this card presents it — name, place, and the traits a
//  family actually weighs (who it's for, what kind of camp, its rhythm,
//  its values) — with plain words for what a pinch does next. Nothing
//  plays until the second, confirming pinch.
//

import SwiftUI

struct CampFocusCard: View {

    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            if let camp = model.focusedCamp {
                VStack(spacing: 18) {
                    VStack(spacing: 6) {
                        Text(camp.name)
                            .font(.system(size: 40, weight: .semibold))
                            .tracking(0.5)
                            .foregroundStyle(Design.labelPrimary)
                        Text(camp.place.uppercased())
                            .font(.system(size: 16, weight: .medium))
                            .tracking(3.2)
                            .foregroundStyle(Design.labelSecondary)
                    }

                    HStack(spacing: 10) {
                        chip(camp.gender)
                        chip(camp.style)
                        if camp.religion.localizedCaseInsensitiveContains("jewish") {
                            chip("Jewish values")
                        }
                        chip(camp.sessions)
                    }

                    Text("PINCH THE CAMP TO STEP INSIDE   ·   PINCH ANYWHERE ELSE FOR THE MAP")
                        .font(.system(size: 14, weight: .medium))
                        .tracking(2.4)
                        .foregroundStyle(Design.labelSecondary.opacity(0.85))
                        .padding(.top, 2)
                }
                .padding(.horizontal, 44)
                .padding(.vertical, 32)
                .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 30))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Design.labelSecondary.opacity(0.25), lineWidth: 1))
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: model.focusedCamp)
        .allowsHitTesting(false)
    }

    private func chip(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Design.labelPrimary.opacity(0.9))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Design.labelSecondary.opacity(0.16), in: Capsule())
    }
}
