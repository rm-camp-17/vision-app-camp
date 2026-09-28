//
//  MapAssembler.swift
//  CampExperts
//
//  Builds the whole stage once: the tilted map, twenty lenses, the
//  invisible shell that catches stray pinches. Returns handles to
//  everything the choreography needs.
//

import SwiftUI
import RealityKit
import AVFoundation
import UIKit

/// Handles gathered at build time so Transport.swift never has to search
/// the scene graph mid-animation.
@MainActor
final class SceneAnchors {
    let root = Entity()
    /// Everything a guest looks at while browsing (map, card, hints),
    /// shifted as one unit to the guest's eye height. The film player
    /// stays on `root`: immersive video is anchored to the space itself.
    let stage = Entity()
    let mapRoot = Entity()
    let playerHost = Entity()
    let shell = Entity()
    var lensRoots: [String: Entity] = [:]
    var lensDiscs: [String: ModelEntity] = [:]
    var lensRings: [String: ModelEntity] = [:]
    var homeTransforms: [String: Transform] = [:]
}

@MainActor
enum MapAssembler {

    static func build(catalog: [Camp],
                      loops: ProxyLoopPool,
                      attachments: RealityViewAttachments) -> SceneAnchors {
        let anchors = SceneAnchors()

        // The map, leaned back like a drafting table.
        anchors.mapRoot.position = Design.mapCenter
        anchors.mapRoot.orientation = simd_quatf(angle: Design.mapTiltRadians,
                                                 axis: SIMD3(1, 0, 0))
        anchors.root.addChild(anchors.stage)
        anchors.stage.addChild(anchors.mapRoot)

        if let mapCanvas = attachments.entity(for: "map") {
            anchors.mapRoot.addChild(mapCanvas)
        }

        // The wordmark floats just above the map's top edge, on the same
        // tilted plane, slightly proud of it like the lenses.
        if let brand = attachments.entity(for: "brand") {
            brand.position = SIMD3(0, MapProjection.mapHeight / 2 + 0.10,
                                   Design.lensLift)
            anchors.mapRoot.addChild(brand)
        }

        // The focus card hangs just below the swelled lens — high enough
        // to stay inside the comfortable downward-gaze zone, leaned
        // gently toward the eye so its type is never foreshortened.
        if let card = attachments.entity(for: "focuscard") {
            card.position = SIMD3(0, 1.20, -1.05)
            card.orientation = simd_quatf(angle: -0.24, axis: SIMD3(1, 0, 0))
            anchors.stage.addChild(card)
        }

        // The attribute-browse panel lives on the map plane, slightly
        // prouder than the canvas so it never z-fights the geography it
        // replaces.
        if let panel = attachments.entity(for: "browsepanel") {
            panel.position = SIMD3(0, 0, Design.lensLift + 0.012)
            anchors.mapRoot.addChild(panel)
        }

        // Transient gesture hints: one over the reel, one inside films.
        // World-anchored low center, where captions live.
        if let hint = attachments.entity(for: "gesturehint") {
            hint.position = SIMD3(0, 0.92, -1.45)
            hint.orientation = simd_quatf(angle: -0.18, axis: SIMD3(1, 0, 0))
            anchors.stage.addChild(hint)
        }

        let placed = separatedPositions(for: catalog)
        for camp in catalog {
            let lens = makeLens(for: camp,
                                at: placed[camp.id] ?? MapProjection.position(
                                    latitude: camp.latitude, longitude: camp.longitude),
                                loops: loops, attachments: attachments)
            anchors.lensRoots[camp.id] = lens.root
            anchors.lensDiscs[camp.id] = lens.disc
            anchors.lensRings[camp.id] = lens.ring
            anchors.homeTransforms[camp.id] = lens.root.transform
            anchors.mapRoot.addChild(lens.root)
        }

        // Invisible room enclosing the visitor: six thin walls of a big
        // box, so a pinch lands NO MATTER WHERE THEY'RE LOOKING — sky,
        // water, over a shoulder. Walls, not a solid volume: a gaze ray
        // that STARTS inside a collision shape resolves to it at zero
        // distance, swallowing every lens and button in front of it.
        // (And a flat far wall only covered ~±57°; inside a 180° film,
        // sky-pinches fell into nothing.)
        anchors.shell.name = "shell"
        anchors.shell.position = SIMD3(0, 1.4, 0)
        anchors.shell.components.set(InputTargetComponent())
        let r: Float = 8, t: Float = 0.1, s: Float = 16.2
        anchors.shell.components.set(CollisionComponent(
            shapes: [
                .generateBox(width: s, height: s, depth: t).offsetBy(translation: SIMD3(0, 0, -r)),
                .generateBox(width: s, height: s, depth: t).offsetBy(translation: SIMD3(0, 0, r)),
                .generateBox(width: t, height: s, depth: s).offsetBy(translation: SIMD3(-r, 0, 0)),
                .generateBox(width: t, height: s, depth: s).offsetBy(translation: SIMD3(r, 0, 0)),
                .generateBox(width: s, height: t, depth: s).offsetBy(translation: SIMD3(0, -r, 0)),
                .generateBox(width: s, height: t, depth: s).offsetBy(translation: SIMD3(0, r, 0)),
            ],
            isStatic: true))
        anchors.root.addChild(anchors.shell)

        anchors.root.addChild(anchors.playerHost)
        return anchors
    }

