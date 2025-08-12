import Foundation
import CoreLocation
#if canImport(CryptoKit)
import CryptoKit
#endif

protocol DistanceMatrixClient {
    func getDurationsSeconds(
        origin: CLLocationCoordinate2D,
        destinations: [CLLocationCoordinate2D],
        mode: TransportMode
    ) async throws -> [TimeInterval]
}

struct WaypointSuggestionConfig {
    var maxAdditionalMinutes: Double = 30.0
    var minRating: Double = 3.4
    var minReviews: Int = 5
    var baseCorridorRadiusMeters: Int = 600
    var fallbackCorridorRadiusIncrementMeters: Int = 200
    var resultCount: Int = 3
}

final class SystemWaypointSuggestionUseCase {
    private let placeRepository: PlaceRepository
    private let distanceMatrixClient: DistanceMatrixClient
    private let cacheRepository: CacheRepository
    private let config: WaypointSuggestionConfig
    
    init(
        placeRepository: PlaceRepository,
        distanceMatrixClient: DistanceMatrixClient,
        cacheRepository: CacheRepository,
        config: WaypointSuggestionConfig = WaypointSuggestionConfig()
    ) {
        self.placeRepository = placeRepository
        self.distanceMatrixClient = distanceMatrixClient
        self.cacheRepository = cacheRepository
        self.config = config
    }
    
    func getRecommendations(
        currentLocation: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mood: Mood,
        transportMode: TransportMode,
        now: Date = Date(),
        seed: String? = nil
    ) async throws -> [Genre] {
        // Baseline duration T0
        let baseline = try await distanceMatrixClient.getDurationsSeconds(
            origin: currentLocation,
            destinations: [destination],
            mode: transportMode
        ).first ?? .infinity
        if !baseline.isFinite { return [] }
        
        // Search once, then fallback with wider radius if zero eligible
        for attempt in 0...1 {
            let radius = config.baseCorridorRadiusMeters + attempt * config.fallbackCorridorRadiusIncrementMeters
            let candidates = try await fetchCorridorCandidates(
                current: currentLocation,
                destination: destination,
                mood: mood,
                radiusMeters: radius
            )
            let filtered = try await applyTimeAndQualityFilters(
                candidates: candidates,
                current: currentLocation,
                destination: destination,
                baselineSec: baseline,
                mode: transportMode
            )
            let picked = pickDeterministicTop(filtered: filtered, seedInput: seedInput(now: now, seed: seed))
            if picked.isEmpty == false {
                #if DEBUG
                print("🎯 Picked spots (\(picked.count)):")
                for sc in picked {
                    let mins = Int(round(sc.timeToSpotMinutes))
                    print("  • \(sc.place.name) [\(sc.place.genre.googleMapType)] ~ \(mins) min")
                }
                #endif
                let genres = mapToGenres(picked)
                // Save mapping and exclude IDs (deterministic set)
                await cacheRepository.savePlacesForGenres(places: picked.map { $0.place }, genres: genres)
                for sp in picked { await cacheRepository.addExcludedPlaceId(sp.place.placeId) }
                return genres
            }
        }
        return []
    }
    
    private func fetchCorridorCandidates(
        current: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mood: Mood,
        radiusMeters: Int
    ) async throws -> [Place] {
        // Sample along straight-line corridor
        let points = corridorSamplePoints(origin: current, destination: destination)
        let types = typesForMood(mood)
        var aggregated: [Place] = []
        for p in points {
            for type in types {
                let places = try await placeRepository.searchPlaces(location: p, type: type, radius: radiusMeters)
                aggregated.append(contentsOf: places)
            }
        }
        // Deduplicate by placeId
        var seen = Set<String>()
        var unique: [Place] = []
        for pl in aggregated {
            if seen.insert(pl.placeId).inserted { unique.append(pl) }
        }
        return unique
    }
    
    private func corridorSamplePoints(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        // Three points: origin-weighted, midpoint, destination-weighted
        func interp(_ t: Double) -> CLLocationCoordinate2D {
            return CLLocationCoordinate2D(
                latitude: origin.latitude + (destination.latitude - origin.latitude) * t,
                longitude: origin.longitude + (destination.longitude - origin.longitude) * t
            )
        }
        return [0.25, 0.5, 0.75].map { interp($0) }
    }
    
