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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        
        return """
        現在地: \(currentLocation.latitude), \(currentLocation.longitude)
        目的地: \(destination.latitude), \(destination.longitude)
        現在時刻: \(dateFormatter.string(from: currentTime))
        気分: \(mood.description)
        移動手段: \(transportMode.displayName)
        除外スポット: \(excludedPlaceIds.joined(separator: ", "))
        
        上記の条件で、経由地として最適な3つのスポットを提案してください。
        飲食店を30%、それ以外を70%の割合で含めてください。
        各スポットについて、GooglePlaces APIで検索可能な具体的な店名または施設名を回答してください。
        
        回答は以下のJSON形式で提供してください：
        [
          {
            "name": "具体的なスポット名",
            "category": "restaurant" または "other",
            "reason": "推薦理由"
          }
        ]
        """
    }
}

struct AIRecommendationResponse: Codable {
    let name: String
    let category: String
    let reason: String
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