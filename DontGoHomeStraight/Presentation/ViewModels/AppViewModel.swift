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

    // 寄り道図鑑
    @Published var visitedSpots: [VisitedSpot] = []

    // 地図アプリ選択（前回選んだものをデフォルトとして記憶する）
    @Published var preferredMapsProvider: MapsProvider = MapsProviderPreference.load()
    @Published var mapsLaunchErrorMessage: String?
    
    // Location
    @Published var locationPermissionStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationAvailable = false
    
    // MARK: - Use Cases
    
    private let placeRecommendationUseCase: PlaceRecommendationUseCase
    private let navigationUseCase: NavigationUseCase
    private let locationRepository: LocationRepository
    private let systemWaypointSuggestionUseCase: SystemWaypointSuggestionUseCase?
    private let visitedSpotRepository: VisitedSpotRepository
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        placeRecommendationUseCase: PlaceRecommendationUseCase,
        navigationUseCase: NavigationUseCase,
        locationRepository: LocationRepository,
        systemWaypointSuggestionUseCase: SystemWaypointSuggestionUseCase? = nil,
        visitedSpotRepository: VisitedSpotRepository = VisitedSpotRepositoryImpl()
    ) {
        self.placeRecommendationUseCase = placeRecommendationUseCase
        self.navigationUseCase = navigationUseCase
        self.locationRepository = locationRepository
        self.systemWaypointSuggestionUseCase = systemWaypointSuggestionUseCase
        self.visitedSpotRepository = visitedSpotRepository
        self.visitedSpots = visitedSpotRepository.getAll()

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

    // MARK: - Collection (寄り道図鑑)

    func navigateToCollection() {
        visitedSpots = visitedSpotRepository.getAll()
        currentScreen = .collection
    }

    func closeCollection() {
        // ホーム画面は画面遷移で入力状態がリセットされるため、旅データも揃えてリセットする
        navigateToHome()
    }

    /// 経由地への到着を確定させる: 図鑑に記録し、Live Activityで種明かしして到着画面へ
    func registerArrival(place: Place) {
        // 到着チェックのタイマーと通知の二重発火を防ぐ
        if currentScreen == .arrival && arrivedPlace?.placeId == place.placeId {
            return
        }

        visitedSpotRepository.record(place: place, mood: selectedMood)
        visitedSpots = visitedSpotRepository.getAll()

        DetourLiveActivityManager.shared.endWithReveal(placeName: place.name)

        arrivedPlace = place
        currentScreen = .arrival
    }

    // MARK: - Live Activity

    func updateDetourLiveActivityDistance(_ meters: Double) {
        DetourLiveActivityManager.shared.updateDistance(meters)
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
        DetourLiveActivityManager.shared.endImmediately()
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
    
    /// 現在の経路を、指定した地図アプリで起動する（経路案内画面のボタンから明示的に呼ばれる）
    func openMaps(provider: MapsProvider) {
        guard let route = currentRoute else { return }

        preferredMapsProvider = provider
        MapsProviderPreference.save(provider)

        Task {
            do {
                try await navigationUseCase.launchNavigation(route: route, provider: provider)
            } catch {
                mapsLaunchErrorMessage = (error as? LocalizedError)?.errorDescription ?? "地図アプリを起動できませんでした"
            }
        }
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
        print("🔍 getRecommendations started:")
        print("  📍 Current: \(currentLocation)")
        print("  🎯 Destination: \(destination.coordinate)")
        print("  😊 Mood: \(mood.description)")
        print("  🚶 Transport: \(transportMode.displayName)")
        print("  🤖 forceAI: \(forceAI)")
        print("  ⚙️ FeatureFlags.detourSystemPicker: \(FeatureFlags.detourSystemPicker)")
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
                #if DEBUG
                print("✅ SystemWaypointSuggestionUseCase completed, got \(genres.count) genres")
                #endif
            } else {
                #if DEBUG
                if forceAI { 
                    print("🧠 Forcing AI recommendation flow") 
                } else {
                    print("🧠 Using AI recommendation flow (default)")
                }
                #endif
                genres = try await placeRecommendationUseCase.getRecommendations(
                    currentLocation: currentLocation,
                    destination: destination.coordinate,
                    mood: mood,
                    transportMode: transportMode
                )
                #if DEBUG
                print("✅ PlaceRecommendationUseCase completed, got \(genres.count) genres")
                #endif
            }
            
            #if DEBUG
            print("📋 Received Genres: \(genres.count) items")
            for (index, genre) in genres.enumerated() {
                print("  \(index + 1). \(genre.name) (\(genre.category))")
            }
            #endif
            
            if genres.isEmpty {
                #if DEBUG
                print("❌ No genres returned - showing empty state with trivia")
                #endif
                // エラーではなく「まっすぐ帰りましょう🎵」+ 豆知識の空状態を表示
                recommendedGenres = []
                currentScreen = .genreSelection
            } else {
                recommendedGenres = genres
                currentScreen = .genreSelection
            }
            
        } catch {
            #if DEBUG
            print("❌ Error in getRecommendations:")
            print("  Error: \(error)")
            print("  Error type: \(type(of: error))")
            if let localizedError = error as? LocalizedError {
                print("  Localized description: \(localizedError.errorDescription ?? "nil")")
            }
            #endif
            handleError(error)
        }
        
        #if DEBUG
        print("🔚 getRecommendations finished, setting isLoading = false")
        #endif
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
            // 経路は作成するが、地図アプリはまだ起動しない（ユーザーが経路案内画面で選ぶ）
            let route = try await navigationUseCase.buildRoute(
                origin: currentLocation,
                destination: destination.coordinate,
                selectedGenre: genre,
                transportMode: transportMode
            )

            currentRoute = route
            currentScreen = .navigation

            // ロック画面・Dynamic Islandにミステリー寄り道を表示
            DetourLiveActivityManager.shared.start(
                genre: genre,
                destinationName: destination.name
            )

        } catch {
            handleError(error)
        }

        isLoading = false
    }
    
    private func handleArrival(placeId: String) async {
        guard let selectedGenre = selectedGenre else { return }

        // キャッシュからスポット情報を取得
        if let place = await navigationUseCase.getWaypointForGenre(selectedGenre) {
            registerArrival(place: place)
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
        return placeRecommendationUseCase.getPhotoURL(photoReference: photoReference, maxWidth: maxWidth)
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
    
    // 複数の候補を検索
    func searchDestinationCandidates(from text: String) async -> [Place] {
        guard let currentLocation = currentLocation else { return [] }
        
        do {
            // 最大5件の候補を取得
            let places = try await placeRecommendationUseCase.searchPlaceCandidates(
                query: text,
                near: currentLocation,
                limit: 5
            )
            return places
        } catch {
            #if DEBUG
            print("❌ searchDestinationCandidates error: \(error)")
            #endif
            return []
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
    case collection

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
        case .collection: return "寄り道図鑑"
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
    
    func searchPlaceCandidates(query: String, near location: CLLocationCoordinate2D, limit: Int) async throws -> [Place] {
        // モック実装：複数の候補を返す
        return (1...min(limit, 3)).map { index in
            Place(
                name: "\(query) 候補\(index)",
                coordinate: location,
                address: "東京都渋谷区 モック住所\(index)",
                genre: Genre(name: "モック", category: .other, googleMapType: "point_of_interest"),
                placeId: "mock-\(query)-\(index)"
            )
        }
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
    func openNavigation(route: NavigationRoute, provider: MapsProvider) async throws {}
    func checkArrival(at waypoint: Place, threshold: CLLocationDistance) -> Bool { return false }
}
#endif