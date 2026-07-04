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
        guard let anchors else { return }
        ambience.startBed()

        try? await Task.sleep(for: .seconds(Design.bootBeat))
        mapVisible = true   // the coastline breathes in

        try? await Task.sleep(for: .seconds(0.5))
        loops.playAll()

        // Lenses arrive west to east — a slow sweep of lights coming on.
        let ordered = CampCatalog.all.sorted { $0.longitude < $1.longitude }
        for camp in ordered {
            anchors.lensDiscs[camp.id]?.fade(to: 1, duration: Design.bootLensFade)
            try? await Task.sleep(for: .seconds(Design.bootLensStagger))
        }

        try? await Task.sleep(for: .seconds(0.4))
        labelsVisible = true
        phase = .map
        idle.arm()
    }

    // MARK: - The crossing: map dissolves, place opens

    func beginTransport(to camp: Camp) {
        guard case .map = phase, anchors != nil else { return }
        phase = .transporting(camp)
        idle.cancel()
        Task { await crossThreshold(to: camp) }
    }

    private func crossThreshold(to camp: Camp) async {
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
                                                   from: nil)
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

        try? await Task.sleep(for: .seconds(Design.darkHold))

        guard let playerEntity else {
            // No media for this camp yet — surface the map again rather
            // than strand a family in the dark.
            await restoreMap(around: camp)
            return
        }

        anchors.playerHost.addChild(playerEntity)
        aiv.play()
        playerEntity.fade(to: 1, duration: Design.sceneBloom)
        visitStartedAt = Date()
        phase = .visiting(camp)
    }

    // MARK: - The return: back to the map, exactly as it was left

    func beginReturn() {
        guard case .visiting(let camp) = phase else { return }
        phase = .returning
        Task { await returnToMap(from: camp) }
    }

    private func returnToMap(from camp: Camp) async {
        aiv.entity?.fade(to: 0, duration: Design.sceneFade)
        await aiv.fadeOutAudio(over: Design.sceneFade)
        aiv.teardown()

        try? await Task.sleep(for: .seconds(Design.darkHold))
        await restoreMap(around: camp)
    }

    /// Bring the map back rippling outward from the camp just visited —
    /// the room remembers where you went.
    private func restoreMap(around camp: Camp) async {
        guard let anchors else { return }

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
