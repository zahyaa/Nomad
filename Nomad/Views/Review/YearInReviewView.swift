//
//  YearInReviewView.swift
//  Nomad
//

import SwiftUI
import SwiftData
import CoreLocation

struct YearInReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allPostcards: [Postcard]
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: .now)
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    
    private var years: [Int] {
        let postcardYears = Set(allPostcards.map { Calendar.current.component(.year, from: $0.timestamp) })
        return postcardYears.sorted(by: >)
    }
    
    private var yearPostcards: [Postcard] {
        allPostcards.filter {
            Calendar.current.component(.year, from: $0.timestamp) == selectedYear
        }
    }
    
    private var stats: YearStats {
        YearStats(postcards: yearPostcards)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    heroSection
                    
                    // Stats cards
                    statsGrid
                    
                    // Top locations
                    topLocationsSection
                    
                    // Month breakdown
                    monthBreakdownSection
                    
                    // Highlights
                    highlightsSection
                }
                .padding()
            }
            .navigationTitle("Year in Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if years.count > 1 {
                        Menu {
                            ForEach(years, id: \.self) { year in
                                Button(String(year)) {
                                    selectedYear = year
                                }
                            }
                        } label: {
                            HStack {
                                Text(String(selectedYear))
                                    .font(.headline)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        generateShareImage()
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }
    
    private var heroSection: some View {
        VStack(spacing: 12) {
            Text(String(selectedYear))
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(.tint)
            
            Text("Your Travel Story")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            if yearPostcards.isEmpty {
                Text("No postcards this year")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(value: "\(stats.totalPostcards)", label: "Postcards", icon: "envelope.fill")
            StatCard(value: "\(stats.uniqueLocations)", label: "Places", icon: "mappin.circle.fill")
            StatCard(value: String(format: "%.0f mi", stats.totalDistance), label: "Distance", icon: "arrow.triangle.swap")
            StatCard(value: "\(stats.uniqueCountries)", label: "Countries", icon: "globe")
        }
    }
    
    private var topLocationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Locations")
                .font(.headline)
            
            ForEach(Array(stats.topLocations.prefix(5).enumerated()), id: \.element.location) { index, item in
                HStack {
                    Text("\(index + 1).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    
                    Text(item.location)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(item.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tint)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var monthBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Activity")
                .font(.headline)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(1..<13, id: \.self) { month in
                    let count = stats.monthCounts[month] ?? 0
                    let height = count > 0 ? CGFloat(count) / CGFloat(stats.maxMonthCount) * 100 : 5
                    
                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(.caption2)
                            .foregroundStyle(count > 0 ? Color.primary : Color.clear)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(count > 0 ? Color.accentColor : Color.gray.opacity(0.2))
                            .frame(height: height)
                        
                        Text(Calendar.current.shortMonthSymbols[month - 1].prefix(1))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 140)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.headline)
            
            if let favorite = stats.mostFavorited {
                HighlightRow(
                    icon: "star.fill",
                    title: "Most Loved",
                    subtitle: favorite.locationName
                )
            }
            
            if let busiestMonth = stats.busiestMonth {
                HighlightRow(
                    icon: "calendar.badge.clock",
                    title: "Busiest Month",
                    subtitle: Calendar.current.monthSymbols[busiestMonth - 1]
                )
            }
            
            if let longestJourney = stats.longestJourney {
                HighlightRow(
                    icon: "figure.walk",
                    title: "Longest Journey",
                    subtitle: String(format: "%.0f miles", longestJourney)
                )
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func generateShareImage() {
        // Create a snapshot of the review view
        let renderer = ImageRenderer(content: YearInReviewShareCard(stats: stats, year: selectedYear))
        renderer.scale = 3.0
        
        if let image = renderer.uiImage {
            shareImage = image
            showShareSheet = true
        }
    }
}

struct YearStats {
    let postcards: [Postcard]
    
    var totalPostcards: Int {
        postcards.count
    }
    
    var uniqueLocations: Int {
        Set(postcards.map { $0.locationName }).count
    }
    
    var uniqueCountries: Int {
        Set(postcards.compactMap { $0.countryCode }).count
    }
    
    var totalDistance: Double {
        guard postcards.count > 1 else { return 0 }
        let sorted = postcards.sorted { $0.timestamp < $1.timestamp }
        var distance: Double = 0
        
        for i in 0..<(sorted.count - 1) {
            let from = CLLocation(latitude: sorted[i].latitude, longitude: sorted[i].longitude)
            let to = CLLocation(latitude: sorted[i + 1].latitude, longitude: sorted[i + 1].longitude)
            distance += from.distance(from: to)
        }
        
        return distance / 1609.34 // Convert to miles
    }
    
    var topLocations: [(location: String, count: Int)] {
        let grouped = Dictionary(grouping: postcards, by: { $0.locationName })
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.count > $1.count }
    }
    
    var monthCounts: [Int: Int] {
        Dictionary(grouping: postcards, by: { Calendar.current.component(.month, from: $0.timestamp) })
            .mapValues { $0.count }
    }
    
    var maxMonthCount: Int {
        monthCounts.values.max() ?? 1
    }
    
    var busiestMonth: Int? {
        monthCounts.max(by: { $0.value < $1.value })?.key
    }
    
    var mostFavorited: Postcard? {
        postcards.filter { $0.isFavorite }.first
    }
    
    var longestJourney: Double? {
        guard postcards.count > 1 else { return nil }
        let sorted = postcards.sorted { $0.timestamp < $1.timestamp }
        var maxDistance: Double = 0
        
        for i in 0..<(sorted.count - 1) {
            let from = CLLocation(latitude: sorted[i].latitude, longitude: sorted[i].longitude)
            let to = CLLocation(latitude: sorted[i + 1].latitude, longitude: sorted[i + 1].longitude)
            let distance = from.distance(from: to) / 1609.34
            maxDistance = max(maxDistance, distance)
        }
        
        return maxDistance > 0 ? maxDistance : nil
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.tint)
            
            Text(value)
                .font(.title.bold())
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HighlightRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(subtitle)
                    .font(.subheadline.weight(.medium))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct YearInReviewShareCard: View {
    let stats: YearStats
    let year: Int
    
    var body: some View {
        VStack(spacing: 24) {
            Text("\(year)")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.tint)
            
            Text("My Travel Year")
                .font(.title2)
            
            HStack(spacing: 32) {
                VStack {
                    Text("\(stats.totalPostcards)")
                        .font(.largeTitle.bold())
                    Text("Postcards")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Text("\(stats.uniqueLocations)")
                        .font(.largeTitle.bold())
                    Text("Places")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Text(String(format: "%.0f", stats.totalDistance))
                        .font(.largeTitle.bold())
                    Text("Miles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            
            Text("Made with Nomad")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(40)
        .frame(width: 400, height: 400)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    YearInReviewView()
        .modelContainer(for: [Postcard.self], inMemory: true)
}
