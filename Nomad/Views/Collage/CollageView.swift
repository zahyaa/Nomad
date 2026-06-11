//
//  CollageView.swift
//  Nomad
//

import SwiftUI
import SwiftData

enum CollageLayout: String, CaseIterable, Identifiable {
    case grid2x2 = "2x2 Grid"
    case grid3x3 = "3x3 Grid"
    case filmStrip = "Film Strip"
    case freeform = "Freeform"
    
    var id: String { rawValue }
    
    var maxPostcards: Int {
        switch self {
        case .grid2x2: return 4
        case .grid3x3: return 9
        case .filmStrip: return 5
        case .freeform: return 8
        }
    }
}

struct CollageView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Postcard.timestamp, order: .reverse) private var allPostcards: [Postcard]
    
    @State private var selectedPostcards: [Postcard] = []
    @State private var layout: CollageLayout = .grid2x2
    @State private var titleText = ""
    @State private var showPostcardPicker = false
    @State private var showShareSheet = false
    @State private var generatedCollage: UIImage?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Layout picker
                Picker("Layout", selection: $layout) {
                    ForEach(CollageLayout.allCases) { layout in
                        Text(layout.rawValue).tag(layout)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Title input
                TextField("Collage Title (optional)", text: $titleText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                // Preview
                ScrollView {
                    CollagePreview(
                        postcards: selectedPostcards,
                        layout: layout,
                        title: titleText
                    )
                    .padding()
                }
                
                // Selected postcards
                if !selectedPostcards.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(selectedPostcards.enumerated()), id: \.element.id) { index, postcard in
                                if let thumbnail = postcard.cachedThumbnail {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(alignment: .topTrailing) {
                                            Button {
                                                selectedPostcards.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                                    .foregroundStyle(.white)
                                                    .background(Circle().fill(.black.opacity(0.5)))
                                            }
                                            .offset(x: 5, y: -5)
                                        }
                                }
                            }
                            
                            if selectedPostcards.count < layout.maxPostcards {
                                Button {
                                    showPostcardPicker = true
                                } label: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                        .frame(width: 60, height: 60)
                                        .overlay {
                                            Image(systemName: "plus")
                                                .font(.title3)
                                                .foregroundStyle(.tint)
                                        }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 80)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 16) {
                    Button {
                        showPostcardPicker = true
                    } label: {
                        Label("Add Postcards", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedPostcards.count >= layout.maxPostcards)
                    
                    Button {
                        generateCollage()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedPostcards.count < 2)
                }
                .padding()
            }
            .navigationTitle("Create Collage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showPostcardPicker) {
                PostcardPickerView(
                    selectedPostcards: $selectedPostcards,
                    maxSelection: layout.maxPostcards,
                    availablePostcards: allPostcards
                )
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = generatedCollage {
                    ShareSheet(items: [image, "Created with Nomad"])
                }
            }
        }
    }
    
    private func generateCollage() {
        let renderer = ImageRenderer(content: CollagePreview(
            postcards: selectedPostcards,
            layout: layout,
            title: titleText
        ).frame(width: 1200, height: layout == .filmStrip ? 400 : 1200))
        renderer.scale = 3.0
        
        if let image = renderer.uiImage {
            generatedCollage = image
            showShareSheet = true
        }
    }
}

struct CollagePreview: View {
    let postcards: [Postcard]
    let layout: CollageLayout
    let title: String
    
    var body: some View {
        VStack(spacing: 16) {
            if !title.isEmpty {
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
            }
            
            switch layout {
            case .grid2x2:
                Grid2x2Layout(postcards: postcards)
            case .grid3x3:
                Grid3x3Layout(postcards: postcards)
            case .filmStrip:
                FilmStripLayout(postcards: postcards)
            case .freeform:
                FreeformLayout(postcards: postcards)
            }
        }
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct Grid2x2Layout: View {
    let postcards: [Postcard]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(Array(postcards.prefix(4)), id: \.id) { postcard in
                CollagePostcardTile(postcard: postcard)
                    .aspectRatio(1, contentMode: .fill)
            }
        }
    }
}

struct Grid3x3Layout: View {
    let postcards: [Postcard]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(Array(postcards.prefix(9)), id: \.id) { postcard in
                CollagePostcardTile(postcard: postcard)
                    .aspectRatio(1, contentMode: .fill)
            }
        }
    }
}

struct FilmStripLayout: View {
    let postcards: [Postcard]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(postcards.prefix(5)), id: \.id) { postcard in
                CollagePostcardTile(postcard: postcard)
                    .aspectRatio(0.7, contentMode: .fill)
            }
        }
    }
}

struct FreeformLayout: View {
    let postcards: [Postcard]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if postcards.count > 0 {
                    CollagePostcardTile(postcard: postcards[0])
                        .aspectRatio(1.5, contentMode: .fill)
                }
                if postcards.count > 1 {
                    CollagePostcardTile(postcard: postcards[1])
                        .aspectRatio(1, contentMode: .fill)
                }
            }
            
            HStack(spacing: 8) {
                if postcards.count > 2 {
                    CollagePostcardTile(postcard: postcards[2])
                        .aspectRatio(1, contentMode: .fill)
                }
                if postcards.count > 3 {
                    CollagePostcardTile(postcard: postcards[3])
                        .aspectRatio(1, contentMode: .fill)
                }
                if postcards.count > 4 {
                    CollagePostcardTile(postcard: postcards[4])
                        .aspectRatio(1, contentMode: .fill)
                }
            }
            
            if postcards.count > 5 {
                HStack(spacing: 8) {
                    ForEach(Array(postcards[5..<min(8, postcards.count)]), id: \.id) { postcard in
                        CollagePostcardTile(postcard: postcard)
                            .aspectRatio(1, contentMode: .fill)
                    }
                }
            }
        }
    }
}

struct CollagePostcardTile: View {
    let postcard: Postcard
    
    var body: some View {
        if let image = postcard.cachedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
        }
    }
}

struct PostcardPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPostcards: [Postcard]
    let maxSelection: Int
    let availablePostcards: [Postcard]
    
    @State private var tempSelection: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(availablePostcards) { postcard in
                        if let thumbnail = postcard.cachedThumbnail {
                            Button {
                                toggleSelection(postcard)
                            } label: {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay {
                                        if tempSelection.contains(postcard.id) {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.accentColor, lineWidth: 3)
                                            
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(.tint)
                                                .background(Circle().fill(.white))
                                                .offset(x: 40, y: -40)
                                        }
                                    }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Postcards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        applySelection()
                    }
                }
            }
            .onAppear {
                tempSelection = Set(selectedPostcards.map { $0.id })
            }
        }
    }
    
    private func toggleSelection(_ postcard: Postcard) {
        if tempSelection.contains(postcard.id) {
            tempSelection.remove(postcard.id)
        } else if tempSelection.count < maxSelection {
            tempSelection.insert(postcard.id)
        }
    }
    
    private func applySelection() {
        selectedPostcards = availablePostcards.filter { tempSelection.contains($0.id) }
        dismiss()
    }
}

#Preview {
    CollageView()
        .modelContainer(for: [Postcard.self], inMemory: true)
}
