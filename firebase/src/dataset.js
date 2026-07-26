import { jitter, isoHoursAgo, mulberry32, todayDateString } from "./utils.js";

const VENDOR_NAMES = [
  "Murugan", "Lakshmi", "Selvam", "Revathi", "Kannan", "Meenakshi",
  "Saravanan", "Anbu", "Kalaivani", "Ramesh", "Valli", "Sekar",
  "Rajendran", "Dhanalakshmi", "Senthil", "Kumaravel", "Malathi", "Ganesan",
  "Priya", "Arumugam", "Balamurugan", "Thenmozhi", "Karthik", "Jayanthi",
  "Muthu", "Geetha", "Pandian", "Shanthi", "Ilango", "Nirmala",
  "Venkatesh", "Chitra", "Manikandan", "Kavitha", "Suresh", "Padma",
  "Natarajan", "Bhuvana", "Elumalai", "Radha",
];

const CUSTOMER_NAMES = [
  "Aisha", "Bala", "Charan", "Deepa", "Eshwar", "Fathima",
  "Gokul", "Harini", "Imran", "Janani", "Karthika", "Lokesh",
  "Megha", "Naveen", "Oviya", "Pradeep", "Rithika", "Sanjay",
  "Tanvi", "Umesh",
];

const NEIGHBORHOOD_IDS = ["t_nagar", "west_mambalam", "thiruvanmiyur"];

/** Active categories vendors may be assigned to (excludes coming soon). */
const ASSIGNABLE_CATEGORIES = [
  "vegetables", "fruits", "flowers", "milk", "fish", "bakery",
  "knife_sharpening", "cobbler",
  "old_newspapers", "plastic", "cardboard", "metal_scrap",
  "kulfi", "roasted_corn", "peanuts",
];

function buildCities() {
  return {
    chennai: {
      id: "chennai",
      name: "Chennai",
      state: "Tamil Nadu",
      country: "IN",
      defaultLanguage: "ta",
      timezone: "Asia/Kolkata",
      enabled: true,
      pilot: true,
    },
    // Placeholder city shells for future expansion (not seeded with vendors yet).
    bangalore: {
      id: "bangalore",
      name: "Bangalore",
      state: "Karnataka",
      country: "IN",
      defaultLanguage: "en",
      timezone: "Asia/Kolkata",
      enabled: false,
      pilot: false,
    },
    hyderabad: {
      id: "hyderabad",
      name: "Hyderabad",
      state: "Telangana",
      country: "IN",
      defaultLanguage: "en",
      timezone: "Asia/Kolkata",
      enabled: false,
      pilot: false,
    },
    mumbai: {
      id: "mumbai",
      name: "Mumbai",
      state: "Maharashtra",
      country: "IN",
      defaultLanguage: "en",
      timezone: "Asia/Kolkata",
      enabled: false,
      pilot: false,
    },
  };
}

function buildCategoryGroups() {
  return {
    fresh_daily: {
      id: "fresh_daily",
      nameEn: "Fresh & Daily",
      nameTa: "தினசரி புதியவை",
      displayOrder: 0,
      enabled: true,
    },
    neighborhood_services: {
      id: "neighborhood_services",
      nameEn: "Neighborhood Services",
      nameTa: "அருகாமை சேவைகள்",
      displayOrder: 1,
      enabled: true,
    },
    recycling: {
      id: "recycling",
      nameEn: "Recycling",
      nameTa: "மறுசுழற்சி",
      displayOrder: 2,
      enabled: true,
    },
    street_treats: {
      id: "street_treats",
      nameEn: "Street Treats",
      nameTa: "தெரு சிற்றுண்டிகள்",
      displayOrder: 3,
      enabled: true,
    },
  };
}

function category(id, group, nameEn, nameTa, sfSymbol, displayOrder, comingSoon = false) {
  return {
    id,
    group,
    nameEn,
    nameTa,
    sfSymbol,
    enabled: true,
    comingSoon,
    displayOrder,
  };
}

