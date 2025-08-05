import Foundation

enum TransportMode: String, CaseIterable {
    case walking = "walking"
    case driving = "driving"
    case transit = "transit"
    case cycling = "cycling"
    
    var displayName: String {
        switch self {
        case .walking: return "徒歩"
        case .driving: return "車"
        case .transit: return "公共交通機関"
        case .cycling: return "自転車"
        }
    }
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .driving: return "car"
        case .transit: return "tram"
        case .cycling: return "bicycle"
        }
    }
    
    var googleMapsMode: String {
        switch self {
        case .walking: return "walking"
        case .driving: return "driving"
        case .transit: return "transit"
        case .cycling: return "bicycling"
        }
    }
}

// MARK: - Codable
extension TransportMode: Codable {}