//
//  HistoryView.swift
//  Nomad
//

import SwiftUI
import SwiftData
import UIKit

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<Postcard> { $0.statusRaw != "received" },
        sort: [SortDescriptor(\Postcard.timestamp, order: .reverse)]
    ) private var postcards: [Postcard]
    
    @State private var searchText = ""
    @State private var selectedFilter: PostcardFilter = .all
    @State private var selectedDateFilter: DateFilter = .allTime
    @State private var showSettings = false
    @State private var showStats = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var isExporting = false
    @State private var exportError: String?
    @State private var showCollections = false
    @State private var showTimeline = false
    @State private var showYearReview = false
    @State private var showCollage = false
    @State private var showCustomStamps = false
    
    enum PostcardFilter: String, CaseIterable {
        case all = "All"
        case sent = "Sent"
        case draft = "Drafts"
        case favorites = "Favorites"
    }
    
    enum DateFilter: String, CaseIterable {
        case allTime = "All Time"
        case thisMonth = "This Month"
        case lastThreeMonths = "Last 3 Months"
        case thisYear = "This Year"
        case lastYear = "Last Year"
    }
    
    var filteredPostcards: [Postcard] {
        var result = postcards
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .sent:
            result = result.filter { $0.status == .sent }
        case .draft:
            result = result.filter { $0.status == .draft }
        case .favorites:
            result = result.filter { $0.isFavorite }
        }
        
        // Apply date filter
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedDateFilter {
        case .allTime:
            break
        case .thisMonth:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            result = result.filter { $0.timestamp >= startOfMonth }
        case .lastThreeMonths:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
            result = result.filter { $0.timestamp >= threeMonthsAgo }
        case .thisYear:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            result = result.filter { $0.timestamp >= startOfYear }
        case .lastYear:
            let startOfLastYear = calendar.date(from: DateComponents(year: calendar.component(.year, from: now) - 1, month: 1, day: 1))!
            let startOfThisYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            result = result.filter { $0.timestamp >= startOfLastYear && $0.timestamp < startOfThisYear }
        }
        
        // Apply search
        if !searchText.isEmpty {
            result = result.filter { postcard in
                postcard.locationName.localizedCaseInsensitiveContains(searchText) ||
                postcard.message?.localizedCaseInsensitiveContains(searchText) == true ||
                postcard.recipientUsername?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if postcards.isEmpty {
                    emptyState
                } else if filteredPostcards.isEmpty {
                    searchEmptyState
                } else {
                    List {
                        ForEach(filteredPostcards) { card in
                            NavigationLink {
                                PostcardDetailScreen(postcard: card)
                            } label: {
                                PostcardRowView(postcard: card)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    toggleFavorite(card)
                                } label: {
                                    Label(card.isFavorite ? "Unfavorite" : "Favorite", 
                                          systemImage: card.isFavorite ? "star.slash" : "star.fill")
                                }
                                .tint(card.isFavorite ? .gray : .yellow)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Postcards")
            .searchable(text: $searchText, prompt: "Search postcards...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            showCollections = true
                        } label: {
                            Label("Collections", systemImage: "folder.fill")
                        }
                        
                        Button {
                            showTimeline = true
                        } label: {
                            Label("Travel Timeline", systemImage: "map.fill")
                        }
                        
                        Button {
                            showYearReview = true
                        } label: {
                            Label("Year in Review", systemImage: "calendar")
                        }
                        
                        Button {
                            showCollage = true
                        } label: {
                            Label("Create Collage", systemImage: "square.grid.2x2")
                        }
                        
                        Button {
                            showCustomStamps = true
                        } label: {
                            Label("Custom Stamps", systemImage: "stamp")
                        }
                        
                        Divider()
                        
                        Button {
                            showSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Label("Menu", systemImage: "line.3.horizontal")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showStats = true
                    } label: {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Status") {
                            Picker("Status Filter", selection: $selectedFilter) {
                                ForEach(PostcardFilter.allCases, id: \.self) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                        }
                        
                        Section("Time Period") {
                            Picker("Date Filter", selection: $selectedDateFilter) {
                                ForEach(DateFilter.allCases, id: \.self) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                        }
                        
                        Section {
                            Button {
                                Task { await exportAsPDF() }
                            } label: {
                                Label("Export as PDF", systemImage: "doc.fill")
                            }
                            .disabled(filteredPostcards.isEmpty || isExporting)
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showStats) {
                TravelStatsView()
            }
            .sheet(isPresented: $showCollections) {
                CollectionsView()
            }
            .sheet(isPresented: $showTimeline) {
                LocationTimelineView()
            }
            .sheet(isPresented: $showYearReview) {
                YearInReviewView()
            }
            .sheet(isPresented: $showCollage) {
                CollageView()
            }
            .sheet(isPresented: $showCustomStamps) {
                CustomStampDesignerView()
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Export Failed", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.stack")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text("No Postcards Yet")
                .font(.title2.weight(.semibold))
            Text("Capture a moment with your camera to create your first postcard.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
    
    private var searchEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text("No Results")
                .font(.title2.weight(.semibold))
            Text("Try adjusting your search or filter.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredPostcards[index])
        }
        try? modelContext.save()
    }
    
    private func toggleFavorite(_ postcard: Postcard) {
        postcard.isFavorite.toggle()
        try? modelContext.save()
    }
    
    private func exportAsPDF() async {
        isExporting = true
        defer { isExporting = false }
        
        do {
            let title = "Postcards_\(selectedFilter.rawValue)_\(selectedDateFilter.rawValue)"
            let url = try await PostcardExporter.exportPDF(postcards: filteredPostcards, title: title)
            await MainActor.run {
                exportURL = url
                showShareSheet = true
            }
        } catch {
            await MainActor.run {
                exportError = error.localizedDescription
            }
        }
    }
}

struct PostcardRowView: View {
    let postcard: Postcard

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                thumbnail
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                if postcard.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.yellow)
                        .shadow(color: .black.opacity(0.3), radius: 1)
                        .offset(x: 2, y: -2)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(postcard.locationName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(postcard.timestamp, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if postcard.status == .sent, let recipient = postcard.recipientUsername {
                    Text("Sent to @\(recipient)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else if postcard.status == .draft {
                    Text("Draft")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = postcard.cachedThumbnail {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Color.gray.opacity(0.2)
        }
    }
}

struct PostcardDetailScreen: View {
    let postcard: Postcard
    @Environment(\.modelContext) private var modelContext
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var isExporting = false
    @State private var exportError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PostcardView(postcard: postcard)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    if let message = postcard.message {
                        Text(message)
                            .font(.body)
                    }
                    Text(postcard.timestamp, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle(postcard.locationName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    postcard.isFavorite.toggle()
                    try? modelContext.save()
                } label: {
                    Image(systemName: postcard.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(postcard.isFavorite ? .yellow : .primary)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        Task { await exportAsImage() }
                    } label: {
                        Label("Export as Image", systemImage: "photo")
                    }
                    .disabled(isExporting)
                } label: {
                    if isExporting {
                        ProgressView()
                    } else {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Export Failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }
    
    private func exportAsImage() async {
        isExporting = true
        defer { isExporting = false }
        
        do {
            let url = try await PostcardExporter.exportImage(postcard)
            await MainActor.run {
                exportURL = url
                showShareSheet = true
            }
        } catch {
            await MainActor.run {
                exportError = error.localizedDescription
            }
        }
    }
}