function buildCategories() {
  const list = [
    category("vegetables", "fresh_daily", "Vegetables", "காய்கறிகள்", "leaf.fill", 0),
    category("fruits", "fresh_daily", "Fruits", "பழங்கள்", "carrot.fill", 1),
    category("flowers", "fresh_daily", "Flowers", "பூக்கள்", "camera.macro", 2),
    category("milk", "fresh_daily", "Milk", "பால்", "cup.and.saucer.fill", 3),
    category("fish", "fresh_daily", "Fish", "மீன்", "fish.fill", 4),
    category("bakery", "fresh_daily", "Bakery", "பேக்கரி", "birthday.cake.fill", 5),
    category("knife_sharpening", "neighborhood_services", "Knife Sharpening", "கத்தி கூர்மைப்படுத்தல்", "scissors", 6),
    category("cobbler", "neighborhood_services", "Cobbler", "செருப்புத் தைப்பவர்", "hammer.fill", 7),
    category("tailor", "neighborhood_services", "Tailor", "தையல்காரர்", "scissors", 8, true),
    category("sofa_repair", "neighborhood_services", "Sofa and Couch Repair", "சோபா பழுதுபார்ப்பு", "sofa.fill", 9, true),
    category("old_newspapers", "recycling", "Old Newspapers", "பழைய செய்தித்தாள்கள்", "newspaper.fill", 10),
    category("plastic", "recycling", "Plastic", "பிளாஸ்டிக்", "arrow.3.trianglepath", 11),
    category("cardboard", "recycling", "Cardboard", "அட்டைப்பெட்டி", "shippingbox.fill", 12),
    category("metal_scrap", "recycling", "Metal Scrap", "உலோகக் குப்பை", "wrench.and.screwdriver.fill", 13),
    category("kulfi", "street_treats", "Kulfi", "குல்ஃபி", "snowflake", 14),
    category("roasted_corn", "street_treats", "Roasted Corn", "சுட்ட சோளம்", "flame.fill", 15),
    category("peanuts", "street_treats", "Peanuts", "நிலக்கடலை", "circle.grid.3x3.fill", 16),
  ];
  return Object.fromEntries(list.map((c) => [c.id, c]));
}

function landmark(id, nameEn, nameTa, latitude, longitude) {
  return { id, nameEn, nameTa, latitude, longitude };
}

function buildNeighborhoods() {
  return {
    t_nagar: {
      id: "t_nagar",
      cityId: "chennai",
      nameEn: "T. Nagar",
      nameTa: "தி. நகர்",
      mapCenter: { latitude: 13.0418, longitude: 80.2341 },
      defaultZoom: 0.018,
      landmarks: [
        landmark("pondy_bazaar", "Pondy Bazaar", "பாண்டி பஜார்", 13.0419, 80.2338),
        landmark("panagal_park", "Panagal Park", "பனகல் பூங்கா", 13.0435, 80.2320),
        landmark("t_nagar_bus", "T. Nagar Bus Terminus", "தி. நகர் பஸ் நிலையம்", 13.0405, 80.2370),
      ],
    },
    west_mambalam: {
      id: "west_mambalam",
      cityId: "chennai",
      nameEn: "West Mambalam",
      nameTa: "மேற்கு மாம்பலம்",
      mapCenter: { latitude: 13.0382, longitude: 80.2219 },
      defaultZoom: 0.018,
      landmarks: [
        landmark("mambalam_railway", "Mambalam Railway Station", "மாம்பலம் ரயில் நிலையம்", 13.0385, 80.2225),
        landmark("postal_colony", "Postal Colony", "போஸ்டல் காலனி", 13.0402, 80.2208),
        landmark("arya_gowda", "Arya Gowda Road", "ஆர்ய கவுடா சாலை", 13.0368, 80.2195),
      ],
    },
    thiruvanmiyur: {
      id: "thiruvanmiyur",
      cityId: "chennai",
      nameEn: "Thiruvanmiyur",
      nameTa: "திருவான்மியூர்",
      mapCenter: { latitude: 12.985, longitude: 80.259 },
      defaultZoom: 0.02,
      landmarks: [
        landmark("thiruvanmiyur_mrts", "Thiruvanmiyur MRTS", "திருவான்மியூர் எம்ஆர்டிஎஸ்", 12.9855, 80.2594),
        landmark("marundeeswarar", "Marundeeswarar Temple", "மருந்தீஸ்வரர் கோயில்", 12.9842, 80.2608),
        landmark("ecr_junction", "East Coast Road junction", "ஈசிஆர் சந்திப்பு", 12.9905, 80.255),
      ],
    },
  };
}

/** 14 + 13 + 13 = 40 */
function neighborhoodQuota(indexZeroBased) {
  if (indexZeroBased < 14) return "t_nagar";
  if (indexZeroBased < 27) return "west_mambalam";
  return "thiruvanmiyur";
}

