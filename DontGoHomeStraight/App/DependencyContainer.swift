//
//  DependencyContainer.swift
//  DontGoHomeStraight
//
//  Created by kazunori.sakata.ts on 2025/08/05.
//

import Foundation

// MARK: - Dependency Container

class DependencyContainer {
    static let shared = DependencyContainer()
    
    // MARK: - API Clients
    private lazy var openAIAPIClient: OpenAIAPIClient = {
        let apiKey = Environment.openAIAPIKey
        #if DEBUG
        print("🔑 OpenAI API Key loaded: \(String(apiKey.prefix(10)))...")
        #endif
        return OpenAIAPIClient(apiKey: apiKey)
    }()
    
    private lazy var googlePlacesAPIClient: GooglePlacesAPIClient = {
        let apiKey = Environment.googlePlacesAPIKey
        #if DEBUG
        print("🔑 Google Places API Key loaded: \(String(apiKey.prefix(10)))...")
        #endif
        return GooglePlacesAPIClient(apiKey: apiKey)
    }()
    
    // MARK: - Repositories
    private lazy var aiRepository: AIRecommendationRepository = {
        return AIRecommendationRepositoryImpl(apiClient: openAIAPIClient)
    }()
    
    private lazy var placeRepository: PlaceRepository = {
        return PlaceRepositoryImpl(apiClient: googlePlacesAPIClient)
    }()
    
    private lazy var cacheRepository: CacheRepository = {
        return CacheRepositoryImpl()
    }()
    
    private lazy var locationRepository: LocationRepository = {
        return LocationRepositoryImpl()
    }()
    
    // MARK: - Use Cases
    private lazy var placeRecommendationUseCase: PlaceRecommendationUseCase = {
        return PlaceRecommendationUseCaseImpl(
            aiRepository: aiRepository,
            placeRepository: placeRepository,
            cacheRepository: cacheRepository
        )
    }()
    
    private lazy var navigationUseCase: NavigationUseCase = {
        return NavigationUseCaseImpl(
            cacheRepository: cacheRepository,
            locationRepository: locationRepository
        )
    }()
    
    private init() {
        validateAPIKeys()
    }
    
    // MARK: - Public Access Methods
    
    func getPlaceRecommendationUseCase() -> PlaceRecommendationUseCase {
        return placeRecommendationUseCase
    }
    
    func getNavigationUseCase() -> NavigationUseCase {
        return navigationUseCase
    }
    
    func getLocationRepository() -> LocationRepository {
        return locationRepository
    }
    
    func getCacheRepository() -> CacheRepository {
        return cacheRepository
    }
    
    // MARK: - Private Methods
    
    // MARK: - View Models
    
    @MainActor
    lazy var appViewModel: AppViewModel = {
        return AppViewModel(
            placeRecommendationUseCase: placeRecommendationUseCase,
            navigationUseCase: navigationUseCase,
            locationRepository: locationRepository
        )
    }()
    
    private func validateAPIKeys() {
        #if DEBUG
        let openAIKey = Environment.openAIAPIKey
        let googleKey = Environment.googlePlacesAPIKey
        
        print("🔧 API Key Validation:")
        print("  - OpenAI: \(openAIKey.isEmpty ? "❌ Empty" : "✅ Set")")
        print("  - Google Places: \(googleKey.isEmpty ? "❌ Empty" : "✅ Set")")
        
        if openAIKey.hasPrefix("sk-dev-") || googleKey.hasPrefix("dev-") {
            print("⚠️ 開発用のダミーAPIキーが使用されています")
        }
        #else
        // 本番環境では実際のキーが設定されているかチェック
        if Environment.openAIAPIKey.isEmpty || Environment.googlePlacesAPIKey.isEmpty {
            fatalError("本番環境では有効なAPIキーが必要です。Config.plistを確認してください。")
        }
        #endif
    }
}

