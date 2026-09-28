//
//  HeadTracker.swift
//  CampExperts
//
//  Where are the guest's eyes? Asked once each time the map is about to
//  appear, so the stage can meet a seated parent, a standing ten-year-old
//  and a tall adult at the same comfortable height. World tracking needs
//  no permission prompt. Unavailable (simulator) or not yet running
//  means nil, and the stage stays at its authored height.
//

import ARKit
import QuartzCore

@MainActor
final class HeadTracker {

    private let session = ARKitSession()
    private let world = WorldTrackingProvider()

    func start() async {
        guard WorldTrackingProvider.isSupported else { return }
        do {
            try await session.run([world])
        } catch {
            trace("world tracking failed to start: \(error.localizedDescription)")
        }
    }

    /// Eye height above the floor, in meters.
    func eyeHeight() -> Float? {
        guard world.state == .running,
              let anchor = world.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())
        else { return nil }
        return anchor.originFromAnchorTransform.columns.3.y
    }
}
