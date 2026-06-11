//
//  TravelStatsView.swift
//  Nomad
//

import SwiftUI
import SwiftData
import CoreLocation

struct TravelStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allPostcards: [Postcard]
    
    private var sentPostcards: [Postcard] {
        allPostcards.filter { $0.status == .sent }
    }
    
    private var totalSent: Int {
        sentPostcards.count
    }
    
    private var uniqueLocations: Int {
        Set(sentPostcards.map { $0.locationName }).count
    }
    
    private var favoriteCount: Int {
        allPostcards.filter { $0.isFavorite }.count
    }
    
    private var uniqueCountries: Int {
        Set(sentPostcards.compactMap { $0.countryCode }).count
    }
    
    private var mostFrequentRecipient: (username: String, count: Int)? {
        let recipients = Dictionary(grouping: sentPostcards.filter { $0.recipientUsername != nil }) { 
            $0.recipientUsername! 
        }.mapValues { $0.count }
        
        guard let max = recipients.max(by: { $0.value < $1.value }) else { return nil }
        return (max.key, max.value)
    }
    
    private var currentStreak: Int {
        guard !sentPostcards.isEmpty else { return 0 }
        let sorted = sentPostcards.sorted { $0.timestamp > $1.timestamp }
        let calendar = Calendar.current
        var streak = 0
        var lastDate = calendar.startOfDay(for: Date())
        
        for postcard in sorted {
            let postcardDate = calendar.startOfDay(for: postcard.timestamp)
            let daysDiff = calendar.dateComponents([.day], from: postcardDate, to: lastDate).day ?? 0
            
            if daysDiff == 0 || daysDiff == 1 {
                if daysDiff == 1 || streak == 0 {
                    streak += 1
                }
                lastDate = postcardDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private var busiestMonth: (month: String, count: Int)? {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sentPostcards) { postcard -> String in
            let components = calendar.dateComponents([.month], from: postcard.timestamp)
            return calendar.monthSymbols[components.month! - 1]
        }.mapValues { $0.count }
        
        guard let max = grouped.max(by: { $0.value < $1.value }) else { return nil }
        return (max.key, max.value)
    }
    
    private var longestSingleJourney: Double? {
        guard sentPostcards.count > 1 else { return nil }
        let sortedByDate = sentPostcards.sorted { $0.timestamp < $1.timestamp }
        var maxDistance: Double = 0
        
        for i in 0..<(sortedByDate.count - 1) {
            let from = CLLocation(latitude: sortedByDate[i].latitude, longitude: sortedByDate[i].longitude)
            let to = CLLocation(latitude: sortedByDate[i + 1].latitude, longitude: sortedByDate[i + 1].longitude)
            let distance = from.distance(from: to) / 1609.34
            maxDistance = max(maxDistance, distance)
        }
        
        return maxDistance > 0 ? maxDistance : nil
    }
    
    private var mostVisitedLocation: String? {
        let locationCounts = Dictionary(grouping: sentPostcards) { $0.locationName }
            .mapValues { $0.count }
        return locationCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private var mostUsedTheme: String? {
        let themeCounts = Dictionary(grouping: sentPostcards) { $0.stampTheme }
            .mapValues { $0.count }
        return themeCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private var totalDistanceTraveled: Double {
        guard sentPostcards.count > 1 else { return 0 }
        var distance: Double = 0
        let sortedByDate = sentPostcards.sorted { $0.timestamp < $1.timestamp }
        
        for i in 0..<(sortedByDate.count - 1) {
            let from = CLLocation(
                latitude: sortedByDate[i].latitude,
                longitude: sortedByDate[i].longitude
            )
            let to = CLLocation(
                latitude: sortedByDate[i + 1].latitude,
                longitude: sortedByDate[i + 1].longitude
            )
            distance += from.distance(from: to)
        }
        return distance / 1609.34 // Convert meters to miles
    }
    
    private var monthlyActivity: [(month: String, count: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sentPostcards) { postcard -> String in
            let components = calendar.dateComponents([.year, .month], from: postcard.timestamp)
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            let date = calendar.date(from: components) ?? postcard.timestamp
            return formatter.string(from: date)
        }
        
        return grouped.map { (month: $0.key, count: $0.value.count) }
            .sorted { $0.month < $1.month }
            .suffix(6)
            .map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.tint)
                        Text("Your Travel Stats")
                            .font(.title.bold())
                    }
                    .padding(.top)
                    
                    // Quick Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        TravelStatCard(
                            value: "\(totalSent)",
                            label: "Postcards Sent",
                            icon: "paperplane.fill",
                            color: .blue
                        )
                        
                        TravelStatCard(
                            value: "\(uniqueLocations)",
                            label: "Locations",
                            icon: "mappin.circle.fill",
                            color: .green
                        )
                        
                        TravelStatCard(
                            value: "\(uniqueCountries)",
                            label: "Countries",
                            icon: "globe",
                            color: .teal
                        )
                        
                        TravelStatCard(
                            value: String(format: "%.0f mi", totalDistanceTraveled),
                            label: "Distance",
                            icon: "location.fill",
                            color: .orange
                        )
                        
                        TravelStatCard(
                            value: "\(favoriteCount)",
                            label: "Favorites",
                            icon: "star.fill",
                            color: .yellow
                        )
                        
                        TravelStatCard(
                            value: "\(currentStreak)",
                            label: "Day Streak",
                            icon: "flame.fill",
                            color: .red
                        )
                    }
                    .padding(.horizontal)
                    
                    // Insights
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Insights")
                            .font(.title2.bold())
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            if let location = mostVisitedLocation {
                                InsightRow(
                                    icon: "trophy.fill",
                                    label: "Most Visited",
                                    value: location,
                                    color: .purple
                                )
                            }
                            
                            if let theme = mostUsedTheme {
                                InsightRow(
                                    icon: "photo.fill",
                                    label: "Favorite Theme",
                                    value: theme.capitalized,
                                    color: .pink
                                )
                            }
                            
                            if sentPostcards.count > 0 {
                                let avgPerMonth = Double(sentPostcards.count) / max(1, Double(monthlyActivity.count))
                                InsightRow(
                                    icon: "calendar",
                                    label: "Avg Per Month",
                                    value: String(format: "%.1f postcards", avgPerMonth),
                                    color: .teal
                                )
                            }
                            
                            if let recipient = mostFrequentRecipient {
                                InsightRow(
                                    icon: "person.fill",
                                    label: "Most Frequent Recipient",
                                    value: "\(recipient.username) (\(recipient.count))",
                                    color: .indigo
                                )
                            }
                            
                            if let month = busiestMonth {
                                InsightRow(
                                    icon: "calendar.badge.clock",
                                    label: "Busiest Month",
                                    value: "\(month.month) (\(month.count) postcards)",
                                    color: .cyan
                                )
                            }
                            
                            if let journey = longestSingleJourney {
                                InsightRow(
                                    icon: "figure.walk",
                                    label: "Longest Single Journey",
                                    value: String(format: "%.0f miles", journey),
                                    color: .brown
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Monthly Activity Chart
                    if !monthlyActivity.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activity")
                                .font(.title2.bold())
                                .padding(.horizontal)
                            
                            ActivityChart(data: monthlyActivity)
                                .frame(height: 200)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct TravelStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
            
            Text(value)
                .font(.title.bold())
                .foregroundStyle(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InsightRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
            }
            
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ActivityChart: View {
    let data: [(month: String, count: Int)]
    
    private var maxCount: Int {
        data.map { $0.count }.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data, id: \.month) { item in
                    VStack(spacing: 4) {
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(height: CGFloat(item.count) / CGFloat(maxCount) * 140)
                        
                        Text("\(item.count)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        Text(item.month.prefix(3))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    TravelStatsView()
        .modelContainer(for: [Postcard.self], inMemory: true)
}
