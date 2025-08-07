import Foundation
import CoreLocation

protocol PlaceRecommendationUseCase {
    func getRecommendations(
        currentLocation: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mood: Mood,
        transportMode: TransportMode
    ) async throws -> [Genre]
    
    func clearCache() async throws
}

class PlaceRecommendationUseCaseImpl: PlaceRecommendationUseCase {
    private let aiRepository: AIRecommendationRepository
    private let placeRepository: PlaceRepository
    private let cacheRepository: CacheRepository
    
    init(
        aiRepository: AIRecommendationRepository,
        placeRepository: PlaceRepository,
        cacheRepository: CacheRepository
    ) {
        self.aiRepository = aiRepository
        self.placeRepository = placeRepository
        self.cacheRepository = cacheRepository
    }
    
    func getRecommendations(
        currentLocation: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mood: Mood,
        transportMode: TransportMode
    ) async throws -> [Genre] {
        // 1. キャッシュから除外リストを取得
        let excludedPlaceIds = await cacheRepository.getExcludedPlaceIds()
        
        // 2. OpenAI APIで推薦を取得
        let request = AIRecommendationRequest(
            currentLocation: currentLocation,
            destination: destination,
            currentTime: Date(),
            mood: mood,
            transportMode: transportMode,
            excludedPlaceIds: excludedPlaceIds
        )
        
        let aiRecommendations = try await aiRepository.getRecommendations(request: request)
        
        // 3. Google Places APIで実在性を確認し、有効なスポットを取得
        var validPlaces: [Place] = []
        
        #if DEBUG
        print("🔍 Searching \(aiRecommendations.count) recommendations in Google Places API:")
        #endif
        
        for (index, recommendationName) in aiRecommendations.enumerated() {
            #if DEBUG
            print("  \(index + 1). Searching: \(recommendationName)")
            #endif
            
            do {
                if let place = try await placeRepository.searchPlace(
                    name: recommendationName,
                    near: currentLocation
                ) {
                    #if DEBUG
                    print("    ✅ Found: \(place.name)")
                    #endif
                    validPlaces.append(place)
                } else {
                    #if DEBUG
                    print("    ❌ Not found")
                    #endif
                }
            } catch {
                #if DEBUG
                print("    ❌ Error: \(error)")
                #endif
            }
        }
        
        // 4. 3件に満たない場合は追加検索
        if validPlaces.count < 3 {
            let additionalPlaces = try await searchAdditionalPlaces(
                location: currentLocation,
                mood: mood,
                needed: 3 - validPlaces.count,
                excludeIds: validPlaces.map { $0.placeId }
            )
            validPlaces.append(contentsOf: additionalPlaces)
        }
        
        // 5. 候補なしの場合
        if validPlaces.isEmpty {
            throw AIRecommendationError.noValidPlaces
        }
        
        // 6. ジャンル情報のみ返却（スポット名は隠匿）
        let genres = createGenresFromPlaces(validPlaces)
        
        // 7. 提案したスポットをキャッシュに保存（ジャンルとの関連付け）
        await cacheRepository.savePlacesForGenres(places: validPlaces, genres: genres)
        
        // 8. 除外リストに追加
        for place in validPlaces {
            await cacheRepository.addExcludedPlaceId(place.placeId)
        }
        
        return Array(genres.prefix(3))
    }
    
    private func searchAdditionalPlaces(
        location: CLLocationCoordinate2D,
        mood: Mood,
        needed: Int,
        excludeIds: [String]
    ) async throws -> [Place] {
        // 気分に基づいてスポットタイプを決定
        let types = getSearchTypesForMood(mood)
        var additionalPlaces: [Place] = []
        
        for type in types {
            if additionalPlaces.count >= needed { break }
            
            let places = try await placeRepository.searchPlaces(
                location: location,
                type: type,
                radius: 3000
            )
            
            let filteredPlaces = places.filter { place in
                !excludeIds.contains(place.placeId)
            }
            
            additionalPlaces.append(contentsOf: filteredPlaces)
        }
        
        return Array(additionalPlaces.prefix(needed))
    }
    
    private func getSearchTypesForMood(_ mood: Mood) -> [String] {
        switch (mood.activityType, mood.vibeType) {
        case (.indoor, .jazzy):
            return ["cafe", "bar", "library", "museum"]
        case (.indoor, .discovery):
            return ["museum", "book_store", "art_gallery", "library"]
        case (.indoor, .exciting):
            return ["shopping_mall", "movie_theater", "amusement_center"]
        case (.outdoor, .jazzy):
            return ["park", "cafe", "tourist_attraction"]
        case (.outdoor, .discovery):
            return ["tourist_attraction", "park", "cemetery", "zoo"]
        case (.outdoor, .exciting):
            return ["amusement_park", "park", "stadium", "tourist_attraction"]
        }
    }
    
    private func createGenresFromPlaces(_ places: [Place]) -> [Genre] {
        var genres: [Genre] = []
        
        for (index, place) in places.enumerated() {
            if index >= 3 { break }
            
            // 実際のスポットの種類に基づいてカテゴリーを決定
            let category = determineCategoryFromPlaceType(place.genre.googleMapType)
            let genre = Genre(
                name: mapPlaceTypeToGenreName(place.genre.googleMapType, category: category),
                category: category,
                googleMapType: place.genre.googleMapType
            )
            genres.append(genre)
        }
        
        return genres
    }
    
    private func determineCategoryFromPlaceType(_ googleMapType: String) -> GenreCategory {
        switch googleMapType {
        case "restaurant", "cafe", "bar", "meal_takeaway", "bakery":
            return .restaurant
        default:
            return .other
        }
    }
    
    private func mapPlaceTypeToGenreName(_ googleMapType: String, category: GenreCategory) -> String {
        // Google Places APIのタイプから日本語ジャンル名にマッピング
        switch googleMapType {
        case "restaurant": return "レストラン"
        case "cafe": return "カフェ"
        case "bar": return "バー"
        case "meal_takeaway": return "テイクアウト"
        case "bakery": return "ベーカリー"
        case "park": return "公園"
        case "museum": return "美術館・博物館"
        case "library": return "図書館"
        case "book_store": return "書店"
        case "shopping_mall": return "ショッピングモール"
        case "movie_theater": return "映画館"
        case "tourist_attraction": return "観光スポット"
        case "place_of_worship": return "神社・寺院"
        case "amusement_park": return "遊園地"
        case "zoo": return "動物園"
        default:
            return category == .restaurant ? "グルメ" : "スポット"
        }
    }
    
    func clearCache() async throws {
        await cacheRepository.clearCache()
    }
}