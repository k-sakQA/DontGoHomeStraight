import Foundation
import CoreLocation
import Combine
import UIKit

class LocationRepositoryImpl: NSObject, LocationRepository {
    private let locationManager = CLLocationManager()
    private let locationSubject = CurrentValueSubject<CLLocationCoordinate2D?, Never>(nil)
    
    var currentLocation: CLLocationCoordinate2D? {
        return locationSubject.value
    }
    
    var locationPublisher: AnyPublisher<CLLocationCoordinate2D?, Never> {
        return locationSubject.eraseToAnyPublisher()
    }
    
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10m移動したら更新
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // 設定アプリを開くアラートを表示
            showLocationSettingsAlert()
        case .authorizedWhenInUse:
            // 必要に応じてalwaysの許可を要求
            startUpdatingLocation()
        case .authorizedAlways:
            startUpdatingLocation()
        @unknown default:
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func openNavigation(route: NavigationRoute, provider: MapsProvider) async throws {
        switch provider {
        case .google:
            // Google Mapsアプリがインストールされているかチェック
            guard let googleMapsURL = route.googleMapsURL,
                  await UIApplication.shared.canOpenURL(googleMapsURL) else {

                // Google Mapsが利用できない場合は標準搭載のApple Mapsにフォールバック
                if let appleMapsURL = route.appleMapsURL {
                    await UIApplication.shared.open(appleMapsURL)
                    return
                }

                throw LocationError.googleMapsNotInstalled
            }

            // Google Mapsアプリでナビゲーション開始
            await UIApplication.shared.open(googleMapsURL)

        case .apple:
            // ユーザーが明示的にApple Mapsを選択した場合はApple Mapsで開く
            guard let appleMapsURL = route.appleMapsURL else {
                throw LocationError.appleMapsUnavailable
            }
            await UIApplication.shared.open(appleMapsURL)
        }
    }
    
    func checkArrival(at waypoint: Place, threshold: CLLocationDistance) -> Bool {
        guard let currentLocation = currentLocation else {
            return false
        }
        
        let currentCLLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let waypointLocation = CLLocation(latitude: waypoint.coordinate.latitude, longitude: waypoint.coordinate.longitude)
        
        let distance = currentCLLocation.distance(from: waypointLocation)
        return distance <= threshold
    }
    
    private func showLocationSettingsAlert() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                return
            }
            
            let alert = UIAlertController(
                title: "位置情報の許可が必要です",
                message: "「まっすぐ帰りたくない」では現在地の取得に位置情報を使用します。設定アプリで位置情報を許可してください。",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "設定を開く", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })
            
            alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
            
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationRepositoryImpl: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // 精度が低い位置情報は無視
        guard location.horizontalAccuracy < 100 else { return }
        
        let coordinate = location.coordinate
        locationSubject.send(coordinate)
        
        // デバッグログ
        #if DEBUG
        print("📍 位置情報更新: \(coordinate.latitude), \(coordinate.longitude) (精度: \(location.horizontalAccuracy)m)")
        #endif
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        #if DEBUG
        print("❌ 位置情報取得エラー: \(error.localizedDescription)")
        #endif
        
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                // 位置情報の許可が拒否された
                showLocationSettingsAlert()
            case .network:
                // ネットワークエラー
                break
            case .locationUnknown:
                // 位置情報を取得できない
                break
            default:
                break
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        #if DEBUG
        print("📱 位置情報許可状態変更: \(status.description)")
        #endif
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            stopUpdatingLocation()
            locationSubject.send(nil)
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Helper Extensions

extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "未設定"
        case .restricted: return "制限"
        case .denied: return "拒否"
        case .authorizedAlways: return "常に許可"
        case .authorizedWhenInUse: return "使用中のみ許可"
        @unknown default: return "不明"
        }
    }
}

// MARK: - Background Location Support

extension LocationRepositoryImpl {
    
    /// バックグラウンドでの位置情報更新を開始（到着判定用）
    func startSignificantLocationChanges() {
        guard authorizationStatus == .authorizedAlways else {
            return
        }
        
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    /// バックグラウンドでの位置情報更新を停止
    func stopSignificantLocationChanges() {
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    /// 地理的領域の監視を開始（到着判定用）
    func startMonitoringRegion(for waypoint: Place, radius: CLLocationDistance = 100) {
        guard authorizationStatus == .authorizedAlways else {
            return
        }
        
        let region = CLCircularRegion(
            center: waypoint.coordinate,
            radius: radius,
            identifier: waypoint.placeId
        )
        
        region.notifyOnEntry = true
        region.notifyOnExit = false
        
        locationManager.startMonitoring(for: region)
    }
    
    /// 地理的領域の監視を停止
    func stopMonitoringRegion(for waypoint: Place) {
        let regions = locationManager.monitoredRegions.filter {
            $0.identifier == waypoint.placeId
        }
        
        for region in regions {
            locationManager.stopMonitoring(for: region)
        }
    }
}

// MARK: - Region Monitoring Delegate

extension LocationRepositoryImpl {
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        #if DEBUG
        print("🎯 地域に到着: \(region.identifier)")
        #endif
        
        // 到着通知をPostする
        NotificationCenter.default.post(
            name: .didArriveAtWaypoint,
            object: nil,
            userInfo: ["placeId": region.identifier]
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        #if DEBUG
        print("🚶‍♂️ 地域から退出: \(region.identifier)")
        #endif
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        #if DEBUG
        print("❌ 地域監視エラー: \(error.localizedDescription)")
        #endif
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let didArriveAtWaypoint = Notification.Name("didArriveAtWaypoint")
}