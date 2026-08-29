//
//  BrandMarkView.swift
//  CampExperts
//
//  The quiet wordmark above the map — host of the room, never a
//  billboard. It carries the one instruction the map needs, the
//  browse-mode toggle, a faint ember while the space waits, and the
//  goodbye after a guest's last visit.
//

import SwiftUI

struct BrandMarkView: View {

    @Environment(AppModel.self) private var model

    private var isAttract: Bool { model.phase == .attract }
    private var isFarewell: Bool { model.phase == .farewell }

    var body: some View {
        VStack(spacing: 12) {
            Text("CAMP EXPERTS")
                .font(.system(size: 44, weight: .semibold))
                .tracking(14)
                .foregroundStyle(Design.labelPrimary)
                .allowsHitTesting(false)

            if isFarewell {
                VStack(spacing: 10) {
                    Text("THAT WAS YOUR THREE CAMPS")
                        .font(.system(size: 20, weight: .semibold))
                        .tracking(4)
                        .foregroundStyle(Design.labelPrimary)
                    if !model.visitedCampNames.isEmpty {
                        Text(model.visitedCampNames.joined(separator: "  ·  ").uppercased())
                            .font(.system(size: 15, weight: .medium))
                            .tracking(2.4)
                            .foregroundStyle(Design.labelSecondary)
                    }
                    Text("HAND THE HEADSET BACK — LET'S FIND YOURS")
                        .font(.system(size: 16, weight: .medium))
                        .tracking(3)
                        .foregroundStyle(Design.labelSecondary)
                }
                .allowsHitTesting(false)
            } else {
                Text(isAttract
                     ? "TAP YOUR THUMB AND FINGER TOGETHER TO BEGIN"
                     : "LOOK AT A CAMP — TAP YOUR THUMB AND FINGER TOGETHER TO VISIT")
                    .font(.system(size: 17, weight: .medium))
                    .tracking(4)
                    .foregroundStyle(Design.labelSecondary)
                    .opacity(isAttract ? 1 : 1)
                    .allowsHitTesting(false)

                // The browse toggle: geography is home; the second view
                // regroups the same camps by what a family is looking for.
                if !isAttract {
                    HStack(spacing: 12) {
                        toggleButton("BY MAP", .geography)
                        toggleButton("BY CAMP TYPE", .attributes)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(width: 1100)
        // Full presence over the map; a faint ember while the space
        // waits; the goodbye holds bright on its own dark stage.
        .opacity(model.mapVisible ? 1 : (isAttract ? 0.25 : (isFarewell ? 1 : 0)))
        .animation(.easeInOut(duration: 0.9), value: model.mapVisible)
        .animation(.easeInOut(duration: 1.6), value: isAttract)
        .animation(.easeInOut(duration: 0.9), value: isFarewell)
    }

    private func toggleButton(_ label: String, _ mode: AppModel.BrowseMode) -> some View {
        let active = model.browseMode == mode
        return Button {
            model.setBrowseMode(mode)
        } label: {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .tracking(2.6)
                .foregroundStyle(active ? Color.black.opacity(0.85) : Design.labelPrimary)
                .padding(.horizontal, 22)
                .padding(.vertical, 10)
                .background(active ? AnyShapeStyle(Design.labelPrimary)
                                   : AnyShapeStyle(Color.white.opacity(0.10)),
                            in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .hoverEffect()
    }
}
