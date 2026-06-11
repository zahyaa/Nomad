//
//  CollectionsView.swift
//  Nomad
//

import SwiftUI
import SwiftData

struct CollectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PostcardCollection.createdAt, order: .reverse) private var collections: [PostcardCollection]
    
    @State private var showNewCollectionSheet = false
    @State private var newCollectionName = ""
    @State private var newCollectionDesc = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if collections.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(collections) { collection in
                                NavigationLink {
                                    CollectionDetailView(collection: collection)
                                } label: {
                                    CollectionCard(collection: collection)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewCollectionSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewCollectionSheet) {
                NewCollectionSheet(
                    name: $newCollectionName,
                    description: $newCollectionDesc,
                    onCreate: {
                        createCollection()
                    }
                )
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.fill.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("No Collections Yet")
                .font(.title2.weight(.semibold))
            Text("Create collections to organize your postcards by trip, theme, or any way you like.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                showNewCollectionSheet = true
            } label: {
                Label("Create Collection", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func createCollection() {
        let collection = PostcardCollection(name: newCollectionName, desc: newCollectionDesc.isEmpty ? nil : newCollectionDesc)
        modelContext.insert(collection)
        try? modelContext.save()
        
        newCollectionName = ""
        newCollectionDesc = ""
        showNewCollectionSheet = false
    }
}

struct CollectionCard: View {
    let collection: PostcardCollection
    
    private var postcardCount: Int {
        collection.postcards?.count ?? 0
    }
    
    private var coverImage: UIImage? {
        if let data = collection.coverImageData {
            return UIImage(data: data)
        }
        if let firstPostcard = collection.postcards?.first {
            return firstPostcard.cachedThumbnail
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let image = coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 140)
                        .overlay {
                            Image(systemName: "photo.stack")
                                .font(.largeTitle)
                                .foregroundStyle(.tertiary)
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text("\(postcardCount) postcards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }
}

struct NewCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var name: String
    @Binding var description: String
    let onCreate: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Collection Name", text: $name)
                }
                
                Section {
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Description")
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct CollectionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var collection: PostcardCollection
    @Query private var allPostcards: [Postcard]
    
    @State private var showAddPostcards = false
    @State private var showEditSheet = false
    @State private var editName: String = ""
    @State private var editDesc: String = ""
    
    private var postcards: [Postcard] {
        collection.postcards ?? []
    }
    
    var body: some View {
        List {
            Section {
                if let desc = collection.desc, !desc.isEmpty {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Label("\(postcards.count)", systemImage: "photo.stack")
                    Spacer()
                    Label(collection.createdAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Section {
                ForEach(postcards) { postcard in
                    NavigationLink {
                        PostcardDetailScreen(postcard: postcard)
                    } label: {
                        PostcardRowView(postcard: postcard)
                    }
                }
                .onDelete(perform: removePostcards)
            } header: {
                Text("Postcards")
            }
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showAddPostcards = true
                    } label: {
                        Label("Add Postcards", systemImage: "plus")
                    }
                    
                    Button {
                        editName = collection.name
                        editDesc = collection.desc ?? ""
                        showEditSheet = true
                    } label: {
                        Label("Edit Collection", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        deleteCollection()
                    } label: {
                        Label("Delete Collection", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddPostcards) {
            AddPostcardsToCollectionView(collection: collection, availablePostcards: availablePostcards())
        }
        .sheet(isPresented: $showEditSheet) {
            EditCollectionSheet(collection: collection, name: $editName, description: $editDesc)
        }
    }
    
    private func availablePostcards() -> [Postcard] {
        let existingIDs = Set(postcards.map { $0.id })
        return allPostcards.filter { !existingIDs.contains($0.id) }
    }
    
    private func removePostcards(at offsets: IndexSet) {
        for index in offsets {
            if var collections = postcards[index].collections {
                collections.removeAll { $0.id == collection.id }
                postcards[index].collections = collections
            }
        }
        try? modelContext.save()
    }
    
    private func deleteCollection() {
        modelContext.delete(collection)
        try? modelContext.save()
    }
}

struct AddPostcardsToCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var collection: PostcardCollection
    let availablePostcards: [Postcard]
    
    @State private var selectedPostcards: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            List(availablePostcards, selection: $selectedPostcards) { postcard in
                PostcardRowView(postcard: postcard)
                    .tag(postcard.id)
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Add Postcards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add (\(selectedPostcards.count))") {
                        addSelected()
                    }
                    .disabled(selectedPostcards.isEmpty)
                }
            }
        }
    }
    
    private func addSelected() {
        for postcardID in selectedPostcards {
            if let postcard = availablePostcards.first(where: { $0.id == postcardID }) {
                if postcard.collections == nil {
                    postcard.collections = []
                }
                postcard.collections?.append(collection)
            }
        }
        try? modelContext.save()
        dismiss()
    }
}

struct EditCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var collection: PostcardCollection
    @Binding var name: String
    @Binding var description: String
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Collection Name", text: $name)
                }
                
                Section {
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Description")
                }
            }
            .navigationTitle("Edit Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        collection.name = name
                        collection.desc = description.isEmpty ? nil : description
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    CollectionsView()
        .modelContainer(for: [PostcardCollection.self, Postcard.self], inMemory: true)
}
