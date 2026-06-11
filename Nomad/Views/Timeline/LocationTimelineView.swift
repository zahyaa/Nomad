//
//  LocationTimelineView.swift
//  Nomad
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct LocationTimelineView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Postcard.timestamp, order: .forward) private var allPostcards: [Postcard]
    
    @State private var selectedPostcard: Postcard?
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showAnimation = false
    
    private var validPostcards: [Postcard] {
        allPostcards.filter { $0.latitude != 0 || $0.longitude != 0 }
    }
    
    private var totalDistance: Double {
        guard validPostcards.count > 1 else { return 0 }
        var distance: Double = 0
        
        for i in 0..<(validPostcards.count - 1) {
            let from = CLLocation(latitude: validPostcards[i].latitude, longitude: validPostcards[i].longitude)
            let to = CLLocation(latitude: validPostcards[i + 1].latitude, longitude: validPostcards[i + 1].longitude)
            distance += from.distance(from: to)
        }
        
        return distance / 1609.34 // Convert to miles
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if validPostcards.isEmpty {
                    emptyState
                } else {
                    Map(position: $cameraPosition, selection: $selectedPostcard) {
                        // Draw path between locations
                        if validPostcards.count > 1 {
                            MapPolyline(coordinates: validPostcards.map { 
                                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                            })
                            .stroke(.tint, lineWidth: 3)
                        }
                        
                        // Markers for each postcard
                        ForEach(Array(validPostcards.enumerated()), id: \.element.id) { index, postcard in
                            Annotation("", coordinate: CLLocationCoordinate2D(latitude: postcard.latitude, longitude: postcard.longitude)) {
                                TimelineMarker(postcard: postcard, index: index + 1, isFirst: index == 0, isLast: index == validPostcards.count - 1)
                            }
                            .tag(postcard)
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    
                    // Timeline scrubber at bottom
                    TimelineScrollView(postcards: validPostcards, selectedPostcard: $selectedPostcard) { postcard in
                        focusOn(postcard)
                    }
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Travel Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(validPostcards.count) stops")
                            .font(.caption.weight(.semibold))
                        if totalDistance > 0 {
                            Text(String(format: "%.0f mi", totalDistance))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedPostcard) { postcard in
                PostcardDetailSheet(postcard: postcard)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text("No Journey Yet")
                .font(.title2.weight(.semibold))
            Text("Start capturing postcards with location data to see your travel timeline.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
    
    private func focusOn(_ postcard: Postcard) {
        let coordinate = CLLocationCoordinate2D(latitude: postcard.latitude, longitude: postcard.longitude)
        cameraPosition = .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }
}

struct TimelineMarker: View {
    let postcard: Postcard
    let index: Int
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isFirst ? Color.green : (isLast ? Color.red : Color.accentColor))
                .frame(width: 32, height: 32)
            
            if isFirst {
                Image(systemName: "figure.walk")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            } else if isLast {
                Image(systemName: "flag.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            } else {
                Text("\(index)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 3)
    }
}

struct TimelineScrollView: View {
    let postcards: [Postcard]
    @Binding var selectedPostcard: Postcard?
    let onTap: (Postcard) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(postcards.enumerated()), id: \.element.id) { index, postcard in
                    TimelineCard(postcard: postcard, index: index + 1)
                        .onTapGesture {
                            selectedPostcard = postcard
                            onTap(postcard)
                        }
                }
            }
            .padding()
        }
        .frame(height: 120)
    }
}

struct TimelineCard: View {
    let postcard: Postcard
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 16, height: 16)
                    .overlay {
                        Text("\(index)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    }
                
                Text(postcard.locationName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            
            Text(postcard.timestamp.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            if let image = postcard.cachedThumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(8)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct PostcardDetailSheet: View {
    let postcard: Postcard
    
    var body: some View {
        VStack(spacing: 16) {
            PostcardView(postcard: postcard)
                .padding()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(postcard.locationName)
                    .font(.title3.bold())
                
                Text(postcard.timestamp.formatted(date: .long, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let message = postcard.message {
                    Text(message)
                        .font(.body)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Spacer()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    LocationTimelineView()
        .modelContainer(for: [Postcard.self], inMemory: true)
}