function buildVendors(neighborhoods, now) {
  const vendors = {};
  for (let i = 0; i < 40; i += 1) {
    const id = `vendor_${String(i + 1).padStart(3, "0")}`;
    const displayName = VENDOR_NAMES[i % VENDOR_NAMES.length];
    const categoryId = ASSIGNABLE_CATEGORIES[i % ASSIGNABLE_CATEGORIES.length];
    const neighborhoodId = neighborhoodQuota(i);
    const neighborhood = neighborhoods[neighborhoodId];
    const label = categoryId.replace(/_/g, " ");

    vendors[id] = {
      id,
      displayName,
      businessName: i % 3 === 0 ? `${displayName} Cart` : null,
      categoryId,
      cityId: "chennai",
      neighborhoodId,
      languages: ["ta", "en"],
      workingHours: {
        start: "06:00",
        end: "20:00",
        labelEn: "6:00 AM – 8:00 PM",
        labelTa: "காலை 6:00 – இரவு 8:00",
      },
      ratingSummary: {
        average: Number((3.8 + ((i % 12) * 0.1)).toFixed(1)),
        count: 8 + (i % 45),
      },
      memberSince: "2025-11",
      descriptionEnglish: `${displayName} offers ${label} around ${neighborhood.nameEn} (synthetic Chennai pilot profile).`,
      descriptionTamil: `${displayName} ${neighborhood.nameTa} பகுதியில் ${label} வழங்குகிறார் (செயற்கை பைலட் சுயவிவரம்).`,
      verified: false,
      photoURL: null,
      phone: null,
      active: true,
      createdAt: isoHoursAgo(24 * (20 + i), now),
    };
  }
  return vendors;
}

function buildStatusAndLocations(vendors, neighborhoods, now) {
  const rand = mulberry32(20260727);
  const vendor_status = {};
  const vendor_locations = {};
  const vendorIds = Object.keys(vendors);
  const liveCount = Math.round(vendorIds.length / 3);

  vendorIds.forEach((vendorId, idx) => {
    const vendor = vendors[vendorId];
    const neighborhood = neighborhoods[vendor.neighborhoodId];
    const landmarks = neighborhood.landmarks;
    const spot = landmarks[idx % landmarks.length];
    const isLive = idx < liveCount;

    vendor_status[vendorId] = {
      sellerId: vendorId,
      vendorId,
      isLive,
      lastSeen: isoHoursAgo(isLive ? 0.1 : 4 + (idx % 10), now),
      startedAt: isLive ? isoHoursAgo(1 + (idx % 3), now) : null,
      availabilityText: isLive ? "Live nearby now" : "Offline — see My Day",
      availabilityTextEn: isLive ? "Live nearby now" : "Offline — see My Day",
      availabilityTextTa: isLive ? "இப்போது அருகில் நேரலை" : "ஆஃப்லைன் — இன்றைய பயணத்தைப் பாருங்கள்",
    };

    vendor_locations[vendorId] = {
      sellerId: vendorId,
      vendorId,
      latitude: jitter(rand, spot.latitude, 0.004),
      longitude: jitter(rand, spot.longitude, 0.004),
      heading: Math.floor(rand() * 360),
      speed: isLive ? Number((0.3 + rand() * 1.7).toFixed(2)) : 0,
      accuracy: Number((8 + rand() * 18).toFixed(1)),
      updatedAt: isoHoursAgo(isLive ? 0.05 : 2.5, now),
      neighborhoodId: vendor.neighborhoodId,
      landmark: spot.nameEn,
      landmarkEn: spot.nameEn,
      landmarkTa: spot.nameTa,
    };
  });

  return { vendor_status, vendor_locations, liveCount };
}

function buildRoutes(vendors, neighborhoods, vendor_locations, now) {
  const vendor_routes = {};
  const routeDate = todayDateString(now);
  // First 28 vendors get morning routes (majority coverage).
  const vendorIds = Object.keys(vendors).slice(0, 28);

  for (const vendorId of vendorIds) {
    const vendor = vendors[vendorId];
    const neighborhood = neighborhoods[vendor.neighborhoodId];
    const landmarks = neighborhood.landmarks;
    const stopCount = 3 + (vendorId.charCodeAt(vendorId.length - 1) % 3);
    const stops = {};
    const currentIndex = Math.min(1, stopCount - 1);
    const baseLat = vendor_locations[vendorId]?.latitude ?? neighborhood.mapCenter.latitude;
    const baseLng = vendor_locations[vendorId]?.longitude ?? neighborhood.mapCenter.longitude;

    for (let s = 0; s < stopCount; s += 1) {
      const spot = landmarks[s % landmarks.length];
      const stopId = `stop_${String(s + 1).padStart(2, "0")}`;
      const hour = 6 + s * 2;
      let status = "upcoming";
      if (s < currentIndex) status = "completed";
      if (s === currentIndex) status = "current";

      stops[stopId] = {
        id: stopId,
        sequence: s + 1,
        time: `${String(hour).padStart(2, "0")}:${s % 2 === 0 ? "00" : "30"}`,
        title: spot.nameEn,
        titleEn: spot.nameEn,
        titleTa: spot.nameTa,
        neighborhoodId: vendor.neighborhoodId,
        latitude: Number((baseLat + (s - 1) * 0.0014).toFixed(6)),
        longitude: Number((baseLng + (s - 1) * 0.0011).toFixed(6)),
        status,
      };
    }

    vendor_routes[vendorId] = {
      vendorId,
      routeDate,
      stops,
    };
  }

  return vendor_routes;
}

