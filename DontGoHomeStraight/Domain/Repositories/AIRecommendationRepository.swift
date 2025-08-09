import Foundation
import CoreLocation

protocol AIRecommendationRepository {
    func getRecommendations(request: AIRecommendationRequest) async throws -> [LLMCandidate]
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
        除外スポット(place_id): \(excludedPlaceIds.joined(separator: ", "))
        
        上記の条件で候補スポットを10件提案してください。各候補は以下のフィールドを含めてください。
        - name: Googleで実在する具体的名称
        - category: "restaurant" または "other"
        
        回答は厳密にJSON配列で返してください（説明文は不要）。
        """
    }
}

struct LLMCandidate: Codable, Equatable {
    let name: String
    let category: GenreCategory
}

// Codable bridge for GenreCategory in LLMCandidate
extension LLMCandidate {
    private enum CodingKeys: String, CodingKey { case name, category }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        let categoryRaw = try container.decode(String.self, forKey: .category)
        self.category = GenreCategory(rawValue: categoryRaw) ?? .other
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(category.rawValue, forKey: .category)
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