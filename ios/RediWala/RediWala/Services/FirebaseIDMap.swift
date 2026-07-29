import Foundation

/// Maps Firebase snake_case IDs ↔ iOS camelCase enums.
enum FirebaseIDMap {
    static func neighborhood(fromFirebase id: String?) -> PilotNeighborhood {
        switch id {
        case "t_nagar": return .tNagar
        case "west_mambalam": return .westMambalam
        case "thiruvanmiyur": return .thiruvanmiyur
        case "adyar": return .adyar
        case "velachery": return .velachery
        case "besant_nagar": return .besantNagar
        case "anna_nagar": return .annaNagar
        case "kodambakkam": return .kodambakkam
        case "ashok_nagar": return .ashokNagar
        case "mylapore": return .mylapore
        case "triplicane": return .triplicane
        case "saidapet": return .saidapet
        case "ecr": return .ecr
        case "omr": return .omr
        default: return .tNagar
        }
    }

    static func firebaseID(for neighborhood: PilotNeighborhood) -> String {
        switch neighborhood {
        case .tNagar: return "t_nagar"
        case .westMambalam: return "west_mambalam"
        case .thiruvanmiyur: return "thiruvanmiyur"
        case .adyar: return "adyar"
        case .velachery: return "velachery"
        case .besantNagar: return "besant_nagar"
        case .annaNagar: return "anna_nagar"
        case .kodambakkam: return "kodambakkam"
        case .ashokNagar: return "ashok_nagar"
        case .mylapore: return "mylapore"
        case .triplicane: return "triplicane"
        case .saidapet: return "saidapet"
        case .ecr: return "ecr"
        case .omr: return "omr"
        }
    }

    static func categoryGroup(fromFirebase id: String?) -> CategoryGroup? {
        switch id {
        case "fresh_daily": return .freshDaily
        case "neighborhood_services": return .neighborhoodServices
        case "home_delivery": return .homeDelivery
        case "recycling": return .recyclingBuyers
        case "street_treats": return .streetTreats
        default: return nil
        }
    }

    static func firebaseID(for group: CategoryGroup) -> String {
        switch group {
        case .freshDaily: return "fresh_daily"
        case .neighborhoodServices: return "neighborhood_services"
        case .homeDelivery: return "home_delivery"
        case .recyclingBuyers: return "recycling"
        case .streetTreats: return "street_treats"
        }
    }

    static func sellerCategory(fromFirebase id: String?) -> SellerCategory? {
        switch id {
        case "vegetables": return .vegetables
        case "fruits": return .fruits
        case "flowers": return .flowers
        case "milk": return .milk
        case "fish": return .fish
        case "bakery": return .bakery
        case "knife_sharpening": return .knifeSharpening
        case "cobbler": return .cobbler
        case "tailor": return .tailor
        case "sofa_repair": return .sofaRepair
        case "ironing": return .ironing
        case "laundry": return .laundry
        case "cable_bill": return .cableBill
        case "household_repair": return .householdRepair
        case "electrical_repair": return .electricalRepair
        case "mobile_mechanic": return .mobileMechanic
        case "water_can": return .waterCan
        case "gas_cylinder": return .gasCylinder
        case "medical_delivery": return .medicalDelivery
        case "old_newspapers": return .oldNewspapers
        case "plastic": return .plastic
        case "cardboard": return .cardboard
        case "metal_scrap": return .metalScrap
        case "kulfi": return .kulfi
        case "roasted_corn": return .roastedCorn
        case "peanuts": return .peanuts
        case "food_truck": return .foodTruck
        case "ice_cream": return .iceCream
        case "juices": return .juices
        case "tender_coconut": return .tenderCoconut
        default: return nil
        }
    }

    static func firebaseID(for category: SellerCategory) -> String {
        switch category {
        case .vegetables: return "vegetables"
        case .fruits: return "fruits"
        case .flowers: return "flowers"
        case .milk: return "milk"
        case .fish: return "fish"
        case .bakery: return "bakery"
        case .knifeSharpening: return "knife_sharpening"
        case .cobbler: return "cobbler"
        case .tailor: return "tailor"
        case .sofaRepair: return "sofa_repair"
        case .ironing: return "ironing"
        case .laundry: return "laundry"
        case .cableBill: return "cable_bill"
        case .householdRepair: return "household_repair"
        case .electricalRepair: return "electrical_repair"
        case .mobileMechanic: return "mobile_mechanic"
        case .waterCan: return "water_can"
        case .gasCylinder: return "gas_cylinder"
        case .medicalDelivery: return "medical_delivery"
        case .oldNewspapers: return "old_newspapers"
        case .plastic: return "plastic"
        case .cardboard: return "cardboard"
        case .metalScrap: return "metal_scrap"
        case .kulfi: return "kulfi"
        case .roastedCorn: return "roasted_corn"
        case .peanuts: return "peanuts"
        case .foodTruck: return "food_truck"
        case .iceCream: return "ice_cream"
        case .juices: return "juices"
        case .tenderCoconut: return "tender_coconut"
        }
    }

    static func language(fromFirebase code: String) -> AppLanguage? {
        AppLanguage(rawValue: code)
    }
}
