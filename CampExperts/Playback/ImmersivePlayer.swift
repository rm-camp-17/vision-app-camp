//
//  ImmersivePlayer.swift
//  CampExperts
//
//  Owns the one heavyweight player in the app: the Apple Immersive Video
//  master for the camp being visited. Created at selection, destroyed at
//  return, so the map's proxy loops and the 8K master never compete for
//  decoders.
//

import Foundation
import RealityKit
import AVFoundation

@MainActor
final class ImmersivePlayer {

    private(set) var entity: Entity?
    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?

    /// Builds the playback entity for a camp. The entity carries a
    /// VideoPlayerComponent in progressive immersive viewing mode: on
    /// visionOS 26, RealityKit renders Apple Immersive Video (.aivu,
    /// MV-HEVC) into the surrounding dome natively, and the Digital Crown
    /// keeps control of envelopment. Flat placeholder media falls back to
    /// a screen floating in the dark, so the journey stays demonstrable
    /// before real footage lands.
    ///
    /// Returns nil only if the camp has no media at all.
    func makeEntity(for camp: Camp,
                    onFinish: @escaping @MainActor () -> Void) -> Entity? {
        teardown()
        guard let url = camp.masterURL else { return nil }

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        // Hold the last frame; the return choreography fades it out.
        player.actionAtItemEnd = .pause

        var video = VideoPlayerComponent(avPlayer: player)
        video.desiredImmersiveViewingMode = .progressive

        let entity = Entity()
        entity.name = "aiv.\(camp.id)"
        // AIV renders as a dome relative to the space origin; keep the
        // entity there. Flat fallback media renders as a screen AT the
        // entity — which at the origin sits inside the viewer's head —
        // so float stand-ins ahead at a comfortable watching distance.
        entity.position = url.pathExtension == "aivu"
            ? .zero
            : SIMD3(0, 1.30, -2.0)
        entity.components.set(video)
        entity.components.set(OpacityComponent(opacity: 0))

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            Task { @MainActor in onFinish() }
        }

        self.player = player
        self.entity = entity
        return entity
    }

    func play() {
        player?.play()
    }

    /// Ramp the sound down with the picture so the cut is never audible.
    func fadeOutAudio(over duration: TimeInterval) async {
        guard let player else { return }
        let steps = 10
        let startVolume = player.volume
        for step in 1...steps {
            player.volume = startVolume * (1 - Float(step) / Float(steps))
            try? await Task.sleep(for: .seconds(duration / Double(steps)))
        }
    }

    func teardown() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil
        player?.pause()
        player = nil
        entity?.removeFromParent()
        entity = nil
    }
}
