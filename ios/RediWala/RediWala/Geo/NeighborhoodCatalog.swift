import Foundation

/// Configuration-driven neighborhood catalog. Neighborhoods are data, not feature code.
enum NeighborhoodCatalog {
    static let chennai = GeoCity(
        id: "chennai",
        displayName: "Chennai",
        countryCode: "IN",
        countryName: "India",
        defaultTimezoneIdentifier: "Asia/Kolkata"
    )

    static let raleigh = GeoCity(
        id: "raleigh",
        displayName: "Raleigh",
        countryCode: "US",
        countryName: "United States",
        defaultTimezoneIdentifier: "America/New_York"
    )

    static let cities: [GeoCity] = [chennai, raleigh]

    static let all: [NeighborhoodDefinition] = chennaiNeighborhoods + raleighPlaceholders

    static func neighborhood(id: String) -> NeighborhoodDefinition? {
        cacheByID[id]
    }

    static func neighborhoods(inCity cityId: String) -> [NeighborhoodDefinition] {
        all.filter { $0.cityId == cityId }
    }

    /// Demo onboarding short list — Chennai pilot set.
    static var demoOnboarding: [NeighborhoodDefinition] {
        let ids = [
            "west_mambalam",
            "thiruvanmiyur",
            "adyar",
            "velachery",
            "t_nagar",
            "besant_nagar",
            "anna_nagar",
            "ashok_nagar"
        ]
        // Avoid `compactMap(neighborhood(id:))` method reference — it trips MainActor isolation.
        return ids.compactMap { neighborhood(id: $0) }
    }

    static var defaultDemoNeighborhood: NeighborhoodDefinition {
        neighborhood(id: "west_mambalam") ?? chennaiNeighborhoods[0]
    }

    private static let cacheByID: [String: NeighborhoodDefinition] = {
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
    }()

    // MARK: - Chennai

    static let chennaiNeighborhoods: [NeighborhoodDefinition] = [
        make(
            id: "west_mambalam",
            name: "West Mambalam",
            key: "neighborhood.westMambalam",
            lat: 13.0382, lon: 80.2219,
            streets: ["Postal Colony", "Arya Gowda Road", "Lake View Road", "Station Road"],
            landmarks: ["Mambalam Railway", "Postal Colony", "Arya Gowda Road"],
            categories: ["vegetables", "flowers", "ironing", "cable_bill", "tailor", "milk"],
            population: 42_000,
            capacity: 28
        ),
        make(
            id: "t_nagar",
            name: "T. Nagar",
            key: "neighborhood.tNagar",
            lat: 13.0418, lon: 80.2341,
            streets: ["Pondy Bazaar", "Usman Road", "South Usman Road", "Thyagaraya Road"],
            landmarks: ["Pondy Bazaar", "Panagal Park", "T Nagar Bus Stand"],
            categories: ["vegetables", "flowers", "bakery", "kulfi", "old_newspapers", "plastic"],
            population: 68_000,
            capacity: 40
        ),
        make(
            id: "thiruvanmiyur",
            name: "Thiruvanmiyur",
            key: "neighborhood.thiruvanmiyur",
            lat: 12.9850, lon: 80.2590,
            streets: ["Kannappa Nagar", "Kurinji Nagar", "Lattice Bridge Road", "ECR Junction"],
            landmarks: ["Thiruvanmiyur MRTS", "Kannappa Nagar", "Kurinji Nagar"],
            categories: ["vegetables", "fish", "flowers", "laundry", "bakery", "milk", "water_can"],
            population: 55_000,
            capacity: 34
        ),
        make(
            id: "besant_nagar",
            name: "Besant Nagar",
            key: "neighborhood.besantNagar",
            lat: 13.0001, lon: 80.2668,
            streets: ["Elliot's Beach Road", "4th Avenue", "6th Avenue"],
            landmarks: ["Elliot's Beach", "Kalakshetra"],
            categories: ["fish", "roasted_corn", "juices", "tender_coconut", "flowers"],
            population: 28_000,
            capacity: 18
        ),
        make(
            id: "adyar",
            name: "Adyar",
            key: "neighborhood.adyar",
            lat: 13.0067, lon: 80.2576,
            streets: ["LB Road", "Indira Nagar", "Gandhi Nagar"],
            landmarks: ["Adyar Bridge", "Theosophical Society"],
            categories: ["vegetables", "milk", "laundry", "water_can", "bakery"],
            population: 48_000,
            capacity: 30
        ),
        make(
            id: "velachery",
            name: "Velachery",
            key: "neighborhood.velachery",
            lat: 12.9750, lon: 80.2207,
            streets: ["Velachery Main Road", "100 Feet Road", "Taramani Link Road"],
            landmarks: ["Velachery Metro", "Vijayanagar"],
            categories: ["vegetables", "food_truck", "laundry", "cable_bill", "plastic"],
            population: 72_000,
            capacity: 36
        ),
        make(
            id: "anna_nagar",
            name: "Anna Nagar",
            key: "neighborhood.annaNagar",
            lat: 13.0850, lon: 80.2101,
            streets: ["2nd Avenue", "3rd Avenue", "Shanthi Colony"],
            landmarks: ["Anna Nagar Tower", "Tower Park"],
            categories: ["vegetables", "milk", "flowers", "ironing", "bakery"],
            population: 60_000,
            capacity: 32
        ),
        make(
            id: "ashok_nagar",
            name: "Ashok Nagar",
            key: "neighborhood.ashokNagar",
            lat: 13.0335, lon: 80.2120,
            streets: ["11th Avenue", "Ashok Pillar Road"],
            landmarks: ["Ashok Pillar", "Ashok Nagar Metro"],
            categories: ["vegetables", "cardboard", "ironing", "milk"],
            population: 35_000,
            capacity: 22
        ),
        make(
            id: "kodambakkam",
            name: "Kodambakkam",
            key: "neighborhood.kodambakkam",
            lat: 13.0519, lon: 80.2240,
            streets: ["Arcott Road", "Power House Road"],
            landmarks: ["Kodambakkam Market"],
            categories: ["vegetables", "flowers", "knife_sharpening", "cobbler"],
            population: 40_000,
            capacity: 24
        ),
        make(
            id: "mylapore",
            name: "Mylapore",
            key: "neighborhood.mylapore",
            lat: 13.0338, lon: 80.2680,
            streets: ["North Mada Street", "South Mada Street", "RK Mutt Road"],
            landmarks: ["Kapaleeshwarar Temple", "Mylapore Tank"],
            categories: ["flowers", "vegetables", "milk", "bakery"],
            population: 45_000,
            capacity: 26
        ),
        make(
            id: "triplicane",
            name: "Triplicane",
            key: "neighborhood.triplicane",
            lat: 13.0580, lon: 80.2750,
            streets: ["Big Street", "Wallajah Road"],
            landmarks: ["Parthasarathy Temple"],
            categories: ["flowers", "vegetables", "fish", "bakery"],
            population: 38_000,
            capacity: 20
        ),
        make(
            id: "saidapet",
            name: "Saidapet",
            key: "neighborhood.saidapet",
            lat: 13.0210, lon: 80.2230,
            streets: ["Anna Salai", "Jones Road"],
            landmarks: ["Saidapet Court"],
            categories: ["vegetables", "laundry", "cable_bill"],
            population: 33_000,
            capacity: 18
        ),
        make(
            id: "ecr",
            name: "ECR",
            key: "neighborhood.ecr",
            lat: 12.9141, lon: 80.2512,
            streets: ["East Coast Road"],
            landmarks: ["ECR Junction"],
            categories: ["fish", "tender_coconut", "roasted_corn", "food_truck"],
            population: 22_000,
            capacity: 14
        ),
        make(
            id: "omr",
            name: "OMR",
            key: "neighborhood.omr",
            lat: 12.9100, lon: 80.2270,
            streets: ["Rajiv Gandhi Salai"],
            landmarks: ["OMR IT Corridor"],
            categories: ["food_truck", "laundry", "water_can", "vegetables"],
            population: 50_000,
            capacity: 28
        )
    ]

