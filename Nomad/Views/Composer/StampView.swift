//
//  StampView.swift
//  Nomad
//

import SwiftUI

struct StampView: View {
    let locationName: String
    let date: Date
    let themeRaw: String
    var stateName: String? = nil
    var countryCode: String? = nil

    private var theme: StampTheme {
        StampTheme(rawValue: themeRaw) ?? .city
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    /// "US" → "🇺🇸". Returns nil for invalid codes.
    private var flagEmoji: String? {
        guard let code = countryCode?.uppercased(), code.count == 2 else { return nil }
        var scalarString = ""
        for scalar in code.unicodeScalars {
            guard let regional = Unicode.Scalar(127397 + scalar.value) else { return nil }
            scalarString.append(String(regional))
        }
        return scalarString
    }

    /// "Texas" → "TX", "British Columbia" → "BC". For 1-word states with no
    /// natural abbreviation, takes the first 3 letters uppercased.
    private var stateBadge: String? {
        guard let stateName, !stateName.isEmpty else { return nil }
        // Many `administrativeArea` values are already abbreviations (e.g. "CA").
        if stateName.count <= 3 { return stateName.uppercased() }
        let initials = stateName
            .split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()
        if initials.count >= 2 { return initials }
        return String(stateName.prefix(3)).uppercased()
    }

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if CityLandmark.hasLandmark(for: locationName) {
                    CityLandmark.view(for: locationName)
                } else {
                    themeArtwork
                }
            }
            .frame(height: 30)

            Text(locationName.uppercased())
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            HStack(spacing: 4) {
                if let flag = flagEmoji {
                    Text(flag).font(.system(size: 11))
                }
                if let badge = stateBadge {
                    Text(badge)
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.black.opacity(0.7), lineWidth: 0.8)
                        )
                }
            }
            .frame(height: 14)

            Text(formattedDate.uppercased())
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(width: 96, height: 124)
        .background(Color.white)
        .overlay(
            Rectangle()
                .stroke(Color.black.opacity(0.85), style: StrokeStyle(lineWidth: 1.2, dash: [3, 2]))
        )
        .shadow(color: .black.opacity(0.15), radius: 1.5, x: 0, y: 1)
    }

    @ViewBuilder
    private var themeArtwork: some View {
        switch theme {
        case .city:
            CityStampArt()
        case .coast:
            CoastStampArt()
        case .mountain:
            MountainStampArt()
        case .countryside:
            CountrysideStampArt()
        case .forest:
            ForestStampArt()
        case .desert:
            DesertStampArt()
        case .urban:
            UrbanStampArt()
        case .lake:
            LakeStampArt()
        }
    }
}

private struct CityStampArt: View {
    var body: some View {
        Canvas { context, size in
            let cols = 5, rows = 3
            let stepX = size.width / CGFloat(cols)
            let stepY = size.height / CGFloat(rows)
            for c in 0...cols {
                var path = Path()
                let x = CGFloat(c) * stepX
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.black.opacity(0.7)), lineWidth: 0.6)
            }
            for r in 0...rows {
                var path = Path()
                let y = CGFloat(r) * stepY
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.black.opacity(0.7)), lineWidth: 0.6)
            }
        }
    }
}

private struct CoastStampArt: View {
    var body: some View {
        Canvas { context, size in
            for i in 0..<3 {
                var path = Path()
                let y = size.height * (0.3 + CGFloat(i) * 0.2)
                path.move(to: CGPoint(x: 0, y: y))
                for x in stride(from: CGFloat(0), to: size.width, by: 4) {
                    let dy = sin(x / 6) * 3
                    path.addLine(to: CGPoint(x: x, y: y + dy))
                }
                context.stroke(path, with: .color(.black.opacity(0.7)), lineWidth: 1)
            }
        }
    }
}

private struct MountainStampArt: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height))
            path.addLine(to: CGPoint(x: size.width * 0.3, y: size.height * 0.2))
            path.addLine(to: CGPoint(x: size.width * 0.55, y: size.height * 0.55))
            path.addLine(to: CGPoint(x: size.width * 0.75, y: size.height * 0.1))
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
            context.stroke(path, with: .color(.black.opacity(0.85)), lineWidth: 1.2)
        }
    }
}

private struct CountrysideStampArt: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 5
            for x in stride(from: CGFloat(2), through: size.width, by: spacing) {
                for y in stride(from: CGFloat(2), through: size.height, by: spacing) {
                    let rect = CGRect(x: x, y: y, width: 1.4, height: 1.4)
                    context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.7)))
                }
            }
        }
    }
}

