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
    
    func toPrompt() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        
        return """
        現在地: \(currentLocation.latitude), \(currentLocation.longitude)
        目的地: \(destination.latitude), \(destination.longitude)
        現在時刻: \(formatter.string(from: currentTime))
        気分: \(mood.description)
        移動手段: \(transportMode.displayName)
        除外スポット: \(excludedPlaceIds.joined(separator: ", "))
        
        上記の条件で、経由地として最適な3つのスポットを提案してください。
        飲食店を30%、それ以外を70%の割合で含めてください。
        各スポットについて、Google Places APIで検索可能な具体的な店名または施設名を回答してください。
        """
    }
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