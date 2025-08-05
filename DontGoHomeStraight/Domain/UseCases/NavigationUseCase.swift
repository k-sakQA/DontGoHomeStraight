import Foundation
import CoreLocation

protocol NavigationUseCase {
    func startNavigation(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        selectedGenre: Genre,
        transportMode: TransportMode
    ) async throws -> NavigationRoute
    
    func checkArrival(
        currentLocation: CLLocationCoordinate2D,
        waypoint: Place,
        threshold: CLLocationDistance
    ) -> Bool
    
    func getWaypointForGenre(_ genre: Genre) async -> Place?
}

class NavigationUseCaseImpl: NavigationUseCase {
    private let cacheRepository: CacheRepository
    private let locationRepository: LocationRepository
    
    init(
        cacheRepository: CacheRepository,
        locationRepository: LocationRepository
    ) {
        self.cacheRepository = cacheRepository
        self.locationRepository = locationRepository
    }
    
    func startNavigation(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        selectedGenre: Genre,
        transportMode: TransportMode
    ) async throws -> NavigationRoute {
        // 1. キャッシュから選択されたジャンルに対応するスポットを取得
        guard let waypoint = await cacheRepository.getPlaceForGenre(genre: selectedGenre) else {
            throw NavigationError.waypointNotFound
        }
        
        // 2. ナビゲーション経路を作成
        let route = NavigationRoute(
            origin: origin,
            destination: destination,
            waypoint: waypoint,
            transportMode: transportMode
        )
        
        // 3. Google Maps アプリで経路案内開始
        try await locationRepository.startGoogleMapsNavigation(route: route)
        
        return route
    }
    
    func checkArrival(
        currentLocation: CLLocationCoordinate2D,
        waypoint: Place,
        threshold: CLLocationDistance = 50.0
    ) -> Bool {
        return locationRepository.checkArrival(at: waypoint, threshold: threshold)
    }
    
    func getWaypointForGenre(_ genre: Genre) async -> Place? {
        return await cacheRepository.getPlaceForGenre(genre: genre)
    }
}

enum NavigationError: LocalizedError {
    case waypointNotFound
    case routeCalculationFailed
    case navigationStartFailed
    case invalidDestination
    
    var errorDescription: String? {
        switch self {
        case .waypointNotFound:
            return "選択されたジャンルの経由地が見つかりません"
        case .routeCalculationFailed:
            return "経路の計算に失敗しました"
        case .navigationStartFailed:
            return "ナビゲーションの開始に失敗しました"
        case .invalidDestination:
            return "無効な目的地が指定されました"
        }
    }
}