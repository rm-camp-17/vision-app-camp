//
//  Transport.swift
//  CampExperts
//
//  The choreography. Three journeys — boot, the crossing, the return —
//  written as explicit, linear timelines so every beat is visible and
//  tunable. This file is the emotional payload of the app; treat edits
//  to it like edits to a film cut.
//

import Foundation
import RealityKit
import simd

extension AppModel {

    // MARK: - Boot: the room finds its light

    func bootIn() async {
        ambience.startBed()
        trace("bootIn: anchors ready, lenses=\(self.anchors?.lensRoots.count ?? -1)")
        try? await Task.sleep(for: .seconds(Design.bootBeat))
        beginIntro()
    }

    // MARK: - The welcome: the reel that greets a new guest

    /// Plays the Camp Experts highlight reel, then opens the map. If the
    /// intro media isn't bundled, the map opens directly — the intro is
    /// optional like every other asset.
    func beginIntro() {
        trace("beginIntro from \(String(describing: self.phase))")
        guard phase == .boot || phase == .attract, anchors != nil else { return }

        let playerEntity = aiv.makeEntity(for: CampCatalog.intro) { [weak self] in
            self?.finishIntro()
        }
        guard let playerEntity, let anchors else {
            phase = .intro
            Task { await bootMapIn() }
            return
        }

        phase = .intro
        introStartedAt = Date()
        levelStage()
        ambience.duckBed()
        anchors.playerHost.addChild(playerEntity)
        aiv.play()
        // The reel is delivered silent; its soundtrack rides alongside.
        ambience.startIntroAudio()
        playerEntity.fade(to: 1, duration: Design.introFade)

        // Gesture school, disguised as a skip button: the first pinch a
        // guest ever makes is rewarded with visible control.
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(Design.introHintAt))
            guard let self, case .intro = self.phase else { return }
            self.introHintVisible = true
            try? await Task.sleep(for: .seconds(Design.hintLinger))
            self.introHintVisible = false
        }
    }

    /// The reel ended (or a settled guest pinched past it): fade down,
    /// hold the dark, open the map.
    func finishIntro() {
        trace("finishIntro from \(String(describing: self.phase))")
        guard case .intro = phase else { return }
        introStartedAt = nil
        introHintVisible = false
        Task {
            aiv.entity?.fade(to: 0, duration: Design.introFade)
            ambience.stopIntroAudio(over: Design.introFade)
            try? await Task.sleep(for: .seconds(Design.introFade))
            aiv.teardown()
            try? await Task.sleep(for: .seconds(Design.darkHold))
            await bootMapIn()
        }
    }

    // MARK: - The map arrives

    private func bootMapIn() async {
        trace("bootMapIn")
        guard let anchors else { return }
        levelStage()
        anchors.mapRoot.isEnabled = true
        ambience.liftBed()
        mapVisible = true   // the coastline breathes in

        try? await Task.sleep(for: .seconds(0.5))
        loops.playAll()

        // Lenses arrive west to east — a slow sweep of lights coming on.
        // Roots too: after a guest reset they were exhaled to zero.
        let ordered = CampCatalog.all.sorted { $0.longitude < $1.longitude }
        for camp in ordered {
            anchors.lensRoots[camp.id]?.fade(to: 1, duration: Design.bootLensFade)
            anchors.lensDiscs[camp.id]?.fade(to: 1, duration: Design.bootLensFade)
            try? await Task.sleep(for: .seconds(Design.bootLensStagger))
        }

        try? await Task.sleep(for: .seconds(0.4))
        labelsVisible = true
        phase = .map
        trace("map phase reached; mapVisible=\(self.mapVisible)")
        idle.arm()
    }

    // MARK: - Eye level

    /// Shift the whole browsing stage so its authored eye line sits at
    /// this guest's eyes. Only ever called while the stage is dark or
    /// about to fade in, so the move is never seen.
    func levelStage() {
        guard let anchors, let eye = head.eyeHeight() else { return }
        let clamped = min(max(eye, 0.9), 2.0)
        anchors.stage.position.y = clamped - Design.designEyeHeight
        trace("stage leveled: eye \(String(format: "%.2f", eye)) m")
    }

    // MARK: - Browse mode: geography, or the traits parents shop by

    /// Swap the map's presentation. Geography is the resting default;
    /// the attribute view dims the geography to a backdrop and raises
    /// the grouped lists. Both feed the same focus flow.
    func setBrowseMode(_ mode: BrowseMode) {
        guard browseMode != mode, let anchors else { return }
        if case .focused = phase { unfocus() }
        guard case .map = phase else { return }
        trace("browse mode: \(String(describing: mode))")
        browseMode = mode

        let lensTarget: Float = (mode == .attributes) ? 0.08 : 1.0
        for (_, lens) in anchors.lensRoots {
            lens.fade(to: lensTarget, duration: 0.5)
        }
        labelsVisible = (mode == .geography)
        idle.arm()
    }

    // MARK: - Reset: the space goes quiet for the next family

    /// After the last visit of a guest's journey (or the headset coming
    /// off), everything fades and the space waits in the dark. The next
    /// don of the headset — or a pinch — begins the welcome again.
    func resetForNextGuest() {
        guard let anchors else { return }
        visitsThisGuest = 0
        visitedCampNames = []
        introStartedAt = nil
        focusTimeoutTask?.cancel()
        focusedCamp = nil
        focusIsSuggestion = false
        introHintVisible = false
        filmHintVisible = false
        browseMode = .geography
        lang = .en
        idle.cancel()
        aiv.teardown()

        labelsVisible = false
        mapVisible = false
        for (_, lens) in anchors.lensRoots {
            lens.fade(to: 0, duration: Design.otherLensesExhale)
        }
        for (id, home) in anchors.homeTransforms {
            anchors.lensRoots[id]?.transform = home
        }
        loops.pauseAll()
        ambience.duckBed()
        ambience.stopIntroAudio(over: 0.3)
        // mapRoot stays enabled: the brand mark keeps a faint ember
        // presence during attract. Phase guards make lenses inert.
        phase = .attract
    }

    // MARK: - Focus: the pause before the plunge

    /// The idle clock's pick arrives as a suggestion: same presentation,
    /// but staying silent lets the space carry you in (and that visit
    /// doesn't count against the guest's three).
    func suggestCamp(_ camp: Camp) {
        guard case .map = phase else { return }
        focusCamp(camp, asSuggestion: true)
    }

    /// Swell one camp toward the visitor and present its card. The rest
    /// of the map recedes but stays present — this is consideration, not
    /// commitment.
    func focusCamp(_ camp: Camp, asSuggestion: Bool = false) {
        guard let anchors else { return }
        switch phase {
        case .map, .focused: break
        default: return
        }

        // Returning a previously focused lens home first (switching).
        if case .focused(let previous) = phase, previous.id != camp.id,
           let home = anchors.homeTransforms[previous.id] {
            anchors.lensRoots[previous.id]?.move(
                to: home, relativeTo: anchors.mapRoot,
                duration: Design.focusMove, timingFunction: .easeInOut)
        }

        trace("focus \(camp.id) suggestion=\(asSuggestion)")
        phase = .focused(camp)
        focusedCamp = camp
        focusIsSuggestion = asSuggestion
        idle.cancel()

        let restingDim: Float = (browseMode == .attributes)
            ? 0.08 : Design.focusDimOpacity
        for (id, lens) in anchors.lensRoots where id != camp.id {
            lens.fade(to: restingDim, duration: Design.focusMove)
        }
        if let chosen = anchors.lensRoots[camp.id],
           let home = anchors.homeTransforms[camp.id] {
            chosen.fade(to: 1, duration: Design.focusMove)
            anchors.lensRings[camp.id]?.fade(to: 0.7, duration: Design.focusMove)
            let spot = anchors.mapRoot.convert(position: Design.lensFocusPoint,
                                               from: anchors.stage)
            var target = home
            target.translation = spot
            target.scale = SIMD3(repeating: Design.lensFocusScale)
            chosen.move(to: target, relativeTo: anchors.mapRoot,
                        duration: Design.focusMove, timingFunction: .easeInOut)
        }

        // A guest's own pick left alone folds home; the space's
        // suggestion left alone carries the guest in — the card's
        // "pinch anywhere else" line is the standing invitation to
        // decline either.
        let dwell = asSuggestion ? Design.suggestionDwell : Design.focusTimeout
        focusTimeoutTask?.cancel()
        focusTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(dwell))
            guard !Task.isCancelled, let self,
                  case .focused(let held) = self.phase, held.id == camp.id
            else { return }
            if self.focusIsSuggestion {
                self.beginTransport(to: camp, countsAsVisit: false)
            } else {
                self.unfocus()
            }
        }
    }

    /// "Not this one": the lens sails home, the map breathes back.
    func unfocus() {
        guard case .focused(let camp) = phase, let anchors else { return }
        trace("unfocus")
        focusTimeoutTask?.cancel()
        focusedCamp = nil
        focusIsSuggestion = false
        phase = .map

        if let home = anchors.homeTransforms[camp.id] {
            anchors.lensRoots[camp.id]?.move(
                to: home, relativeTo: anchors.mapRoot,
                duration: Design.focusMove, timingFunction: .easeInOut)
        }
        anchors.lensRings[camp.id]?.fade(to: 0, duration: Design.focusMove)
        let resting: Float = (browseMode == .attributes) ? 0.08 : 1.0
        for (_, lens) in anchors.lensRoots {
            lens.fade(to: resting, duration: Design.focusMove)
        }
        idle.arm()
    }

    // MARK: - The crossing: map dissolves, place opens

    func beginTransport(to camp: Camp, countsAsVisit: Bool = true) {
        switch phase {
        case .map, .focused: break
        default: return
        }
        guard anchors != nil else { return }
        focusTimeoutTask?.cancel()
        focusedCamp = nil
        focusIsSuggestion = false
        // Whatever view chose this camp, the return lands on the map —
        // geography is where "you are here" makes sense after a visit.
        browseMode = .geography
        phase = .transporting(camp)
        idle.cancel()
        Task { await crossThreshold(to: camp, countsAsVisit: countsAsVisit) }
    }

    private func crossThreshold(to camp: Camp, countsAsVisit: Bool) async {
        trace("crossing to \(camp.id) counts=\(countsAsVisit)")
        guard let anchors else { return }

        // Prepare the destination immediately. The file is local, so by the
        // time the dark holds, the first frame is ready.
        let playerEntity = aiv.makeEntity(for: camp) { [weak self] in
            self?.beginReturn()
        }

        ambience.playSwell()
        ambience.duckBed()

        // Everything that is not the chosen camp exhales.
        labelsVisible = false
        mapVisible = false
        for (id, lens) in anchors.lensRoots where id != camp.id {
            lens.fade(to: 0, duration: Design.otherLensesExhale)
        }

        // The chosen lens comes to meet you.
        if let chosen = anchors.lensRoots[camp.id] {
            let approach = anchors.mapRoot.convert(position: Design.lensApproachPoint,
                                                   from: anchors.stage)
            var target = chosen.transform
            target.translation = approach
            target.scale = SIMD3(repeating: Design.lensApproachScale)
            chosen.move(to: target, relativeTo: anchors.mapRoot,
                        duration: Design.lensApproach, timingFunction: .easeInOut)
        }
        try? await Task.sleep(for: .seconds(Design.lensApproach))

        // ...and dissolves. What follows is a held beat of true dark:
        // the threshold itself.
        anchors.lensRoots[camp.id]?.fade(to: 0, duration: Design.lensDissolve)
        try? await Task.sleep(for: .seconds(Design.lensDissolve))

        anchors.mapRoot.isEnabled = false
        loops.pauseAll()
        if let home = anchors.homeTransforms[camp.id] {
            anchors.lensRoots[camp.id]?.transform = home   // reset while hidden
        }
        anchors.lensRings[camp.id]?.components.set(OpacityComponent(opacity: 0))

        try? await Task.sleep(for: .seconds(Design.darkHold))

        // A menu-reopen restart may have reset the journey while this
        // crossing was mid-flight; the fresh welcome owns the stage now.
        guard case .transporting = phase else { return }

        guard let playerEntity else {
            // No media for this camp yet — surface the map again rather
            // than strand a family in the dark.
            await restoreMap(around: camp)
            return
        }

        trace("playing \(camp.masterURL?.path(percentEncoded: false) ?? "nil"); available memory \(availableMemoryMB) MB")
        anchors.playerHost.addChild(playerEntity)
        aiv.play()
        playerEntity.fade(to: 1, duration: Design.sceneBloom)
        trace("player added and playing")
        visitStartedAt = Date()
        // The space's own suggestions don't spend the guest's visits.
        if countsAsVisit {
            visitsThisGuest += 1
            visitedCampNames.append(camp.name)
        }
        phase = .visiting(camp)

        // The only interface a film needs, briefly: the way home.
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(Design.filmHintAt))
            guard let self, case .visiting = self.phase else { return }
            self.filmHintVisible = true
            try? await Task.sleep(for: .seconds(Design.hintLinger))
            self.filmHintVisible = false
        }
    }

    // MARK: - The return: back to the map, exactly as it was left

    func beginReturn() {
        guard case .visiting(let camp) = phase else { return }
        trace("returning from \(camp.id)")
        filmHintVisible = false
        phase = .returning
        Task { await returnToMap(from: camp) }
    }

    private func returnToMap(from camp: Camp) async {
        aiv.entity?.fade(to: 0, duration: Design.sceneFade)
        await aiv.fadeOutAudio(over: Design.sceneFade)
        aiv.teardown()

        try? await Task.sleep(for: .seconds(Design.darkHold))

        // The last visit of this guest's journey ends with a goodbye,
        // not a blackout: the wordmark holds with the camps they saw,
        // then the space quiets for the next family.
        if visitsThisGuest >= Design.visitsPerGuest {
            await farewell()
            return
        }
        await restoreMap(around: camp)
    }

    /// The goodbye beat: dark stage, the brand and the guest's three
    /// camps, a nudge back to the humans at the booth.
    private func farewell() async {
        guard let anchors else { return }
        trace("farewell: \(self.visitedCampNames.joined(separator: ", "))")
        anchors.mapRoot.isEnabled = true   // the brand mark lives on it
        mapVisible = false
        labelsVisible = false
        phase = .farewell
        try? await Task.sleep(for: .seconds(Design.farewellHold))
        guard case .farewell = phase else { return }
        resetForNextGuest()
    }

    /// Bring the map back rippling outward from the camp just visited —
    /// the room remembers where you went.
    private func restoreMap(around camp: Camp) async {
        guard let anchors else { return }
        // A reset (doff, menu reopen) may have claimed the stage while
        // the return was mid-flight.
        switch phase {
        case .attract, .boot, .intro, .farewell: return
        default: break
        }
        levelStage()   // the guest may have sat down or stood up mid-film

        anchors.mapRoot.isEnabled = true
        loops.playAll()
        ambience.liftBed()
        mapVisible = true

        let origin = MapProjection.position(latitude: camp.latitude,
                                            longitude: camp.longitude)
        let rippleOrder = CampCatalog.all.sorted { a, b in
            let pa = MapProjection.position(latitude: a.latitude, longitude: a.longitude)
            let pb = MapProjection.position(latitude: b.latitude, longitude: b.longitude)
            return simd_length(pa - origin) < simd_length(pb - origin)
        }
        for visited in rippleOrder {
            anchors.lensRoots[visited.id]?.fade(to: 1, duration: Design.lensRippleDuration)
            anchors.lensDiscs[visited.id]?.fade(to: 1, duration: Design.lensRippleDuration)
            try? await Task.sleep(for: .seconds(Design.lensRippleStep))
        }

        try? await Task.sleep(for: .seconds(0.3))
        labelsVisible = true
        phase = .map
        idle.arm()
    }
}
