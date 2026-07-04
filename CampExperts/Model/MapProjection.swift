//
//  MapProjection.swift
//  CampExperts
//
//  One projection, two consumers: the Canvas that draws the geography and
//  the lens entities floating above it must agree to the millimeter, so
//  both convert through here.
//
//  Simple equirectangular projection about the region's mid-latitude — at
//  this scale (a tabletop of the Northeast) the distortion is imperceptible
//  and the math stays legible.
//

import Foundation
import CoreGraphics

enum MapProjection {

    static let latRange = 40.35...45.25
    static let lonRange = (-75.90)...(-67.00)

    private static let midLat = (latRange.lowerBound + latRange.upperBound) / 2
    private static let midLon = (lonRange.lowerBound + lonRange.upperBound) / 2
    private static let lonScale = cos(midLat * .pi / 180)

    /// Meters per degree of latitude, chosen so the region spans `Design.mapWidth`.
    private static let metersPerDegree =
        Double(Design.mapWidth) / ((lonRange.upperBound - lonRange.lowerBound) * lonScale)

    static let mapHeight =
        Float((latRange.upperBound - latRange.lowerBound) * metersPerDegree)

    /// Position on the map plane in meters, origin at the map's center.
    /// +x east, +y north.
    static func position(latitude: Double, longitude: Double) -> SIMD2<Float> {
        let x = (longitude - midLon) * lonScale * metersPerDegree
        let y = (latitude - midLat) * metersPerDegree
        return SIMD2(Float(x), Float(y))
    }

    // MARK: - Canvas space

    /// RealityView attachments render SwiftUI content at ~1360 points per
    /// meter. If the drawn geography and the floating lenses ever disagree
    /// in scale on device, this is the one knob to turn.
    static let pointsPerMeter: CGFloat = 1360

    static var canvasSize: CGSize {
        CGSize(width: CGFloat(Design.mapWidth) * pointsPerMeter,
               height: CGFloat(mapHeight) * pointsPerMeter)
    }

    static func canvasPoint(latitude: Double, longitude: Double) -> CGPoint {
        let p = position(latitude: latitude, longitude: longitude)
        let size = canvasSize
        return CGPoint(
            x: (CGFloat(p.x / Design.mapWidth) + 0.5) * size.width,
            y: (0.5 - CGFloat(p.y / mapHeight)) * size.height)
    }
}
