import CoreLocation
import Foundation

/// Expands the local catalog to 80+ realistic Chennai neighborhood vendors.
/// Each seller gets a unique given name so the catalog never feels cloned.
enum ExpandedChennaiVendors {
    static var sellers: [Seller] {
        var result: [Seller] = []
        var index = 0
        var usedNames = Set<String>()

        for template in templates {
            for (offset, hood) in template.neighborhoods.enumerated() {
                index += 1
                let id = "\(template.idPrefix)_\(hood.rawValue)_\(offset)"
                let center = hood.coordinate
                let jitterLat = Double((index % 7) - 3) * 0.0012
                let jitterLon = Double((index % 5) - 2) * 0.0011
                let live = template.preferLive && (index % 3 != 0)
                let meters = 80 + (index * 37) % 900
                let givenName = uniqueName(
                    from: template.names,
                    index: index,
                    offset: offset,
                    used: &usedNames
                )
                let progress: String? = {
                    switch template.category.defaultServiceMode {
                    case .scheduled:
                        return live ? "Currently on \(hood.landmarkKey.replacingOccurrences(of: "landmark.", with: "").replacingOccurrences(of: "_", with: " "))" : nil
                    case .mobile:
                        return live ? "\(max(1, 4 - (index % 4))) stops away" : nil
                    case .stationary:
                        return live ? "Open at usual spot" : nil
                    }
                }()

                result.append(
                    Seller(
                        id: id,
                        name: givenName,
                        businessName: "\(givenName) \(template.businessSuffix)",
                        category: template.category,
                        profileImageAssetName: nil,
                        neighborhood: hood,
                        landmarkKey: hood.landmarkKey,
                        latitude: center.latitude + jitterLat,
                        longitude: center.longitude + jitterLon,
                        isLive: live,
                        distanceMeters: meters,
                        directionKey: ["direction.north", "direction.south", "direction.east", "direction.west"][index % 4],
                        rating: 4.2 + Double(index % 7) * 0.1,
                        languages: [.tamil, .english],
                        hasAnnouncement: live && index % 2 == 0,
                        announcementDurationSeconds: live && index % 2 == 0 ? 12 + (index % 10) : 0,
                        announcementStoragePath: nil,
                        routeStops: defaultStops(for: hood, category: template.category, live: live),
                        workingHours: template.hours,
                        descriptionKey: "seller.about.generic",
                        phone: String(format: "+91 98%03d %05d", 400 + (index % 90), 10000 + index),
                        photoURL: nil,
                        serviceMode: template.category.defaultServiceMode,
                        progressLabel: progress,
                        apartmentComplex: template.category == .laundry || template.category == .cableBill
                            ? "Kurinji Apartment" : nil,
                        streetName: nil,
                        todaysMessagePreview: live && index % 2 == 0 ? template.message : nil,
                        etaLabel: live ? (meters < 200 ? "Around the corner" : "About \(max(5, meters / 40)) min") : "See My Day"
                    )
                )
            }
        }

        return result
    }

    private static func uniqueName(
        from pool: [String],
        index: Int,
        offset: Int,
        used: inout Set<String>
    ) -> String {
        let start = (index * 3 + offset * 5) % max(pool.count, 1)
        for step in 0..<pool.count {
            let candidate = pool[(start + step) % pool.count]
            if !used.contains(candidate) {
                used.insert(candidate)
                return candidate
            }
        }
        let fallback = "\(pool[index % pool.count]) \(offset + 1)"
        used.insert(fallback)
        return fallback
    }

    private struct Template {
        let idPrefix: String
        let category: SellerCategory
        let names: [String]
        let businessSuffix: String
        let hours: String
        let message: String
        let preferLive: Bool
        let neighborhoods: [PilotNeighborhood]
    }

    private static let coreHoods: [PilotNeighborhood] = [
        .tNagar, .westMambalam, .kodambakkam, .adyar, .besantNagar, .velachery, .annaNagar, .mylapore
    ]

