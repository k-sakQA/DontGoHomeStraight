import XCTest
import CoreLocation
@testable import DontGoHomeStraight

final class SystemWaypointSuggestionUseCaseTests: XCTestCase {
    // Stubs
    struct DMStub: DistanceMatrixClient {
        let toDurations: [TimeInterval]
        let toDestDurations: [TimeInterval]
        let baseline: TimeInterval
        func getDurationsSeconds(origin: CLLocationCoordinate2D, destinations: [CLLocationCoordinate2D], mode: TransportMode) async throws -> [TimeInterval] {
            if destinations.count == 1 { return [baseline] }
            if origin.latitude == 0 { return toDurations } // arbitrary branch
            return toDestDurations
        }
    }
    
    final class PlaceRepoStub: PlaceRepository {
        var placesByCall: [[Place]] = []
        var callIndex = 0
        func searchPlace(name: String, near location: CLLocationCoordinate2D) async throws -> Place? { nil }
        func searchPlaces(location: CLLocationCoordinate2D, type: String, radius: Int) async throws -> [Place] {
            defer { callIndex += 1 }
            return placesByCall.indices.contains(callIndex) ? placesByCall[callIndex] : []
        }
        func getNearbyPlaces(location: CLLocationCoordinate2D, radius: Int) async throws -> [Place] { [] }
        func getPlaceDetails(placeId: String) async throws -> Place? { nil }
        func validatePlace(name: String, location: CLLocationCoordinate2D) async throws -> Bool { true }
        func searchPlaces(names: [String], near location: CLLocationCoordinate2D) async throws -> [Place] { [] }
    }
    
    struct CacheStub: CacheRepository {
        func savePlacesForGenres(places: [Place], genres: [Genre]) async {}
        func getPlaceForGenre(genre: Genre) async -> Place? { nil }
        func getExcludedPlaceIds() async -> [String] { [] }
        func saveExcludedPlaceIds(_ placeIds: [String]) async {}
        func addExcludedPlaceId(_ placeId: String) async {}
        func clearExcludedPlaces() async {}
        func clearCache() async {}
    }
    
    private func makePlace(id: String, type: String, rating: Double, reviews: Int) -> Place {
        return Place(
            name: id,
            coordinate: CLLocationCoordinate2D(latitude: 35, longitude: 139),
            address: "",
            genre: Genre(name: id, category: ["restaurant","cafe","bar","bakery","meal_takeaway"].contains(type) ? .restaurant : .other, googleMapType: type),
            rating: rating,
            priceLevel: nil,
            photoReference: nil,
            isOpen: true,
            placeId: id,
            vicinity: nil,
            userRatingsTotal: reviews
        )
    }
    
    func testBoundary30Minutes() async throws {
        let p1 = makePlace(id: "p1", type: "park", rating: 4.0, reviews: 10)
        let repo = PlaceRepoStub()
        repo.placesByCall = [[p1]]
        let dm = DMStub(toDurations: [600], toDestDurations: [1200], baseline: 1800) // add = 10+20 -30 = 0 min
        let usecase = SystemWaypointSuggestionUseCase(placeRepository: repo, distanceMatrixClient: dm, cacheRepository: CacheStub())
        let genres = try await usecase.getRecommendations(currentLocation: CLLocationCoordinate2D(latitude: 0, longitude: 0), destination: CLLocationCoordinate2D(latitude: 1, longitude: 1), mood: Mood(activityType: .outdoor, vibeType: .discovery), transportMode: .walking, now: Date(timeIntervalSince1970: 0), seed: "s")
        XCTAssertEqual(genres.count, 1)
    }
    
    func testBoundaryOver30MinutesExcluded() async throws {
        let p1 = makePlace(id: "p1", type: "park", rating: 4.0, reviews: 10)
        let repo = PlaceRepoStub()
        repo.placesByCall = [[p1]]
        let dm = DMStub(toDurations: [1200], toDestDurations: [1200], baseline: 1800) // add = 20+20-30=10min
        var cfg = WaypointSuggestionConfig()
        cfg.maxAdditionalMinutes = 5
        let usecase = SystemWaypointSuggestionUseCase(placeRepository: repo, distanceMatrixClient: dm, cacheRepository: CacheStub(), config: cfg)
        let genres = try await usecase.getRecommendations(currentLocation: CLLocationCoordinate2D(latitude: 0, longitude: 0), destination: CLLocationCoordinate2D(latitude: 1, longitude: 1), mood: Mood(activityType: .outdoor, vibeType: .discovery), transportMode: .walking, now: Date(timeIntervalSince1970: 0), seed: "s")
        XCTAssertEqual(genres.count, 0)
    }
    
