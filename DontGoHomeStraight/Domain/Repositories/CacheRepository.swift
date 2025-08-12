import Foundation

protocol CacheRepository {
    /// 推薦結果の一時保存（メモリのみ）。永続化はユーザー選択時に行う。
    func savePlacesForGenres(places: [Place], genres: [Genre]) async
    /// ユーザーが選択した行き先のみを永続保存する
    func saveSelectedPlaceForGenre(place: Place, genre: Genre) async
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