import Foundation

protocol CacheRepository {
    func savePlacesForGenres(places: [Place], genres: [Genre]) async
    func getPlaceForGenre(genre: Genre) async -> Place?
    func saveExcludedPlaceIds(_ placeIds: [String]) async
    func getExcludedPlaceIds() async -> [String]
    func addExcludedPlaceId(_ placeId: String) async
    func clearCache() async
    func clearExcludedPlaces() async
}

enum CacheError: LocalizedError {
    case saveFailed
    case loadFailed
    case corruptedData
    case encryptionFailed
    case decryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "データの保存に失敗しました"
        case .loadFailed:
            return "データの読み込みに失敗しました"
        case .corruptedData:
            return "キャッシュデータが破損しています"
        case .encryptionFailed:
            return "データの暗号化に失敗しました"
        case .decryptionFailed:
            return "データの復号化に失敗しました"
        }
    }
}