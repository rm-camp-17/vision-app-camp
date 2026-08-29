//
//  ThresholdSpaceView.swift
//  CampExperts
//
//  The single scene of the app: the dark stage, the map, and — during a
//  visit — the immersive player. One persistent space, so the crossing is
//  one continuous piece of choreography rather than a scene swap, and the
//  return lands on the map exactly as it was left.
//

import SwiftUI
import RealityKit

struct ThresholdSpaceView: View {

    @Environment(AppModel.self) private var model

    var body: some View {
        RealityView { content, attachments in
            let anchors = MapAssembler.build(
                catalog: CampCatalog.all,
                loops: model.loops,
                attachments: attachments)
            content.add(anchors.root)
            model.sceneReady(anchors)
        } attachments: {
            Attachment(id: "map") {
                NortheastMapView()
            }
            Attachment(id: "brand") {
                BrandMarkView()
            }
            ForEach(CampCatalog.all) { camp in
                Attachment(id: camp.id) {
                    CampLensLabel(camp: camp)
                }
            }
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    let name = value.entity.name
                    if name.hasPrefix("lens.") {
                        model.lensTapped(id: String(name.dropFirst("lens.".count)))
                    } else {
                        model.shellTapped()
                    }
                }
        )
        // Passthrough beyond the dome goes near-black: the room recedes,
        // the camps become the only light in it.
        .preferredSurroundingsEffect(.systemDark)
        .onDisappear {
            model.sceneClosed()
        }
    }
}
