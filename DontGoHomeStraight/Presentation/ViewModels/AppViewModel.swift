import Foundation
import SwiftUI
import Combine
import CoreLocation

@MainActor
class AppViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentScreen: AppScreen = .landing
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Journey Data
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var destination: Destination?
    @Published var selectedTransportMode: TransportMode?
    @Published var selectedMood: Mood?
    @Published var recommendedGenres: [Genre] = []
    @Published var selectedGenre: Genre?
    @Published var currentRoute: NavigationRoute?
    @Published var arrivedPlace: Place?
    
    // Location
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationAvailable = false
    
    // MARK: - Use Cases
    
    private let placeRecommendationUseCase: PlaceRecommendationUseCase
    private let navigationUseCase: NavigationUseCase
    private let locationRepository: LocationRepository
    private let systemWaypointSuggestionUseCase: SystemWaypointSuggestionUseCase?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        placeRecommendationUseCase: PlaceRecommendationUseCase,
        navigationUseCase: NavigationUseCase,
        locationRepository: LocationRepository,
        systemWaypointSuggestionUseCase: SystemWaypointSuggestionUseCase? = nil
    ) {
        self.placeRecommendationUseCase = placeRecommendationUseCase
        self.navigationUseCase = navigationUseCase
        self.locationRepository = locationRepository
        self.systemWaypointSuggestionUseCase = systemWaypointSuggestionUseCase
        
        setupLocationObserver()
        setupArrivalNotification()
    }
    
    // MARK: - Setup
    
    private func setupLocationObserver() {
        // 位置情報の監視
        locationRepository.locationPublisher
            .sink { [weak self] coordinate in
                self?.currentLocation = coordinate
                self?.isLocationAvailable = coordinate != nil
            }
            .store(in: &cancellables)
        
        // 位置情報許可状態の監視
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.locationPermissionStatus = self?.locationRepository.authorizationStatus ?? .notDetermined
            }
            .store(in: &cancellables)
    }
    
    private func setupArrivalNotification() {
        NotificationCenter.default.publisher(for: .didArriveAtWaypoint)
            .sink { [weak self] notification in
                if let placeId = notification.userInfo?["placeId"] as? String {
                    Task {
                        await self?.handleArrival(placeId: placeId)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Navigation Actions
    
    func navigateToDestinationSetting() {
        guard isLocationAvailable else {
            showErrorMessage("現在地を取得してください")
            return
        }
        
        currentScreen = .destinationSetting
    }
    
    func navigateToTransportModeSelection() {
        guard destination != nil else {
            showErrorMessage("目的地を設定してください")
            return
        }
        
        currentScreen = .transportModeSelection
    }
    
    func navigateToMoodSelection() {
        guard selectedTransportMode != nil else {
            showErrorMessage("移動手段を選択してください")
            return
        }
        
        currentScreen = .moodSelection
    }
    
    func navigateToGenreSelection() {
        guard selectedMood != nil else {
            showErrorMessage("気分を選択してください")
            return
        }
        
        Task {
            await getRecommendations()
        }
    }
    
    // AIフローを明示的に選ぶナビゲーション
    func navigateToGenreSelectionAI() {
        guard selectedMood != nil else {
            showErrorMessage("気分を選択してください")
            return
        }
        Task {
            await getRecommendations(forceAI: true)
        }
    }
    
    func navigateToNavigation() {
        guard let selectedGenre = selectedGenre else {
            showErrorMessage("ジャンルを選択してください")
            return
        }
        
        Task {
            await startNavigation(with: selectedGenre)
        }
    }
    
    func navigateToHome() {
        // 状態をリセット
        resetJourneyData()
        currentScreen = .home
    }
    
    func navigateToLanding() {
        // 状態をリセット
        resetJourneyData()
        currentScreen = .landing
    }
    
    // MARK: - Journey Data Management
    
    func setDestination(_ destination: Destination) {
        self.destination = destination
    }
    
    func setTransportMode(_ transportMode: TransportMode) {
        self.selectedTransportMode = transportMode
    }
    
    func setMood(_ mood: Mood) {
        self.selectedMood = mood
    }
    
    func setSelectedGenre(_ genre: Genre) {
        self.selectedGenre = genre
    }
    
    private func resetJourneyData() {
        destination = nil
        selectedTransportMode = nil
        selectedMood = nil
        recommendedGenres = []
        selectedGenre = nil
        currentRoute = nil
        arrivedPlace = nil
    }
    
    // MARK: - Business Logic
    
    func requestLocationPermission() {
        locationRepository.requestLocationPermission()
    }
    
    func startLocationUpdates() {
        locationRepository.startUpdatingLocation()
    }
    
    // MARK: - Cache Management
    
    func clearRecommendationCache() async {
        isLoading = true
        do {
            try await placeRecommendationUseCase.clearCache()
            #if DEBUG
            print("🧹 推薦キャッシュをクリアしました")
            #endif
        } catch {
            errorMessage = "キャッシュのクリアに失敗しました"
            showError = true
        }
        isLoading = false
    }
    
    // MARK: - Navigation Use Case Wrapper Methods
    
    func getWaypointForGenre(_ genre: Genre) async -> Place? {
        return await navigationUseCase.getWaypointForGenre(genre)
    }
    
    func checkArrival(currentLocation: CLLocationCoordinate2D, waypoint: Place, threshold: CLLocationDistance = 50.0) -> Bool {
        return navigationUseCase.checkArrival(currentLocation: currentLocation, waypoint: waypoint, threshold: threshold)
    }
    
    func startNavigationWithRoute(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, selectedGenre: Genre, transportMode: TransportMode) async throws -> NavigationRoute {
        return try await navigationUseCase.startNavigation(origin: origin, destination: destination, selectedGenre: selectedGenre, transportMode: transportMode)
    }
    
    private func getRecommendations(forceAI: Bool = false) async {
        guard let currentLocation = currentLocation,
              let destination = destination,
              let mood = selectedMood,
              let transportMode = selectedTransportMode else {
            showErrorMessage("必要な情報が不足しています")
            return
        }
        
        #if DEBUG
        print("🔍 Recommendations Request:")
        print("  📍 Current: \(currentLocation)")
        print("  🎯 Destination: \(destination.coordinate)")
        print("  😊 Mood: \(mood.description)")
        print("  🚶 Transport: \(transportMode.displayName)")
        #endif
        
        isLoading = true
        
        do {
            let genres: [Genre]
            if forceAI == false, FeatureFlags.detourSystemPicker, let sys = systemWaypointSuggestionUseCase {
                #if DEBUG
                print("🛠️ detour.system_picker=ON: using SystemWaypointSuggestionUseCase")
                #endif
                genres = try await sys.getRecommendations(
                    currentLocation: currentLocation,
                    destination: destination.coordinate,
                    mood: mood,
                    transportMode: transportMode
                )
            } else {
                #if DEBUG
                if forceAI { print("🧠 Forcing AI recommendation flow") }
                #endif
                genres = try await placeRecommendationUseCase.getRecommendations(
                    currentLocation: currentLocation,
                    destination: destination.coordinate,
                    mood: mood,
                    transportMode: transportMode
                )
            }
            
            #if DEBUG
            print("📋 Received Genres: \(genres.count) items")
            for (index, genre) in genres.enumerated() {
                print("  \(index + 1). \(genre.name) (\(genre.category))")
            }
            #endif
            
            if genres.isEmpty {
                #if DEBUG
                print("❌ No genres returned - showing empty message")
                #endif
                showErrorMessage("候補地がありません。今日はまっすぐ帰りましょう🎵")
                navigateToHome()
            } else {
                recommendedGenres = genres
                currentScreen = .genreSelection
            }
            
        } catch {
            #if DEBUG
            print("❌ Error in getRecommendations: \(error)")
            #endif
            handleError(error)
        }
        
        isLoading = false
    }
    
    private func startNavigation(with genre: Genre) async {
        guard let currentLocation = currentLocation,
              let destination = destination,
              let transportMode = selectedTransportMode else {
            showErrorMessage("ナビゲーションの開始に必要な情報が不足しています")
            return
        }
        
        isLoading = true
        
        do {
            // ユーザー選択の行き先を永続保存（ユースケースに委譲）
            await navigationUseCase.persistSelectedWaypoint(for: genre)
            let route = try await navigationUseCase.startNavigation(
                origin: currentLocation,
                destination: destination.coordinate,
                selectedGenre: genre,
                transportMode: transportMode
            )
            
            currentRoute = route
            currentScreen = .navigation
            
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    private func handleArrival(placeId: String) async {
        guard let selectedGenre = selectedGenre else { return }
        
        // キャッシュからスポット情報を取得
        if let place = await navigationUseCase.getWaypointForGenre(selectedGenre) {
            arrivedPlace = place
            currentScreen = .arrival
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        var message = "エラーが発生しました"
        
        if let appError = error as? AIRecommendationError {
            message = appError.localizedDescription
        } else if let locationError = error as? LocationError {
            message = locationError.localizedDescription
        } else if let navigationError = error as? NavigationError {
            message = navigationError.localizedDescription
        } else {
            message = error.localizedDescription
        }
        
        showErrorMessage(message)
    }
    
    func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    func dismissError() {
        showError = false
        errorMessage = nil
    }
    
    // MARK: - Photo URL Generation
    
    func getPhotoURL(photoReference: String, maxWidth: Int = 400) -> URL? {
        return try? placeRecommendationUseCase.getPhotoURL(photoReference: photoReference, maxWidth: maxWidth)
    }

    // MARK: - Place Resolution
    func resolveDestination(from text: String) async -> Place? {
        guard let currentLocation = currentLocation else { return nil }
        do {
            return try await placeRecommendationUseCase.resolvePlace(name: text, near: currentLocation)
        } catch {
            #if DEBUG
            print("❌ resolveDestination error: \(error)")
            #endif
            return nil
        }
    }
}

// MARK: - App Screen Enum

enum AppScreen: CaseIterable {
    case landing
    case home
    case destinationSetting
    case transportModeSelection
    case moodSelection
    case genreSelection
    case navigation
    case arrival
    
    var title: String {
        switch self {
        case .landing: return "まっすぐ帰りたくない"
        case .home: return "設定"
        case .destinationSetting: return "目的地を設定"
        case .transportModeSelection: return "移動手段を選択"
        case .moodSelection: return "今の気分は？"
        case .genreSelection: return "どのジャンルにする？"
        case .navigation: return "経路案内"
        case .arrival: return "到着！"
        }
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension AppViewModel {
    
    static var preview: AppViewModel {
        // プレビュー用のモックインスタンス
        let mockAIRepo = MockAIRecommendationRepository()
        let mockPlaceRepo = MockPlaceRepository()
        let mockCacheRepo = MockCacheRepository()
        let mockLocationRepo = MockLocationRepository()
        
        let placeUseCase = PlaceRecommendationUseCaseImpl(
            aiRepository: mockAIRepo,
            placeRepository: mockPlaceRepo,
            cacheRepository: mockCacheRepo
        )
        
        let navUseCase = NavigationUseCaseImpl(
            cacheRepository: mockCacheRepo,
            locationRepository: mockLocationRepo
        )
        
        return AppViewModel(
            placeRecommendationUseCase: placeUseCase,
            navigationUseCase: navUseCase,
            locationRepository: mockLocationRepo
        )
    }
}

// プレビュー用のモック実装
class MockAIRecommendationRepository: AIRecommendationRepository {
    func getRecommendations(request: AIRecommendationRequest) async throws -> [LLMCandidate] {
        return [
            LLMCandidate(name: "スターバックス渋谷店", category: .restaurant),
            LLMCandidate(name: "代々木公園", category: .other),
            LLMCandidate(name: "明治神宮", category: .other),
            LLMCandidate(name: "タリーズコーヒー 新宿南口店", category: .restaurant),
            LLMCandidate(name: "新宿御苑", category: .other),
            LLMCandidate(name: "TOHOシネマズ新宿", category: .other)
        ]
    }
    
    func validateRecommendation(spotName: String, location: CLLocationCoordinate2D) async throws -> Bool {
        return true
    }
    
    func generateHint(for place: PlaceHintInput) async throws -> String {
        // モック実装：適当なヒントを返す
        switch place.category {
        case .restaurant:
            return "美味しいコーヒーと落ち着いた雰囲気"
        case .other:
            return "緑豊かな都会のオアシス"
        }
    }
}

class MockPlaceRepository: PlaceRepository {
    func searchPlace(name: String, near location: CLLocationCoordinate2D) async throws -> Place? {
        return Place(
            name: name,
            coordinate: location,
            address: "東京都渋谷区",
            genre: Genre(name: "カフェ", category: .restaurant, googleMapType: "cafe"),
            placeId: "mock_place_id"
        )
    }
    
    func searchPlaces(location: CLLocationCoordinate2D, type: String, radius: Int) async throws -> [Place] {
        return []
    }
    
    func getNearbyPlaces(location: CLLocationCoordinate2D, radius: Int) async throws -> [Place] {
        return []
    }
    
    func getPlaceDetails(placeId: String) async throws -> Place? {
        return nil
    }
    
    func validatePlace(name: String, location: CLLocationCoordinate2D) async throws -> Bool {
        return true
    }
    
    func searchPlaces(names: [String], near location: CLLocationCoordinate2D) async throws -> [Place] {
        return names.compactMap { name in
            Place(
                name: name,
                coordinate: location,
                address: "東京都渋谷区",
                genre: Genre(name: "スポット", category: .other, googleMapType: "establishment"),
                placeId: "mock_\(name.hashValue)"
            )
        }
    }
    
    func getPhotoURL(photoReference: String, maxWidth: Int) -> URL? {
        // Mock implementation returns a placeholder image URL
        return URL(string: "https://via.placeholder.com/\(maxWidth)x240")
    }
}

class MockCacheRepository: CacheRepository {
    func savePlacesForGenres(places: [Place], genres: [Genre]) async {}
    func saveSelectedPlaceForGenre(place: Place, genre: Genre) async {}
    func getPlaceForGenre(genre: Genre) async -> Place? { return nil }
    func saveExcludedPlaceIds(_ placeIds: [String]) async {}
    func getExcludedPlaceIds() async -> [String] { return [] }
    func addExcludedPlaceId(_ placeId: String) async {}
    func clearCache() async {}
    func clearExcludedPlaces() async {}
}

class MockLocationRepository: LocationRepository {
    var currentLocation: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)
    var locationPublisher: AnyPublisher<CLLocationCoordinate2D?, Never> = Just(CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)).eraseToAnyPublisher()
    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse
    
    func requestLocationPermission() {}
    func startUpdatingLocation() {}
    func stopUpdatingLocation() {}
    func startGoogleMapsNavigation(route: NavigationRoute) async throws {}
    func checkArrival(at waypoint: Place, threshold: CLLocationDistance) -> Bool { return false }
}
#endif