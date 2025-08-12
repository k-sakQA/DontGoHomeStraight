import Foundation
import CoreLocation

final class DistanceMatrixAdapter: DistanceMatrixClient {
    private let client: GoogleDistanceMatrixClient
    init(apiKey: String) {
        self.client = GoogleDistanceMatrixClient(apiKey: apiKey)
    }
    
    func getDurationsSeconds(origin: CLLocationCoordinate2D, destinations: [CLLocationCoordinate2D], mode: TransportMode) async throws -> [TimeInterval] {
        return try await client.getDurationsSeconds(origin: origin, destinations: destinations, mode: mode)
    }
}