    /// Diverse given names common across Tamil Nadu — mixed communities, no single surname pattern.
    private static let templates: [Template] = [
        Template(
            idPrefix: "veg",
            category: .vegetables,
            names: ["Murugan", "Selvam", "Karthik", "Pandian", "Elango", "Boominathan", "Thangavel", "Nataraj"],
            businessSuffix: "Vegetables",
            hours: "6:00 AM – 8:00 PM",
            message: "Fresh greens and tomatoes today",
            preferLive: true,
            neighborhoods: coreHoods
        ),
        Template(
            idPrefix: "fruit",
            category: .fruits,
            names: ["Raja", "Saravanan", "Vimal", "Inban", "Chezhiyan"],
            businessSuffix: "Fruits",
            hours: "6:30 AM – 8:30 PM",
            message: "Ripe bananas and mangoes",
            preferLive: true,
            neighborhoods: [.tNagar, .adyar, .velachery, .annaNagar, .ecr]
        ),
        Template(
            idPrefix: "flower",
            category: .flowers,
            names: ["Lakshmi", "Kalaivani", "Meena", "Thenmozhi"],
            businessSuffix: "Flowers",
            hours: "5:00 AM – 7:00 PM",
            message: "Temple flowers ready",
            preferLive: true,
            neighborhoods: [.tNagar, .mylapore, .triplicane, .besantNagar]
        ),
        Template(
            idPrefix: "fish",
            category: .fish,
            names: ["Rahim", "Anbu", "Suresh", "Jamal"],
            businessSuffix: "Fresh Fish",
            hours: "6:00 AM – 11:00 AM",
            message: "Morning catch available",
            preferLive: true,
            neighborhoods: [.thiruvanmiyur, .besantNagar, .ecr, .saidapet]
        ),
        Template(
            idPrefix: "milk",
            category: .milk,
            names: ["Revathi", "Kamala", "Geetha", "Banu"],
            businessSuffix: "Milk",
            hours: "5:00 AM – 9:00 AM",
            message: "Fresh milk rounds",
            preferLive: false,
            neighborhoods: [.westMambalam, .ashokNagar, .annaNagar, .kodambakkam]
        ),
        Template(
            idPrefix: "knife",
            category: .knifeSharpening,
            names: ["Siva", "Kannan", "Muthu", "Velu"],
            businessSuffix: "Knife Service",
            hours: "8:00 AM – 6:00 PM",
            message: "Sharpening near your street",
            preferLive: true,
            neighborhoods: [.tNagar, .westMambalam, .adyar, .velachery]
        ),
        Template(
            idPrefix: "cobbler",
            category: .cobbler,
            names: ["Ravi", "Mani", "David"],
            businessSuffix: "Cobbler",
            hours: "9:00 AM – 7:00 PM",
            message: "Shoe repair today",
            preferLive: false,
            neighborhoods: [.tNagar, .saidapet, .mylapore]
        ),
        Template(
            idPrefix: "laundry",
            category: .laundry,
            names: ["Priya", "Nisha", "Fathima", "Anitha"],
            businessSuffix: "Laundry Pickup",
            hours: "8:00 AM – 6:00 PM",
            message: "Collecting Block-wise today",
            preferLive: true,
            neighborhoods: [.adyar, .velachery, .annaNagar, .omr]
        ),
        Template(
            idPrefix: "iron",
            category: .ironing,
            names: ["Babu", "Dinesh", "Sekar"],
            businessSuffix: "Ironing",
            hours: "9:00 AM – 7:00 PM",
            message: "Doorstep ironing",
            preferLive: false,
            neighborhoods: [.westMambalam, .kodambakkam, .ashokNagar]
        ),
        Template(
            idPrefix: "cable",
            category: .cableBill,
            names: ["Arun", "Vijay", "Sathya", "Naveen"],
            businessSuffix: "Cable Collection",
            hours: "9:00 AM – 5:00 PM",
            message: "Collecting dues on South Avenue",
            preferLive: true,
            neighborhoods: [.tNagar, .annaNagar, .velachery, .adyar]
        ),
        Template(
            idPrefix: "water",
            category: .waterCan,
            names: ["Kumar", "Prakash", "Ibrahim", "Giri"],
            businessSuffix: "Water Can",
            hours: "7:00 AM – 7:00 PM",
            message: "20L cans available",
            preferLive: true,
            neighborhoods: [.omr, .velachery, .adyar, .ecr]
        ),
        Template(
            idPrefix: "gas",
            category: .gasCylinder,
            names: ["Shankar", "Mohan", "Yusuf"],
            businessSuffix: "Gas Booking",
            hours: "8:00 AM – 6:00 PM",
            message: "Cylinder delivery slots open",
            preferLive: false,
            neighborhoods: [.kodambakkam, .saidapet, .ashokNagar]
        ),
        Template(
            idPrefix: "paper",
            category: .oldNewspapers,
            names: ["Gopal", "Hussain", "Thomas", "Varadarajan"],
            businessSuffix: "Paper Buyers",
            hours: "9:00 AM – 5:00 PM",
            message: "Buying old newspapers",
            preferLive: true,
            neighborhoods: [.tNagar, .westMambalam, .mylapore, .triplicane]
        ),
        Template(
            idPrefix: "plastic",
            category: .plastic,
            names: ["Faisal", "Imran", "Noor"],
            businessSuffix: "Plastic Recycling",
            hours: "9:00 AM – 5:00 PM",
            message: "Plastic pickup today",
            preferLive: false,
            neighborhoods: [.velachery, .omr, .annaNagar]
        ),
        Template(
            idPrefix: "kulfi",
            category: .kulfi,
            names: ["Meenakshi", "Ayesha", "Rosy", "Kavitha"],
            businessSuffix: "Kulfi Cart",
            hours: "4:00 PM – 10:00 PM",
            message: "Evening kulfi at the corner",
            preferLive: true,
            neighborhoods: [.besantNagar, .ecr, .tNagar, .adyar]
        ),
        Template(
            idPrefix: "truck",
            category: .foodTruck,
            names: ["Aravind", "Sangeetha", "Farooq"],
            businessSuffix: "Food Truck",
            hours: "12:00 PM – 10:00 PM",
            message: "Parked near the park",
            preferLive: true,
            neighborhoods: [.annaNagar, .omr, .velachery]
        ),
        Template(
            idPrefix: "coconut",
            category: .tenderCoconut,
            names: ["Palani", "Senthil", "Azhar", "Jegan"],
            businessSuffix: "Tender Coconut",
            hours: "7:00 AM – 7:00 PM",
            message: "Cold tender coconuts",
            preferLive: true,
            neighborhoods: [.ecr, .besantNagar, .thiruvanmiyur, .mylapore]
        ),
        Template(
            idPrefix: "repair",
            category: .householdRepair,
            names: ["Ganesh", "Sathish", "Peter"],
            businessSuffix: "Home Repairs",
            hours: "9:00 AM – 7:00 PM",
            message: "Minor household repairs",
            preferLive: false,
            neighborhoods: [.kodambakkam, .ashokNagar, .saidapet]
        ),
        Template(
            idPrefix: "elec",
            category: .electricalRepair,
            names: ["Natarajan", "Balu", "Clement"],
            businessSuffix: "Electrical",
            hours: "9:00 AM – 6:00 PM",
            message: "Fan and switch repairs",
            preferLive: false,
            neighborhoods: [.tNagar, .adyar, .annaNagar]
        ),
        Template(
            idPrefix: "mechanic",
            category: .mobileMechanic,
            names: ["Joseph", "Hari", "Abdul"],
            businessSuffix: "Bike Mechanic",
            hours: "8:00 AM – 8:00 PM",
            message: "Roadside bike service",
            preferLive: true,
            neighborhoods: [.omr, .ecr, .velachery]
        ),
        Template(
            idPrefix: "tea",
            category: .bakery,
            names: ["Kannagi", "Sundari", "Fatima", "Jayanthi"],
            businessSuffix: "Tea Cart",
            hours: "6:00 AM – 11:00 AM",
            message: "Hot tea and breakfast snacks",
            preferLive: true,
            neighborhoods: [.tNagar, .saidapet, .westMambalam, .triplicane]
        ),
        Template(
            idPrefix: "icecream",
            category: .iceCream,
            names: ["Ashwin", "Deepa", "Rehman"],
            businessSuffix: "Ice Cream",
            hours: "4:00 PM – 10:00 PM",
            message: "Evening ice cream cart",
            preferLive: true,
            neighborhoods: [.besantNagar, .adyar, .annaNagar]
        ),
        Template(
            idPrefix: "juice",
            category: .juices,
            names: ["Nalam", "Praveen", "Sharmila"],
            businessSuffix: "Juices",
            hours: "8:00 AM – 8:00 PM",
            message: "Fresh juices and sugarcane",
            preferLive: false,
            neighborhoods: [.mylapore, .tNagar, .ecr]
        ),
        Template(
            idPrefix: "medical",
            category: .medicalDelivery,
            names: ["Karthika", "Samuel", "Nazreen"],
            businessSuffix: "Medical Delivery",
            hours: "8:00 AM – 10:00 PM",
            message: "Prescription delivery nearby",
            preferLive: false,
            neighborhoods: [.adyar, .velachery, .annaNagar]
        ),
        Template(
            idPrefix: "sofa",
            category: .sofaRepair,
            names: ["Uday", "Ramesh", "Issac"],
            businessSuffix: "Sofa Repair",
            hours: "9:00 AM – 6:00 PM",
            message: "Sofa and cushion repairs",
            preferLive: false,
            neighborhoods: [.kodambakkam, .ashokNagar, .westMambalam]
        ),
        Template(
            idPrefix: "tailor",
            category: .tailor,
            names: ["Vasanthi", "Jaya", "Zulekha", "Mallika"],
            businessSuffix: "Tailor",
            hours: "9:00 AM – 8:00 PM",
            message: "Alterations and stitching",
            preferLive: false,
            neighborhoods: [.tNagar, .mylapore, .triplicane, .saidapet]
        )
    ]