private struct ForestStampArt: View {
    var body: some View {
        Canvas { context, size in
            // Draw trees as triangles
            for i in 0..<4 {
                let x = size.width * (0.15 + CGFloat(i) * 0.23)
                let baseY = size.height * 0.8
                let topY = size.height * 0.2
                
                var path = Path()
                path.move(to: CGPoint(x: x, y: topY))
                path.addLine(to: CGPoint(x: x - 8, y: baseY))
                path.addLine(to: CGPoint(x: x + 8, y: baseY))
                path.closeSubpath()
                
                context.stroke(path, with: .color(.black.opacity(0.75)), lineWidth: 1.0)
            }
        }
    }
}

private struct DesertStampArt: View {
    var body: some View {
        Canvas { context, size in
            // Draw cactus shapes
            for i in 0..<3 {
                let x = size.width * (0.2 + CGFloat(i) * 0.3)
                let baseY = size.height * 0.85
                
                // Main trunk
                var trunk = Path()
                trunk.move(to: CGPoint(x: x, y: baseY))
                trunk.addLine(to: CGPoint(x: x, y: size.height * 0.3))
                context.stroke(trunk, with: .color(.black.opacity(0.8)), lineWidth: 2.5)
                
                // Side arms
                if i != 1 {
                    var arm = Path()
                    let armY = size.height * 0.5
                    arm.move(to: CGPoint(x: x, y: armY))
                    arm.addLine(to: CGPoint(x: x + (i == 0 ? -6 : 6), y: armY))
                    arm.addLine(to: CGPoint(x: x + (i == 0 ? -6 : 6), y: armY - 8))
                    context.stroke(arm, with: .color(.black.opacity(0.8)), lineWidth: 2.0)
                }
            }
        }
    }
}

private struct UrbanStampArt: View {
    var body: some View {
        Canvas { context, size in
            // Draw skyscrapers
            let buildings: [(CGFloat, CGFloat)] = [
                (0.1, 0.4), (0.25, 0.2), (0.4, 0.5), (0.55, 0.15), (0.7, 0.35), (0.85, 0.25)
            ]
            
            for (xPos, heightRatio) in buildings {
                let x = size.width * xPos
                let height = size.height * heightRatio
                let rect = CGRect(x: x - 5, y: size.height - height, width: 10, height: height)
                
                var path = Path(rect)
                context.stroke(path, with: .color(.black.opacity(0.85)), lineWidth: 1.0)
                
                // Add windows
                for row in 0..<3 {
                    for col in 0..<2 {
                        let wx = x - 3 + CGFloat(col) * 3
                        let wy = size.height - height + CGFloat(row) * 4 + 2
                        let window = CGRect(x: wx, y: wy, width: 1.5, height: 2)
                        context.fill(Path(window), with: .color(.black.opacity(0.6)))
                    }
                }
            }
        }
    }
}

private struct LakeStampArt: View {
    var body: some View {
        Canvas { context, size in
            // Draw wavy water surface
            for i in 0..<4 {
                var path = Path()
                let y = size.height * (0.2 + CGFloat(i) * 0.2)
                path.move(to: CGPoint(x: 0, y: y))
                for x in stride(from: CGFloat(0), to: size.width, by: 3) {
                    let dy = sin(x / 5 + CGFloat(i)) * 2
                    path.addLine(to: CGPoint(x: x, y: y + dy))
                }
                context.stroke(path, with: .color(.black.opacity(0.65)), lineWidth: 0.8)
            }
            
            // Add a small boat silhouette
            let boatPath = Path { p in
                let cx = size.width * 0.7
                let cy = size.height * 0.4
                p.move(to: CGPoint(x: cx - 6, y: cy + 3))
                p.addLine(to: CGPoint(x: cx + 6, y: cy + 3))
                p.addLine(to: CGPoint(x: cx + 4, y: cy))
                p.addLine(to: CGPoint(x: cx - 4, y: cy))
                p.closeSubpath()
            }
            context.fill(boatPath, with: .color(.black.opacity(0.7)))
        }
    }
}

#Preview {
    HStack {
        StampView(locationName: "Austin, USA", date: .now, themeRaw: "city",
                  stateName: "Texas", countryCode: "US")
        StampView(locationName: "Big Sur, USA", date: .now, themeRaw: "coast",
                  stateName: "CA", countryCode: "US")
        StampView(locationName: "Zermatt, CH", date: .now, themeRaw: "mountain",
                  stateName: "Valais", countryCode: "CH")
        StampView(locationName: "Tuscany, IT", date: .now, themeRaw: "countryside",
                  stateName: "Tuscany", countryCode: "IT")
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
