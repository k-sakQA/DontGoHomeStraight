// #if canImport(XCTest)
import XCTest
@testable import DontGoHomeStraight

final class GenreTests: XCTestCase {
    
    // MARK: - Test Genre Creation
    
    func test_ジャンル作成_正常ケース() {
        // Given
        let id = "test-id"
        let name = "カフェ"
        let category = GenreCategory.restaurant
        let googleMapType = "cafe"
        
        // When
        let genre = Genre(id: id, name: name, category: category, googleMapType: googleMapType)
        
        // Then
        XCTAssertEqual(genre.id, id)
        XCTAssertEqual(genre.name, name)
        XCTAssertEqual(genre.category, category)
        XCTAssertEqual(genre.googleMapType, googleMapType)
    }
    
    func test_ジャンル作成_IDの自動生成() {
        // Given & When
        let genre = Genre(name: "公園", category: .other, googleMapType: "park")
        
        // Then
        XCTAssertFalse(genre.id.isEmpty)
        XCTAssertEqual(genre.name, "公園")
        XCTAssertEqual(genre.category, .other)
    }
    
    // MARK: - Test GenreCategory
    
    func test_ジャンルカテゴリ_表示名() {
        // Given & When & Then
        XCTAssertEqual(GenreCategory.restaurant.displayName, "グルメ")
        XCTAssertEqual(GenreCategory.other.displayName, "その他")
    }
    
    func test_ジャンルカテゴリ_絵文字() {
        // Given & When & Then
        XCTAssertEqual(GenreCategory.restaurant.emoji, "🍽️")
        XCTAssertEqual(GenreCategory.other.emoji, "🏛️")
    }
    
    // MARK: - Test Random Category Distribution
    
    func test_ランダムカテゴリ_分布確認() {
        // Given
        let sampleSize = 1000
        var restaurantCount = 0
        
        // When
        for _ in 0..<sampleSize {
            if GenreCategory.getRandomCategory() == .restaurant {
                restaurantCount += 1
            }
        }
        
        // Then
        let restaurantRatio = Double(restaurantCount) / Double(sampleSize)
        
        // 30%の範囲内（25%-35%で許容）
        XCTAssertGreaterThan(restaurantRatio, 0.25, "レストラン比率が低すぎます: \(restaurantRatio)")
        XCTAssertLessThan(restaurantRatio, 0.35, "レストラン比率が高すぎます: \(restaurantRatio)")
    }
    
    // MARK: - Test Category Distribution
    
    func test_カテゴリ分配_3件の場合() {
        // Given
        let totalCount = 3
        
        // When
        let categories = GenreCategory.distributeCategories(totalCount: totalCount)
        
        // Then
        XCTAssertEqual(categories.count, 3)
        
        let restaurantCount = categories.filter { $0 == .restaurant }.count
        let otherCount = categories.filter { $0 == .other }.count
        
        XCTAssertEqual(restaurantCount, 1) // 30% of 3 = 1
        XCTAssertEqual(otherCount, 2) // 70% of 3 = 2
    }
    
    func test_カテゴリ分配_5件の場合() {
        // Given
        let totalCount = 5
        
        // When
        let categories = GenreCategory.distributeCategories(totalCount: totalCount)
        
        // Then
        XCTAssertEqual(categories.count, 5)
        
        let restaurantCount = categories.filter { $0 == .restaurant }.count
        let otherCount = categories.filter { $0 == .other }.count
        
        XCTAssertEqual(restaurantCount, 1) // max(1, 30% of 5) = 1
        XCTAssertEqual(otherCount, 4) // 5 - 1 = 4
    }
    
    func test_カテゴリ分配_10件の場合() {
        // Given
        let totalCount = 10
        
        // When
        let categories = GenreCategory.distributeCategories(totalCount: totalCount)
        
        // Then
        XCTAssertEqual(categories.count, 10)
        
        let restaurantCount = categories.filter { $0 == .restaurant }.count
        let otherCount = categories.filter { $0 == .other }.count
        
        XCTAssertEqual(restaurantCount, 3) // 30% of 10 = 3
        XCTAssertEqual(otherCount, 7) // 70% of 10 = 7
    }
    
    func test_カテゴリ分配_1件の場合() {
        // Given
        let totalCount = 1
        
        // When
        let categories = GenreCategory.distributeCategories(totalCount: totalCount)
        
        // Then
        XCTAssertEqual(categories.count, 1)
        
        let restaurantCount = categories.filter { $0 == .restaurant }.count
        
        XCTAssertEqual(restaurantCount, 1) // max(1, 30% of 1) = 1
    }
    
    // MARK: - Test Common Genres
    
    func test_共通レストランジャンル() {
        // Given & When
        let restaurantGenres = Genre.commonRestaurantGenres
        
        // Then
        XCTAssertFalse(restaurantGenres.isEmpty)
        
        for genre in restaurantGenres {
            XCTAssertEqual(genre.category, .restaurant)
            XCTAssertFalse(genre.name.isEmpty)
            XCTAssertFalse(genre.googleMapType.isEmpty)
        }
    }
    
    func test_共通その他ジャンル() {
        // Given & When
        let otherGenres = Genre.commonOtherGenres
        
        // Then
        XCTAssertFalse(otherGenres.isEmpty)
        
        for genre in otherGenres {
            XCTAssertEqual(genre.category, .other)
            XCTAssertFalse(genre.name.isEmpty)
            XCTAssertFalse(genre.googleMapType.isEmpty)
        }
    }
    
    // MARK: - Test Equality and Hashable
    
    func test_ジャンルの等価性() {
        // Given
        let id = "test-id"
        let genre1 = Genre(id: id, name: "カフェ", category: .restaurant, googleMapType: "cafe")
        let genre2 = Genre(id: id, name: "別の名前", category: .other, googleMapType: "park")
        
        // When & Then
        XCTAssertEqual(genre1, genre2) // IDが同じなら等価
    }
    
    func test_ジャンルのハッシュ値() {
        // Given
        let id = "test-id"
        let genre1 = Genre(id: id, name: "カフェ", category: .restaurant, googleMapType: "cafe")
        let genre2 = Genre(id: id, name: "別の名前", category: .other, googleMapType: "park")
        
        // When & Then
        XCTAssertEqual(genre1.hashValue, genre2.hashValue) // IDが同じならハッシュ値も同じ
    }
    
    // MARK: - Test Codable
    
    func test_ジャンルのエンコード_デコード() throws {
        // Given
        let originalGenre = Genre(name: "美術館", category: .other, googleMapType: "museum")
        
        // When
        let encodedData = try JSONEncoder().encode(originalGenre)
        let decodedGenre = try JSONDecoder().decode(Genre.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalGenre.id, decodedGenre.id)
        XCTAssertEqual(originalGenre.name, decodedGenre.name)
        XCTAssertEqual(originalGenre.category, decodedGenre.category)
        XCTAssertEqual(originalGenre.googleMapType, decodedGenre.googleMapType)
    }
}
// #endif