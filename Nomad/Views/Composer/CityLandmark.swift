//
//  CityLandmark.swift
//  Nomad
//
//  Hand-drawn landmark silhouettes for well-known cities. Each landmark is a
//  Canvas drawing, kept under ~30 lines per city so the stamp stays crisp at
//  small sizes. Match keys against the lowercased city portion of the
//  postcard's locationName.
//

import SwiftUI

enum CityLandmark {
    /// Returns a view for the given location name, or nil if no specific
    /// landmark is known. Falls back to theme art in the stamp.
    @ViewBuilder
    static func view(for locationName: String?) -> some View {
        let key = (locationName ?? "")
            .lowercased()
            .components(separatedBy: ",")
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""
        switch key {
        case "paris":           EiffelTower()
        case "new york",
             "manhattan",
             "brooklyn":        NYCSkyline()
        case "london":          BigBen()
        case "tokyo",
             "kyoto":           MountFuji()
        case "sydney":          OperaHouse()
        case "dubai":           BurjKhalifa()
        case "san francisco":   GoldenGateBridge()
        case "rome":            Colosseum()
        case "pisa":            LeaningTower()
        case "moscow":          KremlinSpire()
        case "istanbul":        HagiaSophia()
        case "rio de janeiro":  ChristRedeemer()
        case "cairo":           Pyramids()
        case "athens":          Parthenon()
        case "barcelona":       SagradaFamilia()
        case "amsterdam":       Windmill()
        default:                EmptyView()
        }
    }

    static func hasLandmark(for locationName: String?) -> Bool {
        let key = (locationName ?? "")
            .lowercased()
            .components(separatedBy: ",")
            .first?
            .trimmingCharacters(in: .whitespaces) ?? ""
        let known: Set<String> = [
            "paris", "new york", "manhattan", "brooklyn", "london", "tokyo",
            "kyoto", "sydney", "dubai", "san francisco", "rome", "pisa",
            "moscow", "istanbul", "rio de janeiro", "cairo", "athens",
            "barcelona", "amsterdam"
        ]
        return known.contains(key)
    }
}

// MARK: - Landmark drawings

private struct EiffelTower: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            var path = Path()
            // Base legs
            path.move(to: CGPoint(x: w * 0.15, y: h))
            path.addLine(to: CGPoint(x: w * 0.35, y: h * 0.55))
            path.move(to: CGPoint(x: w * 0.85, y: h))
            path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.55))
            // Middle deck
            path.move(to: CGPoint(x: w * 0.30, y: h * 0.6))
            path.addLine(to: CGPoint(x: w * 0.70, y: h * 0.6))
            path.move(to: CGPoint(x: w * 0.35, y: h * 0.55))
            path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.55))
            // Upper tower
            path.move(to: CGPoint(x: w * 0.40, y: h * 0.55))
            path.addLine(to: CGPoint(x: w * 0.45, y: h * 0.25))
            path.move(to: CGPoint(x: w * 0.60, y: h * 0.55))
            path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.25))
            // Antenna
            path.move(to: CGPoint(x: w * 0.45, y: h * 0.25))
            path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.05))
            path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.25))
            ctx.stroke(path, with: .color(.black.opacity(0.85)), lineWidth: 1.1)
        }
    }
}

private struct NYCSkyline: View {
    var body: some View {
        Canvas { ctx, size in
            let h = size.height
            // Varying building heights, with an Empire-State-like spire in the middle.
            let cols: [CGFloat] = [0.5, 0.35, 0.65, 0.45, 0.20, 0.4, 0.55, 0.3]
            let w = size.width / CGFloat(cols.count)
            for (i, top) in cols.enumerated() {
                let x = CGFloat(i) * w
                let rect = CGRect(x: x + 1, y: h * top, width: w - 2, height: h * (1 - top))
                ctx.fill(Path(rect), with: .color(.black.opacity(0.85)))
            }
            // Spire on building index 4
            var spire = Path()
            let sx = CGFloat(4) * w + w / 2
            spire.move(to: CGPoint(x: sx, y: h * 0.20 - 6))
            spire.addLine(to: CGPoint(x: sx, y: h * 0.20))
            ctx.stroke(spire, with: .color(.black.opacity(0.85)), lineWidth: 1.2)
        }
    }
}

