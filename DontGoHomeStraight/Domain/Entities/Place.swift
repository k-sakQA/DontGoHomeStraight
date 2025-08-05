import Foundation
import CoreLocation

struct Place {
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
        vicinity: String? = nil
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