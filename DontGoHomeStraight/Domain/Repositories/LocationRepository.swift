import Foundation
import CoreLocation
import Combine

protocol LocationRepository {
    var currentLocation: CLLocationCoordinate2D? { get }
    var locationPublisher: AnyPublisher<CLLocationCoordinate2D?, Never> { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    
    func requestLocationPermission()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    /// 指定した地図アプリで経路案内を開く。ユーザーが明示的に選んだプロバイダで起動する
    func openNavigation(route: NavigationRoute, provider: MapsProvider) async throws
    func checkArrival(at waypoint: Place, threshold: CLLocationDistance) -> Bool
}

enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnavailable
    case googleMapsNotInstalled
    case appleMapsUnavailable
    case navigationFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "位置情報の許可が必要です。設定から許可してください。"
        case .locationUnavailable:
            return "現在地を取得できません。"
        case .googleMapsNotInstalled:
            return "Google Mapsアプリがインストールされていません。"
        case .appleMapsUnavailable:
            return "Apple Mapsを起動できませんでした。"
        case .navigationFailed:
            return "ナビゲーションの開始に失敗しました。"
        }
    }
}