private struct BigBen: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            // Tower body
            ctx.stroke(
                Path(CGRect(x: w * 0.4, y: h * 0.25, width: w * 0.2, height: h * 0.7)),
                with: .color(.black.opacity(0.85)), lineWidth: 1.1
            )
            // Clock face
            ctx.stroke(
                Path(ellipseIn: CGRect(x: w * 0.42, y: h * 0.32, width: w * 0.16, height: w * 0.16)),
                with: .color(.black.opacity(0.85)), lineWidth: 1
            )
            // Spire
            var top = Path()
            top.move(to: CGPoint(x: w * 0.4, y: h * 0.25))
            top.addLine(to: CGPoint(x: w * 0.5, y: h * 0.05))
            top.addLine(to: CGPoint(x: w * 0.6, y: h * 0.25))
            ctx.stroke(top, with: .color(.black.opacity(0.85)), lineWidth: 1.1)
        }
    }
}

private struct MountFuji: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            var path = Path()
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: w * 0.3, y: h * 0.4))
            path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.25))
            // Snow cap notch
            path.addLine(to: CGPoint(x: w * 0.45, y: h * 0.30))
            path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.20))
            path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.30))
            path.addLine(to: CGPoint(x: w * 0.60, y: h * 0.25))
            path.addLine(to: CGPoint(x: w * 0.70, y: h * 0.40))
            path.addLine(to: CGPoint(x: w, y: h))
            path.closeSubpath()
            ctx.stroke(path, with: .color(.black.opacity(0.85)), lineWidth: 1.1)
        }
    }
}

private struct OperaHouse: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            // 3 shell arches
            for i in 0..<3 {
                let xOff = CGFloat(i) * w * 0.22
                var path = Path()
                path.move(to: CGPoint(x: w * 0.15 + xOff, y: h * 0.9))
                path.addQuadCurve(
                    to: CGPoint(x: w * 0.40 + xOff, y: h * 0.9),
                    control: CGPoint(x: w * 0.275 + xOff, y: h * 0.2)
                )
                ctx.stroke(path, with: .color(.black.opacity(0.85)), lineWidth: 1.1)
            }
            // Water line
            var water = Path()
            water.move(to: CGPoint(x: 0, y: h * 0.95))
            water.addLine(to: CGPoint(x: w, y: h * 0.95))
            ctx.stroke(water, with: .color(.black.opacity(0.5)), lineWidth: 0.8)
        }
    }
}

private struct BurjKhalifa: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            var path = Path()
            path.move(to: CGPoint(x: w * 0.4, y: h))
            path.addLine(to: CGPoint(x: w * 0.45, y: h * 0.3))
            path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.05))
            path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.3))
            path.addLine(to: CGPoint(x: w * 0.6, y: h))
            path.closeSubpath()
            ctx.stroke(path, with: .color(.black.opacity(0.85)), lineWidth: 1.1)
        }
    }
}

private struct GoldenGateBridge: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            // Two towers
            ctx.stroke(
                Path(CGRect(x: w * 0.20, y: h * 0.3, width: 2, height: h * 0.55)),
                with: .color(.black.opacity(0.85)), lineWidth: 1.2
            )
            ctx.stroke(
                Path(CGRect(x: w * 0.78, y: h * 0.3, width: 2, height: h * 0.55)),
                with: .color(.black.opacity(0.85)), lineWidth: 1.2
            )
            // Suspension cable
            var cable = Path()
            cable.move(to: CGPoint(x: w * 0.05, y: h * 0.55))
            cable.addQuadCurve(
                to: CGPoint(x: w * 0.95, y: h * 0.55),
                control: CGPoint(x: w * 0.5, y: h * 0.85)
            )
            ctx.stroke(cable, with: .color(.black.opacity(0.85)), lineWidth: 1)
            // Deck
            var deck = Path()
            deck.move(to: CGPoint(x: 0, y: h * 0.85))
            deck.addLine(to: CGPoint(x: w, y: h * 0.85))
            ctx.stroke(deck, with: .color(.black.opacity(0.85)), lineWidth: 1)
        }
    }
}

