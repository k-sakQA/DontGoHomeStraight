import Foundation

struct Genre {
    let id: String
    let name: String
    let category: GenreCategory
    let googleMapType: String
    
    init(id: String = UUID().uuidString, name: String, category: GenreCategory, googleMapType: String) {
        self.id = id
        self.name = name
        self.category = category
        self.googleMapType = googleMapType
    }
}

enum GenreCategory: String, CaseIterable {
    case restaurant = "restaurant"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .restaurant: return "グルメ"
        case .other: return "その他"
        }
    }
    
    var emoji: String {
        switch self {
        case .restaurant: return "🍽️"
        case .other: return "🏛️"
        }
    }
    
    // 30% : 70% の比率でカテゴリを決定
    static func getRandomCategory() -> GenreCategory {
        return Int.random(in: 1...10) <= 3 ? .restaurant : .other
    }
    
    // 指定された数でカテゴリを分配
    static func distributeCategories(totalCount: Int) -> [GenreCategory] {
        let restaurantCount = max(1, Int(Double(totalCount) * 0.3))
        let otherCount = totalCount - restaurantCount
        
        var categories: [GenreCategory] = []
        categories.append(contentsOf: Array(repeating: .restaurant, count: restaurantCount))
        categories.append(contentsOf: Array(repeating: .other, count: otherCount))
        
        return categories.shuffled()
    }
}

// MARK: - Equatable
extension Genre: Equatable {
    static func == (lhs: Genre, rhs: Genre) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Genre: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Codable
extension Genre: Codable {}
extension GenreCategory: Codable {}

// MARK: - Common Genres
extension Genre {
    static let commonRestaurantGenres = [
        Genre(name: "カフェ", category: .restaurant, googleMapType: "cafe"),
        Genre(name: "レストラン", category: .restaurant, googleMapType: "restaurant"),
        Genre(name: "ファストフード", category: .restaurant, googleMapType: "meal_takeaway"),
        Genre(name: "バー", category: .restaurant, googleMapType: "bar"),
        Genre(name: "ベーカリー", category: .restaurant, googleMapType: "bakery")
    ]
    
    static let commonOtherGenres = [
        Genre(name: "公園", category: .other, googleMapType: "park"),
        Genre(name: "美術館", category: .other, googleMapType: "museum"),
        Genre(name: "図書館", category: .other, googleMapType: "library"),
        Genre(name: "書店", category: .other, googleMapType: "book_store"),
        Genre(name: "ショッピングモール", category: .other, googleMapType: "shopping_mall"),
        Genre(name: "神社・寺院", category: .other, googleMapType: "place_of_worship"),
        Genre(name: "映画館", category: .other, googleMapType: "movie_theater")
    ]
}