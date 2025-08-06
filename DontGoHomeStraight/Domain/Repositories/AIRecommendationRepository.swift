import Foundation
import CoreLocation

protocol AIRecommendationRepository {
    func getRecommendations(request: AIRecommendationRequest) async throws -> [String]
    func validateRecommendation(spotName: String, location: CLLocationCoordinate2D) async throws -> Bool
}

struct AIRecommendationRequest {
    let currentLocation: CLLocationCoordinate2D
    let destination: CLLocationCoordinate2D
    let currentTime: Date
    let mood: Mood
    let transportMode: TransportMode
    let excludedPlaceIds: [String]
    

}



enum AIRecommendationError: LocalizedError {
    case noValidPlaces
    case aiServiceUnavailable
    case invalidResponse
    case apiKeyInvalid
    case quotaExceeded
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .noValidPlaces:
            return "候補地がありません。今日はまっすぐ帰りましょう🎵"
        case .aiServiceUnavailable:
            return "AI推薦サービスが一時的に利用できません"
        case .invalidResponse:
            return "AIからの応答が無効です"
        case .apiKeyInvalid:
            return "OpenAI APIキーが無効です"
        case .quotaExceeded:
            return "AI API利用制限に達しました"
        case .networkError:
            return "ネットワークエラーが発生しました"
        }
    }
}