private struct Colosseum: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            // Two rows of arches
            for row in 0..<2 {
                let y = h * (row == 0 ? 0.35 : 0.65)
                for col in 0..<5 {
                    let cx = w * 0.15 + CGFloat(col) * w * 0.15
                    let rect = CGRect(x: cx, y: y, width: w * 0.10, height: h * 0.20)
                    var path = Path()
                    path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                    path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
                    path.addQuadCurve(
                        to: CGPoint(x: rect.maxX, y: rect.midY),
                        control: CGPoint(x: rect.midX, y: rect.minY)
                    )
                    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                    ctx.stroke(path, with: .color(.black.opacity(0.85)), lineWidth: 0.8)
                }
            }
        }
    }
}

private struct LeaningTower: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            ctx.transform = CGAffineTransform(translationX: w * 0.5, y: h * 0.5)
                .rotated(by: .pi / 18) // 10°
                .translatedBy(x: -w * 0.5, y: -h * 0.5)
            ctx.stroke(
                Path(CGRect(x: w * 0.42, y: h * 0.15, width: w * 0.16, height: h * 0.75)),
                with: .color(.black.opacity(0.85)), lineWidth: 1
            )
            for i in 0..<5 {
                var line = Path()
                let y = h * (0.25 + 0.15 * CGFloat(i))
                line.move(to: CGPoint(x: w * 0.42, y: y))
                line.addLine(to: CGPoint(x: w * 0.58, y: y))
                ctx.stroke(line, with: .color(.black.opacity(0.7)), lineWidth: 0.6)
            }
        }
    }
}

private struct KremlinSpire: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            // Onion dome
            var dome = Path()
            dome.move(to: CGPoint(x: w * 0.35, y: h * 0.55))
            dome.addQuadCurve(
                to: CGPoint(x: w * 0.65, y: h * 0.55),
                control: CGPoint(x: w * 0.5, y: h * 0.15)
            )
            ctx.stroke(dome, with: .color(.black.opacity(0.85)), lineWidth: 1.1)
            // Tower base
            ctx.stroke(
                Path(CGRect(x: w * 0.4, y: h * 0.55, width: w * 0.2, height: h * 0.4)),
                with: .color(.black.opacity(0.85)), lineWidth: 1
            )
            // Cross on top
            var cross = Path()
            cross.move(to: CGPoint(x: w * 0.5, y: h * 0.20))
            cross.addLine(to: CGPoint(x: w * 0.5, y: h * 0.05))
            cross.move(to: CGPoint(x: w * 0.45, y: h * 0.10))
            cross.addLine(to: CGPoint(x: w * 0.55, y: h * 0.10))
            ctx.stroke(cross, with: .color(.black.opacity(0.85)), lineWidth: 1)
        }
    }
}

private struct HagiaSophia: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            // Central dome
            var dome = Path()
            dome.addArc(
                center: CGPoint(x: w * 0.5, y: h * 0.55),
                radius: w * 0.22,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
            ctx.stroke(dome, with: .color(.black.opacity(0.85)), lineWidth: 1.1)
            // Building base
            ctx.stroke(
                Path(CGRect(x: w * 0.20, y: h * 0.55, width: w * 0.6, height: h * 0.4)),
                with: .color(.black.opacity(0.85)), lineWidth: 1
            )
            // Minarets
            for x: CGFloat in [w * 0.12, w * 0.85] {
                ctx.stroke(
                    Path(CGRect(x: x, y: h * 0.3, width: 2, height: h * 0.65)),
                    with: .color(.black.opacity(0.85)), lineWidth: 1
                )
                var tip = Path()
                tip.move(to: CGPoint(x: x - 3, y: h * 0.3))
                tip.addLine(to: CGPoint(x: x + 1, y: h * 0.18))
                tip.addLine(to: CGPoint(x: x + 5, y: h * 0.3))
                ctx.stroke(tip, with: .color(.black.opacity(0.85)), lineWidth: 1)
            }
        }
    }
}

