import Foundation
import CoreLocation

/// 寄り道図鑑に記録される訪問済みスポット
struct VisitedSpot: Codable, Identifiable {
    /// Google PlacesのplaceIdをそのままIDとして使用
    let id: String
    let name: String
    let address: String
    let genreName: String
    let genreCategory: GenreCategory
    let googleMapType: String
    let coordinate: CLLocationCoordinate2D
    let photoReference: String?
    let rating: Double?
    let userRatingsTotal: Int?
    let rarity: SpotRarity
    let firstVisitedAt: Date
    var lastVisitedAt: Date
    var visitCount: Int
    var moodDescription: String?

    init(place: Place, mood: Mood?, visitedAt: Date = Date()) {
        self.id = place.placeId
        self.name = place.name
        self.address = place.address
        self.genreName = place.genre.name
        self.genreCategory = place.genre.category
        self.googleMapType = place.genre.googleMapType
        self.coordinate = place.coordinate
        self.photoReference = place.photoReference
        self.rating = place.rating
        self.userRatingsTotal = place.userRatingsTotal
        self.rarity = SpotRarity.evaluate(rating: place.rating, reviewCount: place.userRatingsTotal)
        self.firstVisitedAt = visitedAt
        self.lastVisitedAt = visitedAt
        self.visitCount = 1
        self.moodDescription = mood?.description
    }
}

// MARK: - Equatable
extension VisitedSpot: Equatable {
    static func == (lhs: VisitedSpot, rhs: VisitedSpot) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Spot Rarity

/// スポットのレアリティ（評価×口コミ数から「隠れ家度」を判定）
enum SpotRarity: String, Codable, CaseIterable {
    case standard = "standard"
    case rare = "rare"
    case secret = "secret"

    var displayName: String {
        switch self {
        case .standard: return "定番"
        case .rare: return "レア"
        case .secret: return "シークレット"
        }
    }

    var stars: Int {
        switch self {
        case .standard: return 1
        case .rare: return 2
        case .secret: return 3
        }
    }

    var colorHex: String {
        switch self {
        case .standard: return "6C757D"
        case .rare: return "3A7DFF"
        case .secret: return "D4A017"
        }
    }

    /// 高評価かつ口コミが少ない「知る人ぞ知る」スポットほどレア
    static func evaluate(rating: Double?, reviewCount: Int?) -> SpotRarity {
        guard let rating = rating else { return .standard }
        let reviews = reviewCount ?? 0
        if rating >= 4.4 && reviews > 0 && reviews < 200 {
            return .secret
        }
        if rating >= 4.0 {
            return .rare
        }
        return .standard
    }
}

// MARK: - Display Helpers
extension VisitedSpot {
    var formattedLastVisit: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: lastVisitedAt)
    }

    var categoryEmoji: String {
        return genreCategory.emoji
    }
}
