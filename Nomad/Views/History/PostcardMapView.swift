//
//  PostcardMapView.swift
//  Nomad
//

import SwiftUI
import SwiftData
import MapKit
import UIKit

struct PostcardMapView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\Postcard.timestamp, order: .reverse)])
    private var postcards: [Postcard]

    @State private var selected: Postcard?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapStyle: MapStyleOption = .standard

    enum MapStyleOption: String, CaseIterable {
        case standard = "Standard"
        case satellite = "Satellite"
        case hybrid = "Hybrid"
    }

    private var validPostcards: [Postcard] {
        postcards.filter { $0.latitude != 0 || $0.longitude != 0 }
    }
    
    private var currentMapStyle: MapStyle {
        switch mapStyle {
        case .standard:
            return .standard(elevation: .realistic)
        case .satellite:
            return .imagery(elevation: .realistic)
        case .hybrid:
            return .hybrid(elevation: .realistic)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if validPostcards.isEmpty {
                    emptyState
                } else {
                    Map(position: $cameraPosition, selection: $selected) {
                        ForEach(validPostcards) { card in
                            Annotation(card.locationName, coordinate: card.coordinate, anchor: .bottom) {
                                PostcardPin(postcard: card)
                            }
                            .tag(card)
                        }
                    }
                    .mapStyle(currentMapStyle)
                    .sheet(item: $selected) { card in
                        PostcardMapDetailSheet(postcard: card)
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
                    }
                    .safeAreaInset(edge: .bottom) {
                        HStack {
                            Menu {
                                Picker("Map Style", selection: $mapStyle) {
                                    ForEach(MapStyleOption.allCases, id: \.self) { style in
                                        Text(style.rawValue).tag(style)
                                    }
                                }
                            } label: {
                                Label("Map Style", systemImage: "map")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.regularMaterial, in: Capsule())
                            }
                            
                            Spacer()
                            
                            Button {
                                fitAllPostcards()
                            } label: {
                                Label("Show All", systemImage: "arrow.up.left.and.arrow.down.right")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(.regularMaterial, in: Capsule())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Travel Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func fitAllPostcards() {
        guard !validPostcards.isEmpty else { return }
        
        let coordinates = validPostcards.map { $0.coordinate }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(maxLat - minLat, 0.01) * 1.5,
            longitudeDelta: max(maxLon - minLon, 0.01) * 1.5
        )
        
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text("No Locations Yet")
                .font(.title2.weight(.semibold))
            Text("Capture postcards with location data to see them on the map.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}

private struct PostcardPin: View {
    let postcard: Postcard

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let image = postcard.cachedThumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.gray.opacity(0.3)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white, lineWidth: 2)
            )
            .adaptiveShadow(radius: 2, y: 1)

            Triangle()
                .fill(Color.white)
                .frame(width: 8, height: 5)
                .offset(y: 5)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private struct PostcardMapDetailSheet: View {
    let postcard: Postcard

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PostcardView(postcard: postcard)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 6) {
                    Text(postcard.locationName)
                        .font(.title3.bold())
                    Text(postcard.timestamp, format: .dateTime.month(.wide).year())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let message = postcard.message, !message.isEmpty {
                        Text(message)
                            .font(.body)
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
            .padding(.top)
        }
    }
}

private extension Postcard {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