private struct ChristRedeemer: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            // Mountain base (Corcovado)
            var mountain = Path()
            mountain.move(to: CGPoint(x: 0, y: h))
            mountain.addLine(to: CGPoint(x: w * 0.5, y: h * 0.5))
            mountain.addLine(to: CGPoint(x: w, y: h))
            mountain.closeSubpath()
            ctx.stroke(mountain, with: .color(.black.opacity(0.7)), lineWidth: 0.8)
            // Cross figure
            var figure = Path()
            figure.move(to: CGPoint(x: w * 0.5, y: h * 0.40))
            figure.addLine(to: CGPoint(x: w * 0.5, y: h * 0.10))
            figure.move(to: CGPoint(x: w * 0.35, y: h * 0.20))
            figure.addLine(to: CGPoint(x: w * 0.65, y: h * 0.20))
            ctx.stroke(figure, with: .color(.black.opacity(0.85)), lineWidth: 1.4)
        }
    }
}

private struct Pyramids: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            for (cx, scale) in [(w * 0.35, 0.85), (w * 0.65, 1.0), (w * 0.85, 0.65)] {
                let base: CGFloat = w * 0.18 * CGFloat(scale)
                var path = Path()
                path.move(to: CGPoint(x: cx - base, y: h * 0.9))
                path.addLine(to: CGPoint(x: cx, y: h * 0.9 - base))
                path.addLine(to: CGPoint(x: cx + base, y: h * 0.9))
                path.closeSubpath()
                ctx.stroke(path, with: .color(.black.opacity(0.85)), lineWidth: 1)
            }
        }
    }
}

private struct Parthenon: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            // Pediment triangle
            var pediment = Path()
            pediment.move(to: CGPoint(x: w * 0.15, y: h * 0.45))
            pediment.addLine(to: CGPoint(x: w * 0.5, y: h * 0.15))
            pediment.addLine(to: CGPoint(x: w * 0.85, y: h * 0.45))
            pediment.closeSubpath()
            ctx.stroke(pediment, with: .color(.black.opacity(0.85)), lineWidth: 1)
            // 5 columns
            for i in 0..<5 {
                let cx = w * (0.20 + 0.15 * CGFloat(i))
                ctx.stroke(
                    Path(CGRect(x: cx, y: h * 0.45, width: 2.4, height: h * 0.45)),
                    with: .color(.black.opacity(0.85)), lineWidth: 0.8
                )
            }
        }
    }
}

private struct SagradaFamilia: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            // 3 conic spires
            for cx in [w * 0.3, w * 0.5, w * 0.7] {
                var spire = Path()
                spire.move(to: CGPoint(x: cx - 6, y: h * 0.9))
                spire.addLine(to: CGPoint(x: cx, y: h * 0.1))
                spire.addLine(to: CGPoint(x: cx + 6, y: h * 0.9))
                spire.closeSubpath()
                ctx.stroke(spire, with: .color(.black.opacity(0.85)), lineWidth: 1)
            }
        }
    }
}

private struct Windmill: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            // Body trapezoid
            var body = Path()
            body.move(to: CGPoint(x: w * 0.35, y: h * 0.95))
            body.addLine(to: CGPoint(x: w * 0.40, y: h * 0.45))
            body.addLine(to: CGPoint(x: w * 0.60, y: h * 0.45))
            body.addLine(to: CGPoint(x: w * 0.65, y: h * 0.95))
            body.closeSubpath()
            ctx.stroke(body, with: .color(.black.opacity(0.85)), lineWidth: 1)
            // Sails (X)
            var sails = Path()
            sails.move(to: CGPoint(x: w * 0.20, y: h * 0.25))
            sails.addLine(to: CGPoint(x: w * 0.80, y: h * 0.65))
            sails.move(to: CGPoint(x: w * 0.80, y: h * 0.25))
            sails.addLine(to: CGPoint(x: w * 0.20, y: h * 0.65))
            ctx.stroke(sails, with: .color(.black.opacity(0.85)), lineWidth: 1.1)
        }
    }
}
