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
    let mapRoot = Entity()
    let playerHost = Entity()
    let shell = Entity()
    var lensRoots: [String: Entity] = [:]
    var lensDiscs: [String: ModelEntity] = [:]
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
        anchors.root.addChild(anchors.mapRoot)

        if let mapCanvas = attachments.entity(for: "map") {
            anchors.mapRoot.addChild(mapCanvas)
        }

        for camp in catalog {
            let lens = makeLens(for: camp, loops: loops, attachments: attachments)
            anchors.lensRoots[camp.id] = lens.root
            anchors.lensDiscs[camp.id] = lens.disc
            anchors.homeTransforms[camp.id] = lens.root.transform
            anchors.mapRoot.addChild(lens.root)
        }

        // Invisible far wall behind the map. Pinches that miss every lens
        // land here: on the map they re-arm the idle clock; during a visit
        // they begin the return.
        anchors.shell.name = "shell"
        anchors.shell.position = SIMD3(0, 1.4, -4.5)
        anchors.shell.components.set(InputTargetComponent())
        anchors.shell.components.set(CollisionComponent(
            shapes: [.generateBox(width: 14, height: 9, depth: 0.1)],
            isStatic: true))
        anchors.root.addChild(anchors.shell)

        anchors.root.addChild(anchors.playerHost)
        return anchors
    }

    private static func makeLens(for camp: Camp,
                                 loops: ProxyLoopPool,
                                 attachments: RealityViewAttachments)
    -> (root: Entity, disc: ModelEntity) {

        let root = Entity()
        root.name = "lensroot.\(camp.id)"
        let mapPosition = MapProjection.position(latitude: camp.latitude,
                                                 longitude: camp.longitude)
        root.position = SIMD3(mapPosition.x, mapPosition.y, Design.lensLift)

        let radius = Design.lensRadius
        let mesh = MeshResource.generatePlane(width: radius * 2,
                                              height: radius * 2,
                                              cornerRadius: radius)

        // A living loop when the proxy exists; a dark, waiting disc when it
        // doesn't, so a media-less build is dim rather than broken.
        let material: any Material
        if let player = loops.player(for: camp) {
            material = VideoMaterial(avPlayer: player)
        } else {
            material = UnlitMaterial(color: UIColor(red: 0.09, green: 0.11,
                                                    blue: 0.13, alpha: 1.0))
        }

        let disc = ModelEntity(mesh: mesh, materials: [material])
        disc.name = "lens.\(camp.id)"
        disc.components.set(InputTargetComponent())
        // Collision slightly larger than the disc: forgiving gaze targeting.
        disc.components.set(CollisionComponent(
            shapes: [.generateBox(width: radius * 2.4, height: radius * 2.4, depth: 0.02)],
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

        return (root, disc)
    }
}
