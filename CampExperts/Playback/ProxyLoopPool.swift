//
//  ProxyLoopPool.swift
//  CampExperts
//
//  Twenty tiny, muted, looping flat proxies — the "living" in the lenses.
//  One AVPlayerLooper per camp. All of them pause during a visit so every
//  decoder in the machine belongs to the immersive master.
//

import Foundation
import AVFoundation

@MainActor
final class ProxyLoopPool {

    /// The decoder budget. Proxies are 512×512 HEVC/H.264 at ~1.5 Mb/s,
    /// which current hardware sustains twenty of comfortably. If a future
    /// asset drop pushes bitrates up and the map stutters, lower this:
    /// camps beyond the budget hold their dark waiting discs instead.
    var maxLive = 22

    private var players: [String: AVQueuePlayer] = [:]
    private var loopers: [String: AVPlayerLooper] = [:]

    func player(for camp: Camp) -> AVQueuePlayer? {
        if let existing = players[camp.id] { return existing }
        guard players.count < maxLive, let url = camp.loopURL else { return nil }

        let player = AVQueuePlayer()
        player.isMuted = true
        loopers[camp.id] = AVPlayerLooper(player: player,
                                          templateItem: AVPlayerItem(url: url))
        players[camp.id] = player
        return player
    }

    /// Staggered start keeps twenty decoders from spinning up on the same frame.
    func playAll() {
        let players = Array(self.players.values)
        Task { @MainActor in
            for player in players {
                player.play()
                try? await Task.sleep(for: .milliseconds(70))
            }
        }
    }

    func pauseAll() {
        for player in players.values { player.pause() }
    }
}