function buildAnnouncements(vendors, now) {
  const vendor_announcements = {};
  const intervals = [10, 15, 20];
  const vendorIds = Object.keys(vendors).slice(0, 22);

  vendorIds.forEach((vendorId, idx) => {
    const vendor = vendors[vendorId];
    vendor_announcements[vendorId] = {
      sellerId: vendorId,
      vendorId,
      duration: 8 + (idx % 16),
      language: idx % 2 === 0 ? "ta" : "en",
      storagePath: `announcements/dev/${vendorId}/sample.m4a`,
      recordedAt: isoHoursAgo(1 + (idx % 8), now),
      transcriptEnglish: `Hello, this is ${vendor.displayName}. Fresh goods nearby in the Chennai pilot.`,
      transcriptTamil: `வணக்கம், நான் ${vendor.displayName}. சென்னை பைலட்டில் அருகில் புதிய பொருட்கள் உள்ளன.`,
      playbackIntervalMinutes: intervals[idx % intervals.length],
      hasAnnouncement: true,
      activeWhileLive: true,
    };
  });

  return vendor_announcements;
}

function buildCustomers(now) {
  const customers = {};
  CUSTOMER_NAMES.forEach((displayName, i) => {
    const id = `customer_${String(i + 1).padStart(3, "0")}`;
    customers[id] = {
      id,
      displayName,
      cityId: "chennai",
      neighborhoodId: NEIGHBORHOOD_IDS[i % NEIGHBORHOOD_IDS.length],
      languages: i % 4 === 0 ? ["ta"] : ["ta", "en"],
      photoURL: null,
      createdAt: isoHoursAgo(24 * (8 + i), now),
    };
  });
  return customers;
}

function buildFavorites(customers, vendors) {
  const customer_favorites = {};
  const vendorIds = Object.keys(vendors);

  Object.keys(customers).forEach((customerId, idx) => {
    const count = 1 + (idx % 5);
    const map = {};
    for (let i = 0; i < count; i += 1) {
      const vendorId = vendorIds[(idx * 3 + i * 7) % vendorIds.length];
      map[vendorId] = true;
    }
    customer_favorites[customerId] = map;
  });

  return customer_favorites;
}

function buildCustomerSettings(customers) {
  const customer_settings = {};
  Object.keys(customers).forEach((customerId, idx) => {
    customer_settings[customerId] = {
      customerId,
      preferredLanguage: idx % 3 === 0 ? "ta" : "en",
      notificationsEnabled: true,
      announcementAutoplay: false,
      distanceUnit: "meters",
      updatedAt: new Date().toISOString(),
    };
  });
  return customer_settings;
}

/**
 * Builds the permanent RediWala RTDB payload for the Chennai pilot seed.
 */
export function buildDataset(now = new Date()) {
  const cities = buildCities();
  const categoryGroups = buildCategoryGroups();
  const categories = buildCategories();
  const neighborhoods = buildNeighborhoods();
  const vendors = buildVendors(neighborhoods, now);
  const { vendor_status, vendor_locations, liveCount } = buildStatusAndLocations(
    vendors,
    neighborhoods,
    now
  );
  const vendor_routes = buildRoutes(vendors, neighborhoods, vendor_locations, now);
  const vendor_announcements = buildAnnouncements(vendors, now);
  const customers = buildCustomers(now);
  const customer_favorites = buildFavorites(customers, vendors);
  const customer_settings = buildCustomerSettings(customers);

  const metadata = {
    schemaVersion: "2.0",
    generatedAt: now.toISOString(),
    environment: "development",
    pilotCity: "Chennai",
    pilotCityId: "chennai",
    pilotNeighborhoods: [...NEIGHBORHOOD_IDS],
    seedTag: "chennai_pilot_permanent_v2",
  };

  const payload = {
    metadata,
    cities,
    neighborhoods,
    categoryGroups,
    categories,
    vendors,
    vendor_status,
    vendor_locations,
    vendor_routes,
    vendor_announcements,
    customers,
    customer_favorites,
    customer_settings,
  };

  const counts = {
    cities: Object.keys(cities).length,
    categoryGroups: Object.keys(categoryGroups).length,
    categories: Object.keys(categories).length,
    neighborhoods: Object.keys(neighborhoods).length,
    vendors: Object.keys(vendors).length,
    liveVendors: liveCount,
    vendor_locations: Object.keys(vendor_locations).length,
    vendor_routes: Object.keys(vendor_routes).length,
    vendor_announcements: Object.keys(vendor_announcements).length,
    customers: Object.keys(customers).length,
    customer_settings: Object.keys(customer_settings).length,
    favoriteRelationships: Object.values(customer_favorites).reduce(
      (sum, map) => sum + Object.keys(map).length,
      0
    ),
  };

  return { payload, counts };
}
