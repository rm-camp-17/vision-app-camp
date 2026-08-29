//
//  AmbienceEngine.swift
//  CampExperts
//
//  Two sounds only: a barely-there ambient bed under the map, and a low
//  swell that carries the crossing. The camps bring their own sound.
//  Both files are optional — silence is an acceptable v1 mix, so every
//  call here degrades to a no-op if the audio hasn't been dropped in.
//

import Foundation
import AVFoundation

@MainActor
final class AmbienceEngine {

    private var bed: AVAudioPlayer?
    private var swell: AVAudioPlayer?
    private var intro: AVAudioPlayer?

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)

        if let url = Bundle.main.url(forResource: "ambience", withExtension: "m4a",
                                     subdirectory: "Audio") {
            bed = try? AVAudioPlayer(contentsOf: url)
            bed?.numberOfLoops = -1
            bed?.volume = 0
        }
        if let url = Bundle.main.url(forResource: "swell", withExtension: "m4a",
                                     subdirectory: "Audio") {
            swell = try? AVAudioPlayer(contentsOf: url)
            swell?.volume = Design.swellVolume
        }
        if let url = Bundle.main.url(forResource: "intro", withExtension: "m4a",
                                     subdirectory: "Audio") {
            intro = try? AVAudioPlayer(contentsOf: url)
            intro?.volume = Design.introAudioVolume
        }
    }

    /// The welcome reel's soundtrack. The .aivu ships silent, so its
    /// audio rides alongside as a plain player, started with playback.
    func startIntroAudio() {
        intro?.currentTime = 0
        intro?.volume = Design.introAudioVolume
        intro?.play()
    }

    func stopIntroAudio(over duration: TimeInterval) {
        guard let intro, intro.isPlaying else { return }
        intro.setVolume(0, fadeDuration: duration)
        Task { @MainActor [weak intro] in
            try? await Task.sleep(for: .seconds(duration))
            intro?.stop()
        }
    }

    func startBed() {
        guard let bed, !bed.isPlaying else { return }
        bed.play()
        bed.setVolume(Design.ambienceVolume, fadeDuration: 3.0)
    }

    func duckBed() {
        bed?.setVolume(0, fadeDuration: 0.8)
    }

    func liftBed() {
        bed?.setVolume(Design.ambienceVolume, fadeDuration: 2.0)
    }

    func playSwell() {
        swell?.currentTime = 0
        swell?.play()
    }
}
