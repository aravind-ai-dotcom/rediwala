import Foundation

/// Local synthetic Chennai pilot sellers for discovery UI.
enum SyntheticChennaiData {
    static let sellers: [Seller] = [
        // Fresh & Daily
        make(
            id: "murugan",
            name: "Murugan",
            businessName: "Murugan Fresh Cart",
            category: .vegetables,
            neighborhood: .westMambalam,
            landmarkKey: "landmark.mambalam_railway",
            lat: 13.0391, lon: 80.2238,
            isLive: true,
            meters: 140,
            direction: "direction.north",
            rating: 4.7,
            announcement: true,
            duration: 18,
            hours: "6:00 AM – 8:00 PM",
            descriptionKey: "seller.about.murugan",
            phone: "+91 98401 23456",
            stops: [
                stop("m1", "8:00 AM", "stop.mambalam_railway", .westMambalam, "landmark.mambalam_railway", 13.0385, 80.2225, .completed),
                stop("m2", "10:30 AM", "stop.postal_colony", .westMambalam, "landmark.postal_colony", 13.0402, 80.2208, .current),
                stop("m3", "1:00 PM", "stop.ashok_nagar", .westMambalam, "landmark.ashok_nagar", 13.0355, 80.2120, .upcoming)
            ]
        ),
        make(
            id: "lakshmi",
            name: "Lakshmi",
            businessName: "Lakshmi Flowers",
            category: .flowers,
            neighborhood: .tNagar,
            landmarkKey: "landmark.pondy_bazaar",
            lat: 13.0426, lon: 80.2335,
            isLive: true,
            meters: 95,
            direction: "direction.east",
            rating: 4.8,
            announcement: true,
            duration: 12,
            hours: "5:30 AM – 7:00 PM",
            descriptionKey: "seller.about.lakshmi",
            phone: "+91 98402 34567",
            stops: [
                stop("l1", "6:00 AM", "stop.pondy_bazaar", .tNagar, "landmark.pondy_bazaar", 13.0419, 80.2338, .completed),
                stop("l2", "9:30 AM", "stop.panagal_park", .tNagar, "landmark.panagal_park", 13.0435, 80.2320, .current),
                stop("l3", "12:15 PM", "stop.kapaleeshwarar", .tNagar, "landmark.kapaleeshwarar_temple", 13.0338, 80.2702, .upcoming)
            ]
        ),
        make(
            id: "saravanan",
            name: "Saravanan",
            businessName: nil,
            category: .fruits,
            neighborhood: .thiruvanmiyur,
            landmarkKey: "landmark.thiruvanmiyur_mrts",
            lat: 12.9862, lon: 80.2598,
            isLive: true,
            meters: 220,
            direction: "direction.south",
            rating: 4.5,
            announcement: false,
            duration: 0,
            hours: "6:30 AM – 8:30 PM",
            descriptionKey: "seller.about.saravanan",
            phone: "+91 98407 89012",
            stops: [
                stop("s1", "7:00 AM", "stop.thiruvanmiyur_mrts", .thiruvanmiyur, "landmark.thiruvanmiyur_mrts", 12.9855, 80.2594, .current),
                stop("s2", "11:00 AM", "stop.besant_nagar", .thiruvanmiyur, "landmark.besant_nagar_beach", 12.9988, 80.2710, .upcoming),
                stop("s3", "3:30 PM", "stop.lattice_bridge", .thiruvanmiyur, "landmark.lattice_bridge", 12.9910, 80.2550, .upcoming)
            ]
        ),
        make(
            id: "revathi",
            name: "Revathi",
            businessName: "Revathi Fresh Milk",
            category: .milk,
            neighborhood: .westMambalam,
            landmarkKey: "landmark.mambalam_railway",
            lat: 13.0370, lon: 80.2250,
            isLive: false,
            meters: 310,
            direction: "direction.west",
            rating: 4.9,
            announcement: false,
            duration: 0,
            hours: "5:00 AM – 9:00 AM",
            descriptionKey: "seller.about.revathi",
            phone: "+91 98404 56789",
            stops: [
                stop("r1", "5:15 AM", "stop.postal_colony", .westMambalam, "landmark.postal_colony", 13.0402, 80.2208, .completed),
                stop("r2", "6:45 AM", "stop.mambalam_railway", .westMambalam, "landmark.mambalam_railway", 13.0385, 80.2225, .completed),
                stop("r3", "8:00 AM", "stop.t_nagar_bus", .tNagar, "landmark.t_nagar_bus", 13.0405, 80.2370, .upcoming)
            ]
        ),
        make(
            id: "anbu",
            name: "Anbu",
            businessName: "Anbu Fish Mart",
            category: .fish,
            neighborhood: .thiruvanmiyur,
            landmarkKey: "landmark.besant_nagar_beach",
            lat: 12.9975, lon: 80.2685,
            isLive: true,
            meters: 480,
            direction: "direction.southeast",
            rating: 4.2,
            announcement: true,
            duration: 15,
            hours: "5:30 AM – 11:00 AM",
            descriptionKey: "seller.about.anbu",
            phone: "+91 98408 11223",
            stops: [
                stop("a1", "5:45 AM", "stop.besant_nagar", .thiruvanmiyur, "landmark.besant_nagar_beach", 12.9988, 80.2710, .current),
                stop("a2", "8:30 AM", "stop.thiruvanmiyur_mrts", .thiruvanmiyur, "landmark.thiruvanmiyur_mrts", 12.9855, 80.2594, .upcoming)
            ]
        ),
        make(
            id: "kalaivani",
            name: "Kalaivani",
            businessName: "Kalaivani Bakery Cart",
            category: .bakery,
            neighborhood: .tNagar,
            landmarkKey: "landmark.panagal_park",
            lat: 13.0440, lon: 80.2315,
            isLive: false,
            meters: 360,
            direction: "direction.northeast",
            rating: 4.4,
            announcement: false,
            duration: 0,
            hours: "7:00 AM – 9:00 PM",
            descriptionKey: "seller.about.kalaivani",
            phone: "+91 98409 22334",
            stops: [
                stop("k1", "7:30 AM", "stop.panagal_park", .tNagar, "landmark.panagal_park", 13.0435, 80.2320, .upcoming),
                stop("k2", "12:00 PM", "stop.pondy_bazaar", .tNagar, "landmark.pondy_bazaar", 13.0419, 80.2338, .upcoming),
                stop("k3", "5:00 PM", "stop.t_nagar_bus", .tNagar, "landmark.t_nagar_bus", 13.0405, 80.2370, .upcoming)
            ]
        ),
        // Neighborhood Services
        make(
            id: "selvam",
            name: "Selvam",
            businessName: "Selvam Knife Works",
            category: .knifeSharpening,
            neighborhood: .westMambalam,
            landmarkKey: "landmark.postal_colony",
            lat: 13.0410, lon: 80.2195,
            isLive: true,
            meters: 190,
            direction: "direction.northwest",
            rating: 4.6,
            announcement: true,
            duration: 10,
            hours: "8:00 AM – 6:00 PM",
            descriptionKey: "seller.about.selvam",
            phone: "+91 98403 45678",
            stops: [
                stop("sv1", "8:30 AM", "stop.postal_colony", .westMambalam, "landmark.postal_colony", 13.0402, 80.2208, .current),
                stop("sv2", "11:30 AM", "stop.mambalam_railway", .westMambalam, "landmark.mambalam_railway", 13.0385, 80.2225, .upcoming),
                stop("sv3", "3:00 PM", "stop.pondy_bazaar", .tNagar, "landmark.pondy_bazaar", 13.0419, 80.2338, .upcoming)
            ]
        ),
        make(
            id: "kannan",
            name: "Kannan",
            businessName: "Kannan Cobbler",
            category: .cobbler,
            neighborhood: .thiruvanmiyur,
            landmarkKey: "landmark.thiruvanmiyur_mrts",
            lat: 12.9840, lon: 80.2575,
            isLive: true,
            meters: 260,
            direction: "direction.southwest",
            rating: 4.3,
            announcement: false,
            duration: 0,
            hours: "9:00 AM – 7:00 PM",
            descriptionKey: "seller.about.kannan",
            phone: "+91 98405 67890",
            stops: [
                stop("kn1", "9:15 AM", "stop.thiruvanmiyur_mrts", .thiruvanmiyur, "landmark.thiruvanmiyur_mrts", 12.9855, 80.2594, .current),
                stop("kn2", "1:00 PM", "stop.lattice_bridge", .thiruvanmiyur, "landmark.lattice_bridge", 12.9910, 80.2550, .upcoming),
                stop("kn3", "4:30 PM", "stop.besant_nagar", .thiruvanmiyur, "landmark.besant_nagar_beach", 12.9988, 80.2710, .upcoming)
            ]
        ),
        make(
            id: "meena_service",
            name: "Meenakshi",
            businessName: nil,
            category: .knifeSharpening,
            neighborhood: .tNagar,
            landmarkKey: "landmark.pondy_bazaar",
            lat: 13.0408, lon: 80.2355,
            isLive: false,
            meters: 410,
            direction: "direction.east",
            rating: 4.1,
            announcement: false,
            duration: 0,
            hours: "9:00 AM – 5:00 PM",
            descriptionKey: "seller.about.meenakshi_service",
            phone: "+91 98410 33445",
            stops: [
                stop("ms1", "9:00 AM", "stop.pondy_bazaar", .tNagar, "landmark.pondy_bazaar", 13.0419, 80.2338, .upcoming),
                stop("ms2", "1:30 PM", "stop.panagal_park", .tNagar, "landmark.panagal_park", 13.0435, 80.2320, .upcoming)
            ]
        ),
        // Recycling
        make(
            id: "ramesh",
            name: "Ramesh",
            businessName: "Ramesh Recyclers",
            category: .oldNewspapers,
            neighborhood: .tNagar,
            landmarkKey: "landmark.t_nagar_bus",
            lat: 13.0398, lon: 80.2365,
            isLive: true,
            meters: 175,
            direction: "direction.south",
            rating: 4.5,
            announcement: true,
            duration: 20,
            hours: "8:00 AM – 6:00 PM",
            descriptionKey: "seller.about.ramesh",
            phone: "+91 98411 44556",
            stops: [
                stop("rm1", "8:00 AM", "stop.t_nagar_bus", .tNagar, "landmark.t_nagar_bus", 13.0405, 80.2370, .completed),
                stop("rm2", "10:45 AM", "stop.pondy_bazaar", .tNagar, "landmark.pondy_bazaar", 13.0419, 80.2338, .current),
                stop("rm3", "2:30 PM", "stop.postal_colony", .westMambalam, "landmark.postal_colony", 13.0402, 80.2208, .upcoming)
            ]
        ),
        make(
            id: "ramesh_plastic",
            name: "Ramesh",
            businessName: "Ramesh Plastic & Paper",
            category: .plastic,
            neighborhood: .tNagar,
            landmarkKey: "landmark.pondy_bazaar",
            lat: 13.0412, lon: 80.2348,
            isLive: false,
            meters: 205,
            direction: "direction.east",
            rating: 4.5,
            announcement: false,
            duration: 0,
            hours: "8:00 AM – 6:00 PM",
            descriptionKey: "seller.about.ramesh_plastic",
            phone: "+91 98411 44557",
            stops: [
                stop("rp1", "11:00 AM", "stop.pondy_bazaar", .tNagar, "landmark.pondy_bazaar", 13.0419, 80.2338, .upcoming),
                stop("rp2", "3:00 PM", "stop.panagal_park", .tNagar, "landmark.panagal_park", 13.0435, 80.2320, .upcoming)
            ]
        ),
        make(
            id: "selvam_cardboard",
            name: "Selvam",
            businessName: nil,
            category: .cardboard,
            neighborhood: .westMambalam,
            landmarkKey: "landmark.ashok_nagar",
            lat: 13.0350, lon: 80.2135,
            isLive: true,
            meters: 520,
            direction: "direction.west",
            rating: 4.0,
            announcement: false,
            duration: 0,
            hours: "9:00 AM – 5:30 PM",
            descriptionKey: "seller.about.selvam_cardboard",
            phone: "+91 98412 55667",
            stops: [
                stop("sc1", "9:30 AM", "stop.ashok_nagar", .westMambalam, "landmark.ashok_nagar", 13.0355, 80.2120, .current),
                stop("sc2", "1:00 PM", "stop.mambalam_railway", .westMambalam, "landmark.mambalam_railway", 13.0385, 80.2225, .upcoming)
            ]
        ),
        make(
            id: "anbu_metal",
            name: "Anbu",
            businessName: "Anbu Scrap Metals",
            category: .metalScrap,
            neighborhood: .thiruvanmiyur,
            landmarkKey: "landmark.lattice_bridge",
            lat: 12.9905, lon: 80.2540,
            isLive: false,
            meters: 610,
            direction: "direction.northwest",
            rating: 4.1,
            announcement: true,
            duration: 14,
            hours: "8:30 AM – 5:00 PM",
            descriptionKey: "seller.about.anbu_metal",
            phone: "+91 98413 66778",
            stops: [
                stop("am1", "9:00 AM", "stop.lattice_bridge", .thiruvanmiyur, "landmark.lattice_bridge", 12.9910, 80.2550, .upcoming),
                stop("am2", "12:30 PM", "stop.thiruvanmiyur_mrts", .thiruvanmiyur, "landmark.thiruvanmiyur_mrts", 12.9855, 80.2594, .upcoming)
            ]
        ),
        // Street Treats
        make(
            id: "meenakshi",
            name: "Meenakshi",
            businessName: "Meenakshi Kulfi",
            category: .kulfi,
            neighborhood: .tNagar,
            landmarkKey: "landmark.pondy_bazaar",
            lat: 13.0422, lon: 80.2345,
            isLive: true,
            meters: 110,
            direction: "direction.north",
            rating: 4.9,
            announcement: true,
            duration: 8,
            hours: "4:00 PM – 10:00 PM",
            descriptionKey: "seller.about.meenakshi",
            phone: "+91 98406 78901",
            stops: [
                stop("mk1", "4:15 PM", "stop.pondy_bazaar", .tNagar, "landmark.pondy_bazaar", 13.0419, 80.2338, .current),
                stop("mk2", "6:30 PM", "stop.panagal_park", .tNagar, "landmark.panagal_park", 13.0435, 80.2320, .upcoming),
                stop("mk3", "8:30 PM", "stop.t_nagar_bus", .tNagar, "landmark.t_nagar_bus", 13.0405, 80.2370, .upcoming)
            ]
        ),
        make(
            id: "kannan_corn",
            name: "Kannan",
            businessName: "Kannan Corn Stall",
            category: .roastedCorn,
            neighborhood: .thiruvanmiyur,
            landmarkKey: "landmark.besant_nagar_beach",
            lat: 12.9992, lon: 80.2705,
            isLive: true,
            meters: 540,
            direction: "direction.east",
            rating: 4.6,
            announcement: false,
            duration: 0,
            hours: "5:00 PM – 10:30 PM",
            descriptionKey: "seller.about.kannan_corn",
            phone: "+91 98414 77889",
            stops: [
                stop("kc1", "5:00 PM", "stop.besant_nagar", .thiruvanmiyur, "landmark.besant_nagar_beach", 12.9988, 80.2710, .current),
                stop("kc2", "7:30 PM", "stop.thiruvanmiyur_mrts", .thiruvanmiyur, "landmark.thiruvanmiyur_mrts", 12.9855, 80.2594, .upcoming)
            ]
        ),
        make(
            id: "lakshmi_peanuts",
            name: "Lakshmi",
            businessName: nil,
            category: .peanuts,
            neighborhood: .westMambalam,
            landmarkKey: "landmark.mambalam_railway",
            lat: 13.0388, lon: 80.2210,
            isLive: false,
            meters: 280,
            direction: "direction.south",
            rating: 4.3,
            announcement: false,
            duration: 0,
            hours: "3:00 PM – 9:00 PM",
            descriptionKey: "seller.about.lakshmi_peanuts",
            phone: "+91 98415 88990",
            stops: [
                stop("lp1", "3:30 PM", "stop.mambalam_railway", .westMambalam, "landmark.mambalam_railway", 13.0385, 80.2225, .upcoming),
                stop("lp2", "6:00 PM", "stop.postal_colony", .westMambalam, "landmark.postal_colony", 13.0402, 80.2208, .upcoming)
            ]
        ),
        make(
            id: "murugan_fruits",
            name: "Murugan",
            businessName: "Murugan Fruit Cart",
            category: .fruits,
            neighborhood: .tNagar,
            landmarkKey: "landmark.kapaleeshwarar_temple",
            lat: 13.0345, lon: 80.2695,
            isLive: false,
            meters: 720,
            direction: "direction.southeast",
            rating: 4.4,
            announcement: true,
            duration: 11,
            hours: "6:00 AM – 7:30 PM",
            descriptionKey: "seller.about.murugan_fruits",
            phone: "+91 98416 99001",
            stops: [
                stop("mf1", "6:30 AM", "stop.kapaleeshwarar", .tNagar, "landmark.kapaleeshwarar_temple", 13.0338, 80.2702, .upcoming),
                stop("mf2", "10:00 AM", "stop.pondy_bazaar", .tNagar, "landmark.pondy_bazaar", 13.0419, 80.2338, .upcoming)
            ]
        ),
        make(
            id: "kalaivani_flowers",
            name: "Kalaivani",
            businessName: "Kalaivani Malligai",
            category: .flowers,
            neighborhood: .thiruvanmiyur,
            landmarkKey: "landmark.thiruvanmiyur_mrts",
            lat: 12.9868, lon: 80.2610,
            isLive: true,
            meters: 330,
            direction: "direction.northeast",
            rating: 4.7,
            announcement: false,
            duration: 0,
            hours: "5:00 AM – 6:00 PM",
            descriptionKey: "seller.about.kalaivani_flowers",
            phone: "+91 98417 00112",
            stops: [
                stop("kf1", "5:30 AM", "stop.thiruvanmiyur_mrts", .thiruvanmiyur, "landmark.thiruvanmiyur_mrts", 12.9855, 80.2594, .completed),
                stop("kf2", "8:00 AM", "stop.besant_nagar", .thiruvanmiyur, "landmark.besant_nagar_beach", 12.9988, 80.2710, .current),
                stop("kf3", "11:30 AM", "stop.lattice_bridge", .thiruvanmiyur, "landmark.lattice_bridge", 12.9910, 80.2550, .upcoming)
            ]
        )
    ]

