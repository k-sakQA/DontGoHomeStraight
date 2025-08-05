import Foundation
import CoreLocation

struct Destination {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    let createdAt: Date
    
    init(id: UUID = UUID(), name: String, coordinate: CLLocationCoordinate2D, address: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.address = address
        self.createdAt = createdAt
    }
}

// MARK: - Equatable
extension Destination: Equatable {
    static func == (lhs: Destination, rhs: Destination) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Destination: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}