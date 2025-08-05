import Foundation
import CoreLocation

/// アプリケーション全体の依存関係を管理するコンテナ
class DependencyContainer {
    static let shared = DependencyContainer()
    
    // MARK: - Repositories
    
    lazy var aiRecommendationRepository: AIRecommendationRepository = {
        return AIRecommendationRepositoryImpl(apiKey: Environment.openAIAPIKey)
    }()
    
    lazy var placeRepository: PlaceRepository = {
        return PlaceRepositoryImpl(apiKey: Environment.googlePlacesAPIKey)
    }()
    
    lazy var locationRepository: LocationRepository = {
        return LocationRepositoryImpl()
    }()
    
    lazy var cacheRepository: CacheRepository = {
        return CacheRepositoryImpl()
    }()
    
    // MARK: - Use Cases
    
    lazy var placeRecommendationUseCase: PlaceRecommendationUseCase = {
        return PlaceRecommendationUseCaseImpl(
            aiRepository: aiRecommendationRepository,
            placeRepository: placeRepository,
            cacheRepository: cacheRepository
        )
    }()
    
    lazy var navigationUseCase: NavigationUseCase = {
        return NavigationUseCaseImpl(
            cacheRepository: cacheRepository,
            locationRepository: locationRepository
        )
    }()
    
    // MARK: - View Models
    
    lazy var appViewModel: AppViewModel = {
        return AppViewModel(
            placeRecommendationUseCase: placeRecommendationUseCase,
            navigationUseCase: navigationUseCase,
            locationRepository: locationRepository
        )
    }()
    
    private init() {}
}

