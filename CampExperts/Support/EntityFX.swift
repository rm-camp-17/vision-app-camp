//
//  EntityFX.swift
//  CampExperts
//

import Foundation
import RealityKit

extension Entity {

    /// Fade this entity (and its descendants) to a target opacity.
    /// The component is set to the destination first, so the end state is
    /// authoritative even if the animation is preempted mid-flight.
    func fade(to target: Float,
              duration: TimeInterval,
              timing: AnimationTimingFunction = .easeInOut) {
        let current = components[OpacityComponent.self]?.opacity ?? 1.0
        components.set(OpacityComponent(opacity: target))
        guard duration > 0, current != target else { return }

        let animation = FromToByAnimation<Float>(
            from: current,
            to: target,
            duration: duration,
            timing: timing,
            bindTarget: .opacity)
        if let resource = try? AnimationResource.generate(with: animation) {
            playAnimation(resource)
        }
    }
}
