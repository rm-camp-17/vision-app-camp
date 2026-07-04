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

    /// Center of the map in the room.
    static let mapCenter = SIMD3<Float>(0, 1.28, -1.55)

    /// The map leans back like a drafting table, top edge away from the visitor.
    static let mapTiltRadians: Float = -0.21   // ~12 degrees

    /// Width of the mapped region; height follows from the projection.
    static let mapWidth: Float = 1.70

    /// Lens disc radius. 4.5 cm at 1.55 m subtends about 3.3 degrees —
    /// a comfortable, unmistakable gaze target.
    static let lensRadius: Float = 0.045

    /// Lenses float slightly proud of the map plane.
    static let lensLift: Float = 0.035

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
    static let idleDelay: Duration = .seconds(13)

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
    static let wordmark = Color.white.opacity(0.30)

    // MARK: - Sound

    static let ambienceVolume: Float = 0.16
    static let swellVolume: Float = 0.55
}