    func testCategoryDistribution() async throws {
        // 2 others + 1 restaurant expected
        let pR = makePlace(id: "r", type: "restaurant", rating: 4.0, reviews: 10)
        let pO1 = makePlace(id: "o1", type: "park", rating: 4.5, reviews: 50)
        let pO2 = makePlace(id: "o2", type: "museum", rating: 4.2, reviews: 12)
        let repo = PlaceRepoStub(); repo.placesByCall = [[pR, pO1, pO2]]
        let dm = DMStub(toDurations: [600, 600, 600], toDestDurations: [600, 600, 600], baseline: 1200)
        let usecase = SystemWaypointSuggestionUseCase(placeRepository: repo, distanceMatrixClient: dm, cacheRepository: CacheStub())
        let genres = try await usecase.getRecommendations(currentLocation: CLLocationCoordinate2D(latitude: 0, longitude: 0), destination: CLLocationCoordinate2D(latitude: 1, longitude: 1), mood: Mood(activityType: .outdoor, vibeType: .discovery), transportMode: .walking, now: Date(timeIntervalSince1970: 0), seed: "s")
        XCTAssertEqual(genres.count, 3)
        XCTAssertEqual(genres.filter { $0.category == .restaurant }.count, 1)
        XCTAssertEqual(genres.filter { $0.category == .other }.count, 2)
    }
    
    func testSeedReproducibility() async throws {
        let p1 = makePlace(id: "p1", type: "park", rating: 4.0, reviews: 10)
        let p2 = makePlace(id: "p2", type: "museum", rating: 4.1, reviews: 20)
        let p3 = makePlace(id: "p3", type: "restaurant", rating: 4.5, reviews: 30)
        let repo = PlaceRepoStub(); repo.placesByCall = [[p1, p2, p3]]
        let dm = DMStub(toDurations: [600,600,600], toDestDurations: [600,600,600], baseline: 1100)
        let usecase = SystemWaypointSuggestionUseCase(placeRepository: repo, distanceMatrixClient: dm, cacheRepository: CacheStub())
        let now = Date(timeIntervalSince1970: 1733961600) // fixed
        let g1 = try await usecase.getRecommendations(currentLocation: CLLocationCoordinate2D(latitude: 0, longitude: 0), destination: CLLocationCoordinate2D(latitude: 1, longitude: 1), mood: Mood(activityType: .outdoor, vibeType: .discovery), transportMode: .walking, now: now, seed: "seedA")
        let g2 = try await usecase.getRecommendations(currentLocation: CLLocationCoordinate2D(latitude: 0, longitude: 0), destination: CLLocationCoordinate2D(latitude: 1, longitude: 1), mood: Mood(activityType: .outdoor, vibeType: .discovery), transportMode: .walking, now: now, seed: "seedA")
        XCTAssertEqual(g1.map { $0.name }, g2.map { $0.name })
    }
    
    func testZeroResultFallback() async throws {
        let repo = PlaceRepoStub(); repo.placesByCall = [[], []]
        let dm = DMStub(toDurations: [], toDestDurations: [], baseline: 1000)
        let usecase = SystemWaypointSuggestionUseCase(placeRepository: repo, distanceMatrixClient: dm, cacheRepository: CacheStub())
        let genres = try await usecase.getRecommendations(currentLocation: CLLocationCoordinate2D(latitude: 0, longitude: 0), destination: CLLocationCoordinate2D(latitude: 1, longitude: 1), mood: Mood(activityType: .outdoor, vibeType: .discovery), transportMode: .walking, now: Date(), seed: nil)
        XCTAssertEqual(genres.count, 0)
    }
}