    // MARK: - Helpers

    private static func make(
        id: String,
        name: String,
        businessName: String?,
        category: SellerCategory,
        neighborhood: PilotNeighborhood,
        landmarkKey: String,
        lat: Double,
        lon: Double,
        isLive: Bool,
        meters: Int,
        direction: String,
        rating: Double,
        announcement: Bool,
        duration: Int,
        hours: String,
        descriptionKey: String,
        phone: String,
        stops: [RouteStop]
    ) -> Seller {
        Seller(
            id: id,
            name: name,
            businessName: businessName,
            category: category,
            profileImageAssetName: nil,
            neighborhood: neighborhood,
            landmarkKey: landmarkKey,
            latitude: lat,
            longitude: lon,
            isLive: isLive,
            distanceMeters: meters,
            directionKey: direction,
            rating: rating,
            languages: [.tamil, .english],
            hasAnnouncement: announcement,
            announcementDurationSeconds: duration,
            routeStops: stops,
            workingHours: hours,
            descriptionKey: descriptionKey,
            phone: phone,
            photoURL: nil
        )
    }

    private static func stop(
        _ id: String,
        _ time: String,
        _ titleKey: String,
        _ neighborhood: PilotNeighborhood,
        _ landmarkKey: String,
        _ lat: Double,
        _ lon: Double,
        _ status: RouteStopStatus
    ) -> RouteStop {
        RouteStop(
            id: id,
            timeLabel: time,
            titleKey: titleKey,
            neighborhood: neighborhood,
            landmarkKey: landmarkKey,
            latitude: lat,
            longitude: lon,
            status: status
        )
    }
}
