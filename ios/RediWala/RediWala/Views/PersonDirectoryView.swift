import PhotosUI
import SwiftUI

/// Create / edit / archive / favorite people — local persistence for demo authenticity.
struct PersonDirectoryView: View {
    @ObservedObject private var store = PersonDirectoryStore.shared
    @State private var newName = ""
    @State private var editing: PersonRecord?
    @State private var photoTargetID: String?
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Name", text: $newName)
                    Button("Add") {
                        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        _ = store.create(name: trimmed)
                        newName = ""
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Text("Create person")
            }

            Section("People") {
                ForEach(store.activePeople) { person in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            personAvatar(person)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(person.displayName)
                                    .font(.headline)
                                if let business = person.businessName, !business.isEmpty {
                                    Text(business)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Text(person.neighborhood.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            Button {
                                store.toggleFavorite(id: person.id)
                            } label: {
                                Image(systemName: person.isFavorite ? "star.fill" : "star")
                                    .foregroundStyle(person.isFavorite ? AppTheme.accent : AppTheme.textSecondary)
                            }
                            .buttonStyle(.borderless)
                        }

                        HStack(spacing: 12) {
                            Button("Rename") { editing = person }
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Text("Photo")
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                photoTargetID = person.id
                            })
                            Button("Archive", role: .destructive) {
                                store.archive(id: person.id)
                            }
                        }
                        .font(.caption.weight(.semibold))
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            store.delete(id: person.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("People")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Rename", isPresented: Binding(
            get: { editing != nil },
            set: { if !$0 { editing = nil } }
        )) {
            TextField("Name", text: Binding(
                get: { editing?.displayName ?? "" },
                set: { editing?.displayName = $0 }
            ))
            Button("Save") {
                if let editing {
                    store.rename(id: editing.id, to: editing.displayName)
                }
                editing = nil
            }
            Button("Cancel", role: .cancel) { editing = nil }
        }
        .task(id: selectedPhotoItem) {
            guard let item = selectedPhotoItem, let id = photoTargetID else { return }
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                _ = store.replacePhoto(id: id, image: image)
            }
            selectedPhotoItem = nil
            photoTargetID = nil
        }
    }

    @ViewBuilder
    private func personAvatar(_ person: PersonRecord) -> some View {
        if let path = person.photoLocalPath,
           let image = UIImage(contentsOfFile: path) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(AppTheme.primary.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(String(person.displayName.prefix(1)))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.primary)
                }
        }
    }
}
