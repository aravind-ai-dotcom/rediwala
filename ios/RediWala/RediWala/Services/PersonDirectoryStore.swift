import Combine
import Foundation
import UIKit

/// Local curated people directory — create / edit / archive / favorite / photo.
/// Used for demo authenticity and lasting personal context.
struct PersonRecord: Codable, Equatable, Identifiable {
    var id: String
    var displayName: String
    var neighborhoodRaw: String
    var languageRaw: String
    var roleRaw: String
    var businessName: String?
    var categoryRaw: String?
    var notes: String
    var isFavorite: Bool
    var isArchived: Bool
    var photoLocalPath: String?
    var linkedVendorID: String?
    var createdAt: Date
    var updatedAt: Date

    var neighborhood: PilotNeighborhood {
        PilotNeighborhood(rawValue: neighborhoodRaw) ?? .westMambalam
    }

    static func makeNew(name: String, neighborhood: PilotNeighborhood) -> PersonRecord {
        let now = Date()
        return PersonRecord(
            id: UUID().uuidString,
            displayName: name,
            neighborhoodRaw: neighborhood.rawValue,
            languageRaw: AppLanguage.tamil.rawValue,
            roleRaw: "neighbor",
            businessName: nil,
            categoryRaw: nil,
            notes: "",
            isFavorite: false,
            isArchived: false,
            photoLocalPath: nil,
            linkedVendorID: nil,
            createdAt: now,
            updatedAt: now
        )
    }
}

@MainActor
final class PersonDirectoryStore: ObservableObject {
    static let shared = PersonDirectoryStore()

    @Published private(set) var people: [PersonRecord] = []

    private let key = "customer.person_directory.v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([PersonRecord].self, from: data) {
            people = decoded
        } else {
            seedDemoPeopleIfEmpty()
        }
    }

    var activePeople: [PersonRecord] {
        people.filter { !$0.isArchived }.sorted { $0.displayName < $1.displayName }
    }

    func create(name: String, neighborhood: PilotNeighborhood = .westMambalam) -> PersonRecord {
        let person = PersonRecord.makeNew(name: name, neighborhood: neighborhood)
        people.append(person)
        persist()
        return person
    }

    func update(_ person: PersonRecord) {
        guard let index = people.firstIndex(where: { $0.id == person.id }) else { return }
        var next = person
        next.updatedAt = Date()
        people[index] = next
        persist()
    }

    func rename(id: String, to name: String) {
        guard let index = people.firstIndex(where: { $0.id == id }) else { return }
        people[index].displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        people[index].updatedAt = Date()
        persist()
    }

    func archive(id: String) {
        guard let index = people.firstIndex(where: { $0.id == id }) else { return }
        people[index].isArchived = true
        people[index].updatedAt = Date()
        persist()
    }

    func delete(id: String) {
        if let path = people.first(where: { $0.id == id })?.photoLocalPath {
            try? FileManager.default.removeItem(atPath: path)
        }
        people.removeAll { $0.id == id }
        persist()
    }

    func toggleFavorite(id: String) {
        guard let index = people.firstIndex(where: { $0.id == id }) else { return }
        people[index].isFavorite.toggle()
        people[index].updatedAt = Date()
        persist()
    }

    @discardableResult
    func replacePhoto(id: String, image: UIImage) -> Bool {
        guard let index = people.firstIndex(where: { $0.id == id }),
              let data = image.jpegData(compressionQuality: 0.82) else { return false }
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PersonPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(id).jpg")
        do {
            try data.write(to: url, options: .atomic)
            people[index].photoLocalPath = url.path
            people[index].updatedAt = Date()
            persist()
            return true
        } catch {
            return false
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(people) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func seedDemoPeopleIfEmpty() {
        let seeds: [(String, PilotNeighborhood, String?, String?)] = [
            ("Murugan", .westMambalam, "Murugan Fresh Cart", "vegetables"),
            ("Lakshmi", .westMambalam, "Lakshmi Flowers", "flowers"),
            ("Siva", .kodambakkam, "Siva Ironing", "ironing"),
            ("Revathi", .annaNagar, "Revathi Milk Round", "milk"),
            ("Vasanthi", .mylapore, "Vasanthi Tailor", "tailor"),
            ("Babu", .velachery, "Babu Laundry Pickup", "laundry")
        ]
        people = seeds.map { name, hood, business, category in
            var person = PersonRecord.makeNew(name: name, neighborhood: hood)
            person.businessName = business
            person.categoryRaw = category
            person.roleRaw = "vendor"
            person.isFavorite = category == "milk" || category == "flowers"
            return person
        }
        persist()
    }
}
