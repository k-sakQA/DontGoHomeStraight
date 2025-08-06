import Foundation
import CoreLocation

class PlaceRepositoryImpl: PlaceRepository {
    private let googlePlacesClient: GooglePlacesAPIClient
    
    init(apiClient: GooglePlacesAPIClient) {
        self.googlePlacesClient = apiClient
    }
    
    func searchPlace(name: String, near location: CLLocationCoordinate2D) async throws -> Place? {
        do {
            let place = try await googlePlacesClient.searchPlace(name: name, near: location)
            return place
        } catch let error as PlaceRepositoryError {
            throw error
        } catch {
            throw PlaceRepositoryError.searchFailed
        }
    }
    
    func searchPlaces(location: CLLocationCoordinate2D, type: String, radius: Int) async throws -> [Place] {
        do {
            let places = try await googlePlacesClient.searchPlaces(location: location, type: type, radius: radius)
            return places
        } catch let error as PlaceRepositoryError {
            throw error
        } catch {
            throw PlaceRepositoryError.searchFailed
        }
    }
    
    func getNearbyPlaces(location: CLLocationCoordinate2D, radius: Int) async throws -> [Place] {
        do {
            let places = try await googlePlacesClient.getNearbyPlaces(location: location, radius: radius)
            return places
        } catch let error as PlaceRepositoryError {
            throw error
        } catch {
            throw PlaceRepositoryError.searchFailed
        }
    }
    
    func getPlaceDetails(placeId: String) async throws -> Place? {
        do {
            let place = try await googlePlacesClient.getPlaceDetails(placeId: placeId)
            return place
        } catch let error as PlaceRepositoryError {
            throw error
        } catch {
            throw PlaceRepositoryError.invalidPlaceId
        }
    }
    
    func validatePlace(name: String, location: CLLocationCoordinate2D) async throws -> Bool {
        do {
            let isValid = try await googlePlacesClient.validatePlace(name: name, location: location)
            return isValid
        } catch let error as PlaceRepositoryError {
            throw error
        } catch {
            throw PlaceRepositoryError.searchFailed
        }
    }
}

// MARK: - Helper Extensions

extension PlaceRepositoryImpl {
    
    /// 複数のタイプでスポットを検索し、指定された件数まで取得
    func searchPlacesWithMultipleTypes(
        location: CLLocationCoordinate2D,
        types: [String],
        radius: Int,
        maxResults: Int = 20
    ) async throws -> [Place] {
        var allPlaces: [Place] = []
        
        for type in types {
            if allPlaces.count >= maxResults { break }
            
            let places = try await searchPlaces(location: location, type: type, radius: radius)
            allPlaces.append(contentsOf: places)
        }
        
        // 重複除去とシャッフル
        let uniquePlaces = Array(Set(allPlaces))
        return Array(uniquePlaces.shuffled().prefix(maxResults))
    }
    
    /// 気分に基づいてスポットタイプを決定
    func getRecommendedTypes(for mood: Mood) -> [String] {
        switch (mood.activityType, mood.vibeType) {
        case (.indoor, .jazzy):
            return ["cafe", "bar", "museum", "art_gallery", "library"]
        case (.indoor, .discovery):
            return ["museum", "library", "book_store", "art_gallery", "aquarium"]
        case (.indoor, .exciting):
            return ["shopping_mall", "movie_theater", "amusement_center", "game_center"]
        case (.outdoor, .jazzy):
            return ["park", "garden", "scenic_viewpoint", "cafe", "tourist_attraction"]
        case (.outdoor, .discovery):
            return ["tourist_attraction", "park", "historical_site", "zoo", "botanical_garden"]
        case (.outdoor, .exciting):
            return ["amusement_park", "adventure_park", "sports_complex", "beach", "hiking_area"]
        }
    }
    
    /// 距離でフィルタリング
    func filterPlacesByDistance(
        places: [Place],
        from location: CLLocationCoordinate2D,
        maxDistance: CLLocationDistance
    ) -> [Place] {
        return places.filter { place in
            let distance = place.distance(from: location)
            return distance <= maxDistance
        }
    }
    
    /// 評価でソート
    func sortPlacesByRating(_ places: [Place]) -> [Place] {
        return places.sorted { lhs, rhs in
            let lhsRating = lhs.rating ?? 0.0
            let rhsRating = rhs.rating ?? 0.0
            return lhsRating > rhsRating
        }
    }
    
    /// 営業時間でフィルタリング
    func filterOpenPlaces(_ places: [Place]) -> [Place] {
        return places.filter { place in
            place.isOpen ?? true // 不明な場合は含める
        }
    }
}

// MARK: - Batch Operations

extension PlaceRepositoryImpl {
    
    /// 複数のスポット名を並列で検索
    func searchPlaces(
        names: [String],
        near location: CLLocationCoordinate2D
    ) async throws -> [Place] {
        return try await withThrowingTaskGroup(of: Place?.self) { group in
            for name in names {
                group.addTask {
                    try await self.searchPlace(name: name, near: location)
                }
            }
            
            var places: [Place] = []
            for try await place in group {
                if let place = place {
                    places.append(place)
                }
            }
            return places
        }
    }
    
    /// スポットの実在性を並列で検証
    func validatePlaces(
        names: [String],
        near location: CLLocationCoordinate2D
    ) async throws -> [String: Bool] {
        return try await withThrowingTaskGroup(of: (String, Bool).self) { group in
            for name in names {
                group.addTask {
                    let isValid = try await self.validatePlace(name: name, location: location)
                    return (name, isValid)
                }
            }
            
            var results: [String: Bool] = [:]
            for try await (name, isValid) in group {
                results[name] = isValid
            }
            return results
        }
    }
}

// MARK: - Caching Support

extension PlaceRepositoryImpl {
    
    /// キャッシュキーの生成
    func generateCacheKey(for request: String, location: CLLocationCoordinate2D) -> String {
        let locationString = String(format: "%.4f,%.4f", location.latitude, location.longitude)
        return "\(request)_\(locationString)"
    }
    
    /// 検索結果の有効期限チェック
    func isCacheValid(timestamp: Date, maxAge: TimeInterval = 3600) -> Bool { // 1時間
        return Date().timeIntervalSince(timestamp) < maxAge
    }
}