    private func typesForMood(_ mood: Mood) -> [String] {
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
    
    private struct ScoredCandidate: Hashable {
        let place: Place
        let additionalMinutes: Double
        let timeToSpotMinutes: Double
        let category: GenreCategory
        let score: Double
        let reviews: Int
    }
    
    private func applyTimeAndQualityFilters(
        candidates: [Place],
        current: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        baselineSec: TimeInterval,
        mode: TransportMode
    ) async throws -> [ScoredCandidate] {
        guard candidates.isEmpty == false else { return [] }
        let coords = candidates.map { $0.coordinate }
        async let toP = distanceMatrixClient.getDurationsSeconds(origin: current, destinations: coords, mode: mode)
        async let pToD = distanceMatrixClient.getDurationsSeconds(origin: destination, destinations: coords, mode: mode) // compute as D->P equal to P->D
        let (dur1, dur2) = try await (toP, pToD)
        var out: [ScoredCandidate] = []
        for (idx, place) in candidates.enumerated() {
            guard idx < dur1.count, idx < dur2.count else { continue }
            let d1 = dur1[idx]
            let d2 = dur2[idx]
            guard d1.isFinite, d2.isFinite else { continue }
            let totalViaP = d1 + d2
            let addSec = totalViaP - baselineSec
            let addMin = addSec / 60.0
            guard addMin <= config.maxAdditionalMinutes + 1e-6 else { continue }
            let ratingOK = (place.rating ?? 0) >= config.minRating
            let reviewsOK = (place.userRatingsTotal ?? 0) >= config.minReviews
            guard ratingOK && reviewsOK else { continue }
            let category = place.genre.category
            // Simple score: higher rating, more reviews, shorter additional time
            let score = (place.rating ?? 0) * 1.0 + log(Double((place.userRatingsTotal ?? 0) + 1)) * 0.3 - addMin * 0.2
            let toSpotMin = d1 / 60.0
            out.append(ScoredCandidate(place: place, additionalMinutes: addMin, timeToSpotMinutes: toSpotMin, category: category, score: score, reviews: place.userRatingsTotal ?? 0))
        }
        return out
    }
    
    private func pickDeterministicTop(filtered: [ScoredCandidate], seedInput: String) -> [ScoredCandidate] {
        guard filtered.isEmpty == false else { return [] }
        // Stratify by category
        let restaurants = filtered.filter { $0.category == .restaurant }
        let others = filtered.filter { $0.category == .other }
        let pickRestaurant = min(1, restaurants.count)
        let pickOthers = min(2, others.count)
        
        func deterministicOrder(_ items: [ScoredCandidate], salt: String) -> [ScoredCandidate] {
            return items.sorted { a, b in
                let ha = deterministicScore(id: a.place.placeId, salt: salt) + a.score
                let hb = deterministicScore(id: b.place.placeId, salt: salt) + b.score
                return ha > hb
            }
        }
        
        let orderedR = deterministicOrder(restaurants, salt: seedInput + "R")
        let orderedO = deterministicOrder(others, salt: seedInput + "O")
        var picked: [ScoredCandidate] = []
        picked.append(contentsOf: orderedR.prefix(pickRestaurant))
        picked.append(contentsOf: orderedO.prefix(pickOthers))
        if picked.count < 3 {
            // Fill remaining from the rest deterministically
            let remaining = deterministicOrder(filtered, salt: seedInput + "A").filter { sc in
                picked.contains(where: { $0.place.placeId == sc.place.placeId }) == false
            }
            picked.append(contentsOf: remaining.prefix(3 - picked.count))
        }
        return Array(picked.prefix(3))
    }
    
    private func mapToGenres(_ picked: [ScoredCandidate]) -> [Genre] {
        return picked.map { sc in
            let base = nameFromType(sc.place.genre.googleMapType, category: sc.category)
            let minutes = Int(round(sc.timeToSpotMinutes))
            let display = "\(base) (\(minutes)分)"
            return Genre(
                name: display,
                category: sc.category,
                googleMapType: sc.place.genre.googleMapType
            )
        }
    }
    
    private func nameFromType(_ type: String, category: GenreCategory) -> String {
        switch type {
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
    
    private func seedInput(now: Date, seed: String?) -> String {
        let day = ISO8601DateFormatter()
        day.formatOptions = [.withYear, .withMonth, .withDay]
        let dayStr = day.string(from: now)
        let sec = Int(now.timeIntervalSince1970)
        return "\(dayStr)#\(sec)#\(seed ?? "default")"
    }
    
    private func deterministicScore(id: String, salt: String) -> Double {
        #if canImport(CryptoKit)
        let key = SymmetricKey(data: salt.data(using: .utf8)!)
        let mac = HMAC<SHA256>.authenticationCode(for: Data(id.utf8), using: key)
        let first8 = mac.prefix(8)
        let value = first8.reduce(0) { ($0 << 8) | UInt64($1) }
        return Double(value % 1_000_000) / 1_000_000.0
        #else
        var hasher = Hasher()
        hasher.combine(id)
        hasher.combine(salt)
        let v = hasher.finalize()
        return Double(abs(v % 1_000_000)) / 1_000_000.0
        #endif
    }
}