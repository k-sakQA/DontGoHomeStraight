import Foundation
import CoreLocation

protocol PlaceRepository {
    func searchPlace(name: String, near location: CLLocationCoordinate2D) async throws -> Place?
    func searchPlaces(location: CLLocationCoordinate2D, type: String, radius: Int) async throws -> [Place]
    func getNearbyPlaces(location: CLLocationCoordinate2D, radius: Int) async throws -> [Place]
    func getPlaceDetails(placeId: String) async throws -> Place?
    func validatePlace(name: String, location: CLLocationCoordinate2D) async throws -> Bool
    // Batch Text Search by names
    func searchPlaces(names: [String], near location: CLLocationCoordinate2D) async throws -> [Place]
    func getPhotoURL(photoReference: String, maxWidth: Int) -> URL?
    
    // 複数の候補を返すテキスト検索
    func searchPlaceCandidates(query: String, near location: CLLocationCoordinate2D, limit: Int) async throws -> [Place]
}

enum PlaceRepositoryError: LocalizedError {
    case searchFailed
    case invalidPlaceId
    case noResultsFound
    case apiKeyInvalid
    case quotaExceeded
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .searchFailed:
            return "スポット検索に失敗しました"
        case .invalidPlaceId:
            return "無効なスポットIDです"
        case .noResultsFound:
            return "検索結果が見つかりませんでした"
        case .apiKeyInvalid:
            return "Google Places APIキーが無効です"
        case .quotaExceeded:
            return "API利用制限に達しました"
        case .networkError:
            return "ネットワークエラーが発生しました"
        }
    }
}