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