    /// Real camps cluster — three in Greeley PA within 3 km, three on the
    /// Belgrade Lakes within 2 km. At tabletop scale those project onto
    /// the same point, so lenses are pushed apart pairwise until every
    /// pair clears `Design.lensMinSeparation`, then clamped to the map.
    /// Deterministic (no randomness): same catalog, same layout.
    private static func separatedPositions(for catalog: [Camp]) -> [String: SIMD2<Float>] {
        var positions = catalog.map {
            MapProjection.position(latitude: $0.latitude, longitude: $0.longitude)
        }
        let minD = Design.lensMinSeparation
        let halfW = Design.mapWidth / 2 - Design.lensRadius
        let halfH = MapProjection.mapHeight / 2 - Design.lensRadius
        func clamp(_ p: SIMD2<Float>) -> SIMD2<Float> {
            SIMD2(min(max(p.x, -halfW), halfW), min(max(p.y, -halfH), halfH))
        }
        for _ in 0..<200 {
            var moved = false
            for i in positions.indices {
                for j in positions.indices where j > i {
                    var delta = positions[j] - positions[i]
                    var dist = simd_length(delta)
                    if dist < 1e-6 {                     // exact overlap: split on x
                        delta = SIMD2(1e-3, 0); dist = 1e-3
                    }
                    guard dist < minD else { continue }
                    let push = (minD - dist) / 2 * (delta / dist)
                    // Clamp inside the loop, so an edge-clamped pair is
                    // re-separated on the next pass instead of being
                    // silently squashed back together at the border.
                    positions[i] = clamp(positions[i] - push)
                    positions[j] = clamp(positions[j] + push)
                    moved = true
                }
            }
            if !moved { break }
        }
        var out: [String: SIMD2<Float>] = [:]
        for (camp, p) in zip(catalog, positions) {
            out[camp.id] = clamp(p)
        }
        return out
    }

    private static func makeLens(for camp: Camp,
                                 at mapPosition: SIMD2<Float>,
                                 loops: ProxyLoopPool,
                                 attachments: RealityViewAttachments)
    -> (root: Entity, disc: ModelEntity, ring: ModelEntity) {

        let root = Entity()
        root.name = "lensroot.\(camp.id)"
        root.position = SIMD3(mapPosition.x, mapPosition.y, Design.lensLift)

        // The ember ring: the one warm object in a cold room, and only
        // around the chosen thing. Hidden until focus lights it.
        let ringRadius = Design.lensRadius * 1.10
        let ring = ModelEntity(
            mesh: .generatePlane(width: ringRadius * 2, height: ringRadius * 2,
                                 cornerRadius: ringRadius),
            materials: [UnlitMaterial(color: UIColor(
                red: 1.0, green: 0.63, blue: 0.11, alpha: 1.0))])
        ring.name = "ring.\(camp.id)"
        ring.position = SIMD3(0, 0, -0.002)
        ring.components.set(OpacityComponent(opacity: 0))
        root.addChild(ring)

        let radius = Design.lensRadius
        let mesh = MeshResource.generatePlane(width: radius * 2,
                                              height: radius * 2,
                                              cornerRadius: radius)

        // A living loop when the proxy exists; a dark, waiting disc when it
        // doesn't, so a media-less build is dim rather than broken.
        let material: any RealityKit.Material
        if let player = loops.player(for: camp) {
            material = VideoMaterial(avPlayer: player)
        } else {
            material = UnlitMaterial(color: UIColor(red: 0.09, green: 0.11,
                                                    blue: 0.13, alpha: 1.0))
        }

        let disc = ModelEntity(mesh: mesh, materials: [material])
        disc.name = "lens.\(camp.id)"
        disc.components.set(InputTargetComponent())
        // Collision well beyond the disc: first-wear guests arrive with
        // rough eye calibration, and a generous target plus the focus
        // confirm step is what makes selection feel dependable.
        disc.components.set(CollisionComponent(
            shapes: [.generateBox(width: radius * 3.2, height: radius * 3.2, depth: 0.02)],
            isStatic: true))
        // The gaze answer. Rendered by the system, out of process; the app
        // never learns where the visitor is looking.
        disc.components.set(HoverEffectComponent(.spotlight(
            HoverEffectComponent.SpotlightHoverEffectStyle(color: .white, strength: 1.8))))
        // Boot fades every lens in.
        disc.components.set(OpacityComponent(opacity: 0))
        root.addChild(disc)

        if let label = attachments.entity(for: camp.id) {
            label.position = SIMD3(0, -(radius + 0.048), 0.004)
            root.addChild(label)
        }

        return (root, disc, ring)
    }
}
