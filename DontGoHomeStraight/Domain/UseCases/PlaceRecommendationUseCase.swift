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
        // 1) 除外リスト
        let excludedPlaceIds = await cacheRepository.getExcludedPlaceIds()
        
        // 2) OpenAIから候補（10件）
        let request = AIRecommendationRequest(
            currentLocation: currentLocation,
            destination: destination,
            currentTime: Date(),
            mood: mood,
            transportMode: transportMode,
            excludedPlaceIds: excludedPlaceIds
        )
        let candidates = try await aiRepository.getRecommendations(request: request)
        if candidates.isEmpty { throw AIRecommendationError.noValidPlaces }
        
        // 3) Places Text Search で place 解決（name -> Place）
        let resolvedPlaces = try await placeRepository.searchPlaces(
            names: candidates.map { $0.name },
            near: currentLocation
        )
        
        // name -> LLMCandidate のマップ
        let nameToCandidate: [String: LLMCandidate] = Dictionary(uniqueKeysWithValues: candidates.map { ($0.name, $0) })
        
        // 4) Distance Matrix で current -> place の所要時間（秒）
        let dmClient = GoogleDistanceMatrixClient(apiKey: Environment.googlePlacesAPIKey)
        let dmInputs = resolvedPlaces.map { $0.coordinate }
        let durationsSec = try await dmClient.getDurationsSeconds(
            origin: currentLocation,
            destinations: dmInputs,
            mode: transportMode
        )
        
        // 5) 室内は open_now=true（Details）: 必要なものだけ問い合わせ
        let detailsClient = GooglePlaceDetailsOpenClient(placeRepository: placeRepository)
        var openNowMap: [String: Bool] = [:]
        for place in resolvedPlaces {
            if isIndoor(place: place) {
                let isOpen = try await detailsClient.isOpenNow(placeId: place.placeId)
                openNowMap[place.placeId] = isOpen
            }
        }
        
        // 6) 30分以内、open_now、除外 place_id をフィルタ
        let maxDuration = 30.0 * 60.0
        var eligible: [ScoredPlace] = []
        for (idx, place) in resolvedPlaces.enumerated() {
            guard idx < durationsSec.count else { continue }
            let duration = durationsSec[idx]
            guard duration.isFinite, duration <= maxDuration else { continue }
            if excludedPlaceIds.contains(place.placeId) { continue }
            if isIndoor(place: place), let open = openNowMap[place.placeId], open == false { continue }
            let candidateCategory = nameToCandidate[place.name]?.category ?? place.genre.category
            eligible.append(ScoredPlace(place: place, candidateCategory: candidateCategory, durationSec: duration))
        }
        
        if eligible.isEmpty { throw AIRecommendationError.noValidPlaces }
        
        // 7) スコアリング
        let scored = scorePlaces(eligible: eligible, primaryRoute: nil)
            .sorted { $0.score > $1.score }
        
        // 8) 30/70構成を強制: まず restaurant から1、次に other から2、足りなければ補完
        let restaurants = scored.filter { $0.candidateCategory == .restaurant }
        let others = scored.filter { $0.candidateCategory == .other }
        
        var picked: [ScoredPlace] = []
        if let topRestaurant = restaurants.first { picked.append(topRestaurant) }
        for s in others { if picked.count < 3 { picked.append(s) } }
        if picked.count < 3 {
            // 補完
            for s in restaurants { if picked.contains(where: { $0.place.placeId == s.place.placeId }) == false && picked.count < 3 { picked.append(s) } }
        }
        
        let finalThree = Array(picked.prefix(3))
        if finalThree.isEmpty { throw AIRecommendationError.noValidPlaces }
        
        // 9) ジャンルを返す（常に3件に切り詰め）
        let genres = finalThree.map { sp -> Genre in
            let category = determineCategoryFromPlaceType(sp.place.genre.googleMapType)
            return Genre(
                name: mapPlaceTypeToGenreName(sp.place.genre.googleMapType, category: category),
                category: category,
                googleMapType: sp.place.genre.googleMapType
            )
        }
        
        // キャッシュへ保存と除外
        await cacheRepository.savePlacesForGenres(places: finalThree.map { $0.place }, genres: genres)
        for sp in finalThree { await cacheRepository.addExcludedPlaceId(sp.place.placeId) }
        
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

// MARK: - Scoring and helpers

private struct ScoredPlace: Hashable {
    let place: Place
    let candidateCategory: GenreCategory
    let durationSec: TimeInterval
    var score: Double = 0
}

private extension PlaceRecommendationUseCaseImpl {
    func isIndoor(place: Place) -> Bool {
        // 室内が想定される type 群
        let indoorTypes: Set<String> = [
            "restaurant", "cafe", "bar", "bakery", "shopping_mall", "movie_theater",
            "museum", "library", "book_store"
        ]
        return indoorTypes.contains(place.genre.googleMapType)
    }
    
    func scorePlaces(eligible: [ScoredPlace], primaryRoute: String?) -> [ScoredPlace] {
        // 重み
        let weightDuration = 1.0
        let weightOnRoute = 3.0
        let weightRating = 0.5
        let weightDiversity = 0.5
        
        // ここでは on-route 判定はスキップ（必要なら Directions overview_polyline 近傍判定に置換）
        func onRouteBonus(for _: Place) -> Double { return 0 }
        
        // チェーン・近接の簡易ペナルティ（同名開始 or 300m以内）
        func diversityPenalty(for place: Place, picked: [ScoredPlace]) -> Double {
            for p in picked {
                if p.place.name.split(separator: " ").first == place.name.split(separator: " ").first { return 0.5 }
                let d = p.place.distance(from: place.coordinate)
                if d < 300 { return 0.5 }
            }
            return 0
        }
        
        var out: [ScoredPlace] = []
        for var sp in eligible {
            let durationComponent = -weightDuration * (sp.durationSec / 60.0)
            let onRouteComponent = weightOnRoute * onRouteBonus(for: sp.place)
            let ratingValue = sp.place.rating ?? 0
            let ratingComponent = weightRating * ratingValue
            let penalty = weightDiversity * diversityPenalty(for: sp.place, picked: out)
            sp.score = durationComponent + onRouteComponent + ratingComponent - penalty
            out.append(sp)
        }
        return out
    }
}