    // MARK: - Future US Triangle (placeholders — ready for config expansion)

    static let raleighPlaceholders: [NeighborhoodDefinition] = [
        makeUS(id: "raleigh_downtown", name: "Downtown Raleigh", lat: 35.7796, lon: -78.6382),
        makeUS(id: "cary", name: "Cary", lat: 35.7915, lon: -78.7811),
        makeUS(id: "apex", name: "Apex", lat: 35.7327, lon: -78.8503),
        makeUS(id: "morrisville", name: "Morrisville", lat: 35.8235, lon: -78.8256),
        makeUS(id: "durham", name: "Durham", lat: 35.9940, lon: -78.8986)
    ]

    // MARK: - Helpers

    private static func make(
        id: String,
        name: String,
        key: String,
        lat: Double,
        lon: Double,
        streets: [String],
        landmarks: [String],
        categories: [String],
        population: Int,
        capacity: Int,
        zoom: Double = 0.012,
        visibleRadius: Double = 2_800,
        serviceRadius: Double = 3_200
    ) -> NeighborhoodDefinition {
        let delta = 0.012
        return NeighborhoodDefinition(
            id: id,
            displayName: name,
            displayNameLocalizedKey: key,
            cityId: chennai.id,
            countryCode: "IN",
            centerLatitude: lat,
            centerLongitude: lon,
            defaultZoomSpan: zoom,
            visibleRadiusMeters: visibleRadius,
            serviceRadiusMeters: serviceRadius,
            primaryStreets: streets,
            landmarks: landmarks,
            bounds: GeoBounds(
                southWestLatitude: lat - delta,
                southWestLongitude: lon - delta,
                northEastLatitude: lat + delta,
                northEastLongitude: lon + delta
            ),
            demoPopulation: population,
            vendorCapacity: capacity,
            suggestedCategories: categories
        )
    }

    private static func makeUS(id: String, name: String, lat: Double, lon: Double) -> NeighborhoodDefinition {
        let delta = 0.02
        return NeighborhoodDefinition(
            id: id,
            displayName: name,
            displayNameLocalizedKey: "neighborhood.\(id)",
            cityId: raleigh.id,
            countryCode: "US",
            centerLatitude: lat,
            centerLongitude: lon,
            defaultZoomSpan: 0.02,
            visibleRadiusMeters: 4_000,
            serviceRadiusMeters: 5_000,
            primaryStreets: [],
            landmarks: [name],
            bounds: GeoBounds(
                southWestLatitude: lat - delta,
                southWestLongitude: lon - delta,
                northEastLatitude: lat + delta,
                northEastLongitude: lon + delta
            ),
            demoPopulation: 25_000,
            vendorCapacity: 12,
            suggestedCategories: ["vegetables", "laundry", "food_truck"]
        )
    }
}
