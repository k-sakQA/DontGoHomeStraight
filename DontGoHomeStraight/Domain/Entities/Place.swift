import Foundation
import CoreLocation

struct Place: Codable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    let genre: Genre
    let rating: Double?
    let priceLevel: Int?
    let photoReference: String?
    let isOpen: Bool?
    let placeId: String
    let vicinity: String?
    let userRatingsTotal: Int?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        coordinate: CLLocationCoordinate2D,
        address: String,
        genre: Genre,
        rating: Double? = nil,
        priceLevel: Int? = nil,
        photoReference: String? = nil,
        isOpen: Bool? = nil,
        placeId: String,
        vicinity: String? = nil,
        userRatingsTotal: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.address = address
        self.genre = genre
        self.rating = rating
        self.priceLevel = priceLevel
        self.photoReference = photoReference
        self.isOpen = isOpen
        self.placeId = placeId
        self.vicinity = vicinity
        self.userRatingsTotal = userRatingsTotal
    }
}

// MARK: - Equatable
extension Place: Equatable {
    static func == (lhs: Place, rhs: Place) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Place: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Computed Properties
extension Place {
    var displayRating: String {
        guard let rating = rating else { return "評価なし" }
        return String(format: "★%.1f", rating)
    }
    
    var displayReviews: String {
        guard let reviews = userRatingsTotal else { return "" }
        return "(" + String(reviews) + ")"
    }
    
    var displayPriceLevel: String {
        guard let priceLevel = priceLevel else { return "" }
        return String(repeating: "¥", count: max(1, min(priceLevel, 4)))
    }
    
    var openStatusText: String {
        guard let isOpen = isOpen else { return "営業時間不明" }
        return isOpen ? "営業中" : "閉店中"
    }
    
    var openStatusEmoji: String {
        guard let isOpen = isOpen else { return "❓" }
        return isOpen ? "🟢" : "🔴"
    }
}

// MARK: - Distance Calculation
extension Place {
    func distance(from location: CLLocationCoordinate2D) -> CLLocationDistance {
        let placeLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return placeLocation.distance(from: userLocation)
    }
    
    func formattedDistance(from location: CLLocationCoordinate2D) -> String {
        let distance = distance(from: location)
        if distance < 1000 {
            return String(format: "%.0fm", distance)
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

// MARK: - CLLocationCoordinate2D Codable Extension
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}