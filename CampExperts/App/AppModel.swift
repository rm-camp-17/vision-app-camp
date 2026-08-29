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
import os

/// Booth diagnostics: `log stream --predicate 'subsystem == "com.campexperts.threshold"'`
let flowLog = Logger(subsystem: "com.campexperts.threshold", category: "flow")

@MainActor
@Observable
final class AppModel {

    enum Phase: Equatable {
        case boot
        case attract          // dark and quiet; waiting for the next guest
        case intro            // the welcome reel is playing
        case map
        case focused(Camp)    // one camp swelled forward, card showing
        case transporting(Camp)
        case visiting(Camp)
        case returning
    }

    /// Written only by the choreography in Transport.swift.
    var phase: Phase = .boot

    /// Camp visits completed by the current guest. At
    /// `Design.visitsPerGuest` the return goes to `.attract` instead of
    /// the map, and the space waits for the next family.
    var visitsThisGuest = 0
    var introStartedAt: Date?

    /// The camp currently presented on the focus card (drives the card's
    /// SwiftUI content and visibility).
    var focusedCamp: Camp?
    @ObservationIgnored var focusTimeoutTask: Task<Void, Never>?

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

    /// The space was dismissed (menu, crown). Its whole entity graph is
    /// gone; a reopen builds a new one and hands it to `sceneReady`.
    /// Forget everything scene-bound so that path boots the journey
    /// fresh — a booth reopens on the welcome, never on someone else's
    /// moment.
    func sceneClosed() {
        idle.cancel()
        focusTimeoutTask?.cancel()
        loops.pauseAll()
        aiv.teardown()
        ambience.stopIntroAudio(over: 0.1)
        focusedCamp = nil
        visitsThisGuest = 0
        introStartedAt = nil
        mapVisible = false
        labelsVisible = false
        anchors = nil
        phase = .boot
    }

    // MARK: - Input

    func lensTapped(id: String) {
        guard let camp = CampCatalog.camp(id) else { return }
        switch phase {
        case .map:
            // First pinch presents; it never plunges.
            focusCamp(camp)
        case .focused(let current) where current.id == camp.id:
            // The confirming pinch on the swelled lens: enter.
            beginTransport(to: camp)
        case .focused:
            // A different lens: switch the presentation over.
            focusCamp(camp)
        default:
            break
        }
    }

    /// A pinch that missed every lens.
    func shellTapped() {
        switch phase {
        case .attract:
            // A guest is here (or an operator is testing): wake up.
            beginIntro()
        case .intro:
            // A deliberate pinch skips the reel — but not in the first
            // moments, so a stray confirm never robs the welcome.
            guard let started = introStartedAt,
                  Date().timeIntervalSince(started) > Design.introSkipGrace
            else { return }
            finishIntro()
        case .map:
            // A person is here and browsing; give them the full clock.
            idle.arm()
        case .focused:
            // A pinch away from the lens is "not this one" — back to the map.
            unfocus()
        case .visiting:
            guard let started = visitStartedAt,
                  Date().timeIntervalSince(started) > Design.returnGrace
            else { return }
            beginReturn()
        default:
            break
        }
    }

    // MARK: - Headset on / off

    /// visionOS deactivates the scene when the headset comes off and
    /// reactivates it when the next guest puts it on. Donning from the
    /// waiting state starts the welcome reel; removal mid-journey resets
    /// so the next family never starts in the middle of someone else's
    /// visit. (Removal mid-crossing lets the crossing land in `.visiting`
    /// first; the subsequent deactivation-reset is caught on re-don via
    /// the `.attract` check in the operator flow.)
    func scenePhaseChanged(isActive: Bool) {
        if isActive {
            switch phase {
            case .attract:
                beginIntro()
            case .boot:
                break   // first launch; bootIn owns the opening
            default:
                // Reopened from the menu (or resumed after a suspension
                // that never delivered the inactive callback): a booth
                // never resumes someone else's moment. Fresh welcome.
                flowLog.info("reactivated mid-journey; restarting from the welcome")
                resetForNextGuest()
                beginIntro()
            }
        } else {
            switch phase {
            case .map, .focused, .visiting, .intro:
                resetForNextGuest()
            default:
                break
            }
        }
    }
}
