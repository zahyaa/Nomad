//
//  CustomStampDesigner.swift
//  Nomad
//

import SwiftUI
import SwiftData
import PencilKit

// Model for custom stamps
@Model
final class CustomStamp {
    var id: UUID
    var name: String
    var imageData: Data
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, imageData: Data, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.imageData = imageData
        self.createdAt = createdAt
    }
}

struct CustomStampDesignerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomStamp.createdAt, order: .reverse) private var customStamps: [CustomStamp]
    
    @State private var showDesigner = false
    
    var body: some View {
        NavigationStack {
            Group {
                if customStamps.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(customStamps) { stamp in
                                CustomStampTile(stamp: stamp)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteStamp(stamp)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Custom Stamps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDesigner = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showDesigner) {
                StampCanvasView { image, name in
                    saveStamp(image: image, name: name)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "stamp.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("No Custom Stamps")
                .font(.title2.weight(.semibold))
            Text("Design your own unique stamps to personalize your postcards.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                showDesigner = true
            } label: {
                Label("Create Stamp", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func saveStamp(image: UIImage, name: String) {
        guard let imageData = image.pngData() else { return }
        let stamp = CustomStamp(name: name, imageData: imageData)
        modelContext.insert(stamp)
        try? modelContext.save()
    }
    
    private func deleteStamp(_ stamp: CustomStamp) {
        modelContext.delete(stamp)
        try? modelContext.save()
    }
}

struct CustomStampTile: View {
    let stamp: CustomStamp
    
    var body: some View {
        VStack(spacing: 8) {
            if let image = UIImage(data: stamp.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)
                    .padding(8)
            }
            
            Text(stamp.name)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StampCanvasView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var canvas = PKCanvasView()
    @State private var stampName = ""
    @State private var toolPicker = PKToolPicker()
    
    let onSave: (UIImage, String) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Canvas
                CanvasView(canvas: $canvas, toolPicker: $toolPicker)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                
                // Name input
                Form {
                    Section {
                        TextField("Stamp Name", text: $stampName)
                    } header: {
                        Text("Stamp Details")
                    }
                }
                .frame(height: 120)
            }
            .navigationTitle("Design Stamp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveStamp()
                    }
                    .disabled(stampName.isEmpty || canvas.drawing.bounds.isEmpty)
                }
            }
            .onAppear {
                toolPicker.setVisible(true, forFirstResponder: canvas)
                toolPicker.addObserver(canvas)
                canvas.becomeFirstResponder()
            }
        }
    }
    
    private func saveStamp() {
        let image = canvas.drawing.image(from: canvas.drawing.bounds, scale: 2.0)
        onSave(image, stampName)
        dismiss()
    }
}

struct CanvasView: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    @Binding var toolPicker: PKToolPicker
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .white
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // No updates needed
    }
}

#Preview {
    CustomStampDesignerView()
        .modelContainer(for: [CustomStamp.self], inMemory: true)
}