    private static func defaultStops(
        for hood: PilotNeighborhood,
        category: SellerCategory,
        live: Bool
    ) -> [RouteStop] {
        let c = hood.coordinate
        let mode = category.defaultServiceMode

        func stop(
            _ index: Int,
            timeLabel: String,
            status: RouteStopStatus,
            latDelta: Double,
            lonDelta: Double
        ) -> RouteStop {
            RouteStop(
                id: "\(hood.rawValue)_s\(index)",
                timeLabel: timeLabel,
                titleKey: hood.nameKey,
                neighborhood: hood,
                landmarkKey: hood.landmarkKey,
                latitude: c.latitude + latDelta,
                longitude: c.longitude + lonDelta,
                status: status
            )
        }

        switch mode {
        case .stationary:
            return [
                stop(1, timeLabel: live ? "Now" : "Opens soon", status: live ? .current : .upcoming, latDelta: 0.0, lonDelta: 0.0)
            ]
        case .scheduled:
            let times = ["8:30 AM", "10:30 AM", "1:00 PM", "4:00 PM"]
            return (0..<times.count).map { i in
                let status: RouteStopStatus = (live && i == 0) ? .current : .upcoming
                return stop(i + 1, timeLabel: times[i], status: status, latDelta: Double(i) * 0.0013, lonDelta: -Double(i) * 0.0009)
            }
        case .mobile:
            return [
                stop(1, timeLabel: live ? "Arriving" : "Later today", status: live ? .current : .upcoming, latDelta: 0.0, lonDelta: 0.0),
                stop(2, timeLabel: "Next stop", status: .upcoming, latDelta: 0.002, lonDelta: -0.001)
            ]
        }
    }
}
