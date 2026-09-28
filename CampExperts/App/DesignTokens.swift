//
//  DesignTokens.swift
//  CampExperts
//
//  Every number a visitor can feel lives in this file: distances, beats,
//  opacities, the two colors. Tune the experience here, nowhere else.
//

import SwiftUI

enum Design {

    // MARK: - Stage geometry (meters, space origin is the floor under the visitor)

    /// Every stage position below is authored for this eye height. When
    /// the map appears, the whole stage shifts so this line lands on the
    /// guest's actual eyes — seated adults, kids, and tall standing adults
    /// all get the same view instead of a map pinned to the floor.
    static let designEyeHeight: Float = 1.60

    /// Center of the map: a comfortable 28 cm below the eyes, 1.3 m out.
    static let mapCenter = SIMD3<Float>(0, 1.32, -1.30)

    /// Tilted exactly enough to face the eye squarely (atan(drop/distance),
    /// about 12°) — never leaning away.
    static let mapTiltRadians: Float = -atan2(Float(0.28), Float(1.30))

    /// Width of the mapped region; height follows from the projection.
    static let mapWidth: Float = 1.45

    /// Lens disc radius. 4.5 cm at 1.55 m subtends about 3.3 degrees —
    /// a comfortable, unmistakable gaze target.
    static let lensRadius: Float = 0.045

    /// Lenses float slightly proud of the map plane.
    static let lensLift: Float = 0.035

    /// Minimum center-to-center distance between any two lenses after the
    /// layout separation pass — enough for two discs plus breathing room
    /// so labels never collide (disc is 9 cm across).
    static let lensMinSeparation: Float = 0.19

    // MARK: - Focus (the pause before the plunge)

    /// First pinch focuses a camp instead of entering it: the lens swells
    /// toward the visitor and a card presents the camp. A second pinch on
    /// the lens enters; a pinch anywhere else returns to the map. Big
    /// targets and an explicit confirm forgive first-wear eye calibration.
    static let lensFocusPoint = SIMD3<Float>(0, 1.42, -1.05)
    static let lensFocusScale: Float = 2.6
    static let focusMove: TimeInterval = 0.45
    /// How far the rest of the map recedes while something is focused.
    static let focusDimOpacity: Float = 0.30
    /// A focused camp left alone returns to the map on its own.
    static let focusTimeout: TimeInterval = 45

    /// An idle pick is a suggestion, not an ambush: the space focuses a
    /// camp (swell + card) and only enters if the guest stays silent
    /// this much longer. A pinch elsewhere declines it.
    static let suggestionDwell: TimeInterval = 12

    // MARK: - Booth flow

    /// How many camp visits one guest gets before the space resets for
    /// the next family.
    static let visitsPerGuest = 3

    /// A pinch can skip the intro reel, but not in the first moments —
    /// the confirming pinch from the previous interaction must not
    /// bounce a new guest straight past the welcome.
    static let introSkipGrace: TimeInterval = 8.0

    /// Intro reel fade in/out.
    static let introFade: TimeInterval = 0.9

    /// The intro reel's soundtrack (played alongside the silent .aivu).
    static let introAudioVolume: Float = 0.9

    /// The gesture lesson appears this far into the reel, and the exit
    /// hint this far into a film; each lingers `hintLinger` then fades.
    static let introHintAt: TimeInterval = 8.0
    static let filmHintAt: TimeInterval = 5.0
    static let hintLinger: TimeInterval = 8.0

    /// The goodbye beat after a guest's last visit, before the dark.
    static let farewellHold: TimeInterval = 10.0

    /// Where a chosen lens travels before the crossing: near, just below eye line.
    static let lensApproachPoint = SIMD3<Float>(0, 1.30, -0.85)
    static let lensApproachScale: Float = 1.7

    // MARK: - The crossing (seconds)

    /// Unchosen lenses exhale and go dark.
    static let otherLensesExhale: TimeInterval = 0.35
    /// The coastline drawing dims to black.
    static let mapDim: TimeInterval = 0.55
    /// The chosen lens drifts up to meet the visitor.
    static let lensApproach: TimeInterval = 0.70
    /// ...then dissolves.
    static let lensDissolve: TimeInterval = 0.30
    /// A held beat of true dark. The threshold itself.
    static let darkHold: TimeInterval = 0.45
    /// The camp blooms in from black.
    static let sceneBloom: TimeInterval = 1.40
    /// The camp fades out when the visit ends.
    static let sceneFade: TimeInterval = 0.90
    /// The map breathes back in.
    static let mapRebreathe: TimeInterval = 1.20
    static let lensRippleStep: TimeInterval = 0.05
    static let lensRippleDuration: TimeInterval = 0.55

    // MARK: - Boot

    static let bootBeat: TimeInterval = 0.8
    static let bootLensStagger: TimeInterval = 0.045
    static let bootLensFade: TimeInterval = 0.6

    // MARK: - Idle

    /// If nobody chooses, the space chooses. Long enough to browse,
    /// short enough that the room never feels stuck.
    static let idleDelay: Duration = .seconds(40)

    /// Pinches this early in a visit are almost always the confirm pinch
    /// echoing, or a startled hand. Ignore them.
    static let returnGrace: TimeInterval = 5.0

    // MARK: - Immersion

    /// Progressive immersion: the dome envelops most of the view, and the
    /// Digital Crown always hands "how much world" back to the visitor.
    static let immersionRange: ClosedRange<Double> = 0.35...1.0
    static let immersionInitial: Double = 0.60

    // MARK: - Light

    /// Pale, cold, cartographic. The only line color in the app.
    static let line = Color(red: 0.72, green: 0.82, blue: 0.88)
    static let labelPrimary = Color.white.opacity(0.88)
    static let labelSecondary = Color.white.opacity(0.50)
    /// Ghost state names on the map — true ground, never figure.
    static let stateName = line.opacity(0.20)

    /// The one warm color in a cold room: Camp Experts amber, reserved
    /// for the chosen thing — the focused lens ring, the card's edge,
    /// the waiting ember. Never used ambiently.
    static let ember = Color(red: 1.0, green: 0.63, blue: 0.11)

    // MARK: - Sound

    static let ambienceVolume: Float = 0.16
    static let swellVolume: Float = 0.55
}
