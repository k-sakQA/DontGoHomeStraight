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
        let minutes = Int(estimatedDuration % 3600) / 60
        
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
        let waypointQuery = "\(waypoint.coordinate.latitude),\(waypoint.coordinate.longitude)"
        let destinationQuery = "\(destination.latitude),\(destination.longitude)"
        
        var components = URLComponents(string: "comgooglemaps://")
        components?.queryItems = [
            URLQueryItem(name: "saddr", value: "\(origin.latitude),\(origin.longitude)"),
            URLQueryItem(name: "daddr", value: destinationQuery),
            URLQueryItem(name: "waypoints", value: waypointQuery),
            URLQueryItem(name: "directionsmode", value: transportMode.googleMapsMode)
        ]
        
        return components?.url
    }
    
    var appleMapsURL: URL? {
        // Apple Mapsアプリでの経路案内URL（フォールバック用）
        let waypointQuery = "\(waypoint.coordinate.latitude),\(waypoint.coordinate.longitude)"
        let destinationQuery = "\(destination.latitude),\(destination.longitude)"
        
        var components = URLComponents(string: "http://maps.apple.com/")
        components?.queryItems = [
            URLQueryItem(name: "saddr", value: "\(origin.latitude),\(origin.longitude)"),
            URLQueryItem(name: "daddr", value: destinationQuery),
            URLQueryItem(name: "dirflg", value: transportMode.appleMapsMode)
        ]
        
        return components?.url
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