import Foundation
import CoreLocation

struct NavigationRoute {
    let id: UUID
    let origin: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let waypoint: Place
    let transportMode: TransportMode
    let totalDistance: CLLocationDistance
    let estimatedDuration: TimeInterval
    let polyline: String
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        waypoint: Place,
        transportMode: TransportMode,
        totalDistance: CLLocationDistance = 0,
        estimatedDuration: TimeInterval = 0,
        polyline: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.origin = origin
        self.destination = destination
        self.waypoint = waypoint
        self.transportMode = transportMode
        self.totalDistance = totalDistance
        self.estimatedDuration = estimatedDuration
        self.polyline = polyline
        self.createdAt = createdAt
    }
}

// MARK: - Equatable
extension NavigationRoute: Equatable {
    static func == (lhs: NavigationRoute, rhs: NavigationRoute) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension NavigationRoute: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Computed Properties
extension NavigationRoute {
    var formattedDistance: String {
        if totalDistance < 1000 {
            return String(format: "%.0fm", totalDistance)
        } else {
            return String(format: "%.1fkm", totalDistance / 1000)
        }
    }
    
    var formattedDuration: String {
        let hours = Int(estimatedDuration) / 3600
        let minutes = Int(estimatedDuration.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return String(format: "%d時間%d分", hours, minutes)
        } else {
            return String(format: "%d分", minutes)
        }
    }
    
    var summaryText: String {
        return "\(waypoint.name)経由で\(formattedDistance)・\(formattedDuration)"
    }
}

// MARK: - Google Maps Integration
extension NavigationRoute {
    var googleMapsURL: URL? {
        // Google Mapsアプリで経路案内を開始するURL
        // 経由地を含む場合は daddr に "経由地+to:最終目的地" の形式で指定
        let waypointQuery: String = {
            if let masked = maskedWaypointQuery() {
                return masked
            } else {
                let c = offsetCoordinate(waypoint.coordinate, meters: 60)
                return "\(c.latitude),\(c.longitude)"
            }
        }()
        let destinationQuery = "\(destination.latitude),\(destination.longitude)"
        let combinedDestination = "\(waypointQuery)+to:\(destinationQuery)"
        
        var components = URLComponents(string: "comgooglemaps://")
        components?.queryItems = [
            URLQueryItem(name: "saddr", value: "\(origin.latitude),\(origin.longitude)"),
            URLQueryItem(name: "daddr", value: combinedDestination),
            URLQueryItem(name: "directionsmode", value: transportMode.googleMapsMode)
        ]
        
        return components?.url
    }
    
    var appleMapsURL: URL? {
        // Apple Mapsアプリでの経路案内URL（フォールバック用）
        // 経由地を含む場合は daddr に "経由地+to:最終目的地" の形式で指定
        let waypointQuery: String = {
            if let masked = maskedWaypointQuery() {
                return masked
            } else {
                let c = offsetCoordinate(waypoint.coordinate, meters: 60)
                return "\(c.latitude),\(c.longitude)"
            }
        }()
        let destinationQuery = "\(destination.latitude),\(destination.longitude)"
        let combinedDestination = "\(waypointQuery)+to:\(destinationQuery)"
        
        var components = URLComponents(string: "http://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "saddr", value: "\(origin.latitude),\(origin.longitude)"),
            URLQueryItem(name: "daddr", value: combinedDestination),
            URLQueryItem(name: "dirflg", value: transportMode.appleMapsMode)
        ]
        
        return components?.url
    }
}

// MARK: - Masking helpers
extension NavigationRoute {
    // 郵便番号などで行き先名の露出を避ける
    fileprivate func maskedWaypointQuery() -> String? {
        let addr = waypoint.address
        if addr.isEmpty { return nil }
        if let m = addr.range(of: "〒\\d{3}-\\d{4}", options: .regularExpression) {
            return String(addr[m])
        }
        if let m = addr.range(of: "\\b\\d{3}-\\d{4}\\b", options: .regularExpression) {
            return String(addr[m])
        }
        // 都道府県+市区まで
        if let prefRange = addr.range(of: "(..都|..道|..府|....県)", options: .regularExpression) {
            let tail = addr[prefRange.lowerBound...]
            if let wardEnd = tail.range(of: "区")?.upperBound {
                return String(tail[..<wardEnd])
            }
            if let cityEnd = tail.range(of: "市")?.upperBound {
                return String(tail[..<cityEnd])
            }
            return String(tail)
        }
        return nil
    }

    // 指定メートルだけ座標をオフセット（POI名の自動ラベルを避ける）
    fileprivate func offsetCoordinate(_ coord: CLLocationCoordinate2D, meters: Double) -> CLLocationCoordinate2D {
        let bearing = Double.random(in: 0..<(2 * .pi))
        let dx = meters * cos(bearing)
        let dy = meters * sin(bearing)
        let metersPerLat = 111_132.0
        let metersPerLon = cos(coord.latitude * .pi / 180.0) * 111_320.0
        let dLat = dy / metersPerLat
        let dLon = dx / metersPerLon
        return CLLocationCoordinate2D(latitude: coord.latitude + dLat, longitude: coord.longitude + dLon)
    }
}

// MARK: - Apple Maps Mode Extension
extension TransportMode {
    var appleMapsMode: String {
        switch self {
        case .walking: return "w"
        case .driving: return "d"
        case .transit: return "r"
        case .cycling: return "w" // Apple Mapsは自転車モードがないため徒歩で代用
        }
    }
}