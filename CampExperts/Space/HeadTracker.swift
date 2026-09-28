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
    private var world = WorldTrackingProvider()

    func start() async {
        guard WorldTrackingProvider.isSupported else { return }
        do {
            try await session.run([world])
        } catch {
            trace("world tracking failed to start: \(error.localizedDescription)")
        }
    }

    /// After the headset comes off and goes back on, tracking resumes by
    /// itself; if the provider was stopped outright, start a fresh one.
    func ensureRunning() async {
        guard WorldTrackingProvider.isSupported, world.state == .stopped else { return }
        world = WorldTrackingProvider()
        await start()
    }

    /// Eye height above the floor, in meters.
    func eyeHeight() -> Float? {
        guard world.state == .running,
              let anchor = world.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())
        else { return nil }
        return anchor.originFromAnchorTransform.columns.3.y
    }
}
