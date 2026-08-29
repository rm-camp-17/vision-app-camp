//
//  NortheastMapView.swift
//  CampExperts
//
//  The geography: a hairline drawing of the Northeast floating in the
//  dark — soft bloom under a crisp line, like light through etched glass.
//  No borders, no fills, no chart furniture. It reads as a place.
//

import SwiftUI

struct NortheastMapView: View {

    @Environment(AppModel.self) private var model

    var body: some View {
        Canvas { context, _ in
            let coast = path(CoastlineData.mainland)
            let island = path(CoastlineData.longIsland, closed: true)

            // Land plate: the mainland closed off through the map's own
            // west and north edges and washed with the faintest tint —
            // land separates from ocean before a single line is read.
            let land = landPlate()
            context.fill(land, with: .color(Design.line.opacity(0.055)))
            context.fill(island, with: .color(Design.line.opacity(0.055)))

            // Bloom pass: the same lines, blurred wide and dim.
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 7))
                layer.stroke(coast, with: .color(Design.line.opacity(0.50)), lineWidth: 4.5)
                layer.stroke(island, with: .color(Design.line.opacity(0.50)), lineWidth: 4.5)
            }

            // Crisp pass.
            context.stroke(coast, with: .color(Design.line.opacity(0.85)), style: stroke(1.6))
            context.stroke(island, with: .color(Design.line.opacity(0.85)), style: stroke(1.6))

            // State borders — dimmer than the coast, brighter than the
            // rivers. These are what make it read as a map of somewhere.
            for border in CoastlineData.borders {
                context.stroke(path(border), with: .color(Design.line.opacity(0.30)),
                               style: stroke(1.0))
            }

            for river in CoastlineData.rivers {
                context.stroke(path(river), with: .color(Design.line.opacity(0.38)), style: stroke(1.1))
            }

            for lake in CoastlineData.lakes {
                let p = path(lake, closed: true)
                context.fill(p, with: .color(Design.line.opacity(0.10)))
                context.stroke(p, with: .color(Design.line.opacity(0.55)), style: stroke(1.1))
            }

            // Ghost state names, set wide and very quiet.
            for (name, lat, lon) in CoastlineData.stateLabels {
                let at = MapProjection.canvasPoint(latitude: lat, longitude: lon)
                let text = Text(name)
                    .font(.system(size: 26, weight: .medium))
                    .kerning(9)
                    .foregroundStyle(Design.line.opacity(0.28))
                context.draw(context.resolve(text), at: at, anchor: .center)
            }
        }
        .frame(width: MapProjection.canvasSize.width,
               height: MapProjection.canvasSize.height)
        .opacity(model.mapVisible ? 1 : 0)
        .animation(.easeInOut(duration: model.mapVisible ? 1.3 : Design.mapDim),
                   value: model.mapVisible)
        .allowsHitTesting(false)
    }

    private func stroke(_ width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }

    /// The mainland coastline closed into a fillable landmass through
    /// the map's own west and north edges (clipped by the canvas frame).
    private func landPlate() -> Path {
        var p = path(CoastlineData.mainland)
        let n = MapProjection.latRange.upperBound + 0.5
        let w = MapProjection.lonRange.lowerBound - 0.5
        let s = MapProjection.latRange.lowerBound - 0.5
        guard let first = CoastlineData.mainland.first else { return p }
        p.addLine(to: MapProjection.canvasPoint(latitude: n, longitude: -67.0))
        p.addLine(to: MapProjection.canvasPoint(latitude: n, longitude: w))
        p.addLine(to: MapProjection.canvasPoint(latitude: s, longitude: w))
        p.addLine(to: MapProjection.canvasPoint(latitude: s, longitude: first.1))
        p.closeSubpath()
        return p
    }

    private func path(_ points: [(Double, Double)], closed: Bool = false) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: MapProjection.canvasPoint(latitude: first.0, longitude: first.1))
        for point in points.dropFirst() {
            path.addLine(to: MapProjection.canvasPoint(latitude: point.0, longitude: point.1))
        }
        if closed { path.closeSubpath() }
        return path
    }
}
