//
//  AppModel.swift
//  CampExperts
//
//  The one state machine. Every phase change flows through here, so the
//  choreography in Transport.swift can never fight itself: taps are
//  meaningful only in the phase they belong to, and each journey runs
//  to completion.
//

import SwiftUI
import RealityKit
import Observation

@MainActor
@Observable
final class AppModel {

    enum Phase: Equatable {
        case boot
        case map
        case transporting(Camp)
        case visiting(Camp)
        case returning
    }

    /// Written only by the choreography in Transport.swift.
    var phase: Phase = .boot

    // The Canvas map and the labels live in SwiftUI attachment views;
    // driving their visibility from observable state keeps those fades in
    // SwiftUI, where they are guaranteed to composite correctly.
    var mapVisible = false
    var labelsVisible = false

    let loops = ProxyLoopPool()
    let idle = IdleEngine()
    let ambience = AmbienceEngine()
    let aiv = ImmersivePlayer()

    var anchors: SceneAnchors?
    var visitStartedAt: Date?

    init() {
        idle.onChoose = { [weak self] camp in
            self?.beginTransport(to: camp)
        }
    }

    // MARK: - Scene lifecycle

    func sceneReady(_ anchors: SceneAnchors) {
        guard self.anchors == nil else { return }
        self.anchors = anchors
        Task { await bootIn() }
    }

    func sceneClosed() {
        idle.cancel()
        loops.pauseAll()
        aiv.teardown()
    }

    // MARK: - Input

    func lensTapped(id: String) {
        guard case .map = phase, let camp = CampCatalog.camp(id) else { return }
        beginTransport(to: camp)
    }

    /// A pinch that missed every lens.
    func shellTapped() {
        switch phase {
        case .map:
            // A person is here and browsing; give them the full clock.
            idle.arm()
        case .visiting:
            guard let started = visitStartedAt,
                  Date().timeIntervalSince(started) > Design.returnGrace
            else { return }
            beginReturn()
        default:
            break
        }
    }
}
