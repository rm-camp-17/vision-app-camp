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
    /// A separate soundtrack for a film delivered silent (the intro reel),
    /// started on the same host-clock instant as the picture.
    private var soundtrack: AVPlayer?
    private var endObserver: NSObjectProtocol?
    private var failObserver: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?
    private var rateObservation: NSKeyValueObservation?

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
                    soundtrack soundtrackURL: URL? = nil,
                    onFinish: @escaping @MainActor () -> Void) -> Entity? {
        teardown()
        guard let url = camp.masterURL else { return nil }

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        // Hold the last frame; the return choreography fades it out.
        player.actionAtItemEnd = .pause
        // Required for a host-clock start (setRate(_:time:atHostTime:)).
        player.automaticallyWaitsToMinimizeStalling = false
        if let soundtrackURL {
            let sound = AVPlayer(url: soundtrackURL)
            sound.automaticallyWaitsToMinimizeStalling = false
            sound.volume = Design.introAudioVolume
            soundtrack = sound
        }

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

        // Diagnostics: the player's verdict on the file, and any failure.
        let label = "\(camp.id)/\(url.lastPathComponent)"
        statusObservation = item.observe(\.status, options: [.new]) { item, _ in
            let status = ["unknown", "readyToPlay", "failed"][min(item.status.rawValue, 2)]
            trace("player item \(label): \(status)\(item.error.map { " — \($0.localizedDescription)" } ?? "")")
        }
        rateObservation = player.observe(\.timeControlStatus, options: [.new]) { player, _ in
            let state = ["paused", "waiting", "playing"][min(player.timeControlStatus.rawValue, 2)]
            let why = player.reasonForWaitingToPlay.map { " (\($0.rawValue))" } ?? ""
            trace("player \(label): \(state)\(why)")
        }
        failObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main
        ) { note in
            let err = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            trace("player item \(label) FAILED mid-play: \(err?.localizedDescription ?? "unknown")")
        }

        self.player = player
        self.entity = entity
        return entity
    }

    /// Start picture and sound together. An 8K immersive film takes a
    /// beat to produce its first frame while audio starts instantly, so
    /// "press play on both" drifts apart from the first second. Instead:
    /// wait until both are loaded, preroll both, then release both at the
    /// same moment on the host clock.
    func play() async {
        guard let player, let item = player.currentItem else { return }
        await waitUntilReady(item)
        if let sound = soundtrack?.currentItem { await waitUntilReady(sound) }
        guard self.player === player else { return }        // torn down meanwhile
        if item.status == .readyToPlay { _ = await player.preroll(atRate: 1) }
        if let soundtrack, soundtrack.currentItem?.status == .readyToPlay {
            _ = await soundtrack.preroll(atRate: 1)
        }
        guard self.player === player else { return }
        let start = CMTimeAdd(CMClockGetTime(CMClockGetHostTimeClock()),
                              CMTime(value: 1, timescale: 5))  // 200 ms out
        player.setRate(1, time: .zero, atHostTime: start)
        soundtrack?.setRate(1, time: .zero, atHostTime: start)
        trace("playback started on the host clock\(soundtrack == nil ? "" : " with soundtrack")")
    }

    private func waitUntilReady(_ item: AVPlayerItem) async {
        for _ in 0..<100 where item.status == .unknown {      // up to 10 s
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    /// Ramp the sound down with the picture so the cut is never audible.
    func fadeOutAudio(over duration: TimeInterval) async {
        let voices = [player, soundtrack].compactMap { $0 }
        guard !voices.isEmpty else { return }
        let steps = 10
        let starts = voices.map(\.volume)
        for step in 1...steps {
            for (voice, start) in zip(voices, starts) {
                voice.volume = start * (1 - Float(step) / Float(steps))
            }
            try? await Task.sleep(for: .seconds(duration / Double(steps)))
        }
    }

    func teardown() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        if let failObserver {
            NotificationCenter.default.removeObserver(failObserver)
        }
        endObserver = nil
        failObserver = nil
        statusObservation = nil
        rateObservation = nil
        player?.pause()
        player = nil
        soundtrack?.pause()
        soundtrack = nil
        entity?.removeFromParent()
        entity = nil
    }
}
