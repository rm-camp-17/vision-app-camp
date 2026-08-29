//
//  CampExpertsApp.swift
//  CampExperts
//
//  The app is the threshold: it launches straight into its one immersive
//  space. Two Info.plist keys make that possible — multiple scenes enabled
//  (immersive playback silently fails without it) and the immersive scene
//  session role preferred at launch (no window, no chrome, no taps between
//  a family and the map).
//
//  Progressive immersion is the contract for Apple Immersive Video on
//  visionOS 26: the dome envelops most of the view, and the Digital Crown
//  always hands control of "how much world" back to the person wearing
//  the device.
//

import SwiftUI

@main
struct CampExpertsApp: App {

    @State private var model = AppModel()
    @State private var immersion: ImmersionStyle = .progressive(
        Design.immersionRange, initialAmount: Design.immersionInitial)
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        ImmersiveSpace(id: "threshold") {
            ThresholdSpaceView()
                .environment(model)
                // The headset coming off deactivates the scene; the next
                // guest putting it on reactivates it. That transition is
                // the booth's whole session model: don → welcome reel,
                // doff → reset for the next family.
                .onChange(of: scenePhase) { _, newPhase in
                    model.scenePhaseChanged(isActive: newPhase == .active)
                }
        }
        .immersionStyle(
            selection: $immersion,
            in: .progressive(Design.immersionRange,
                             initialAmount: Design.immersionInitial))
    }
}
