import Foundation
import CoreLocation

class AIRecommendationRepositoryImpl: AIRecommendationRepository {
    private let openAIClient: OpenAIAPIClient
    
    init(apiClient: OpenAIAPIClient) {
        self.openAIClient = apiClient
    }
    
    func getRecommendations(request: AIRecommendationRequest) async throws -> [LLMCandidate] {
        do {
            let candidates = try await openAIClient.getRecommendations(request: request)
            return candidates
        } catch let error as AIRecommendationError {
            throw error
        } catch {
            throw AIRecommendationError.networkError
        }
    }
    
    func validateRecommendation(spotName: String, location: CLLocationCoordinate2D) async throws -> Bool {
        // スポット名の基本的な妥当性チェック
        let trimmedName = spotName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 空文字やあまりに短い名前は無効
        guard trimmedName.count >= 2 else {
            return false
        }
        
        // 明らかに無効な文字列パターンをチェック
        let invalidPatterns = [
            "未定", "仮", "TBD", "test", "テスト", "サンプル",
            "例", "dummy", "ダミー", "適当", "仮設定"
        ]
        
        let lowercaseName = trimmedName.lowercased()
        for pattern in invalidPatterns {
            if lowercaseName.contains(pattern.lowercased()) {
                return false
            }
        }
        
        // 基本的な日本語スポット名のパターンチェック
        let hasValidCharacters = trimmedName.range(of: "[ひらがなカタカナ漢字a-zA-Z0-9\\-・ー]", options: .regularExpression) != nil
        
        return hasValidCharacters
    }
}



// MARK: - Helper Extensions



private extension TransportMode {
    var suitableSpotTypes: [String] {
        switch self {
        case .walking:
            return ["cafe", "park", "museum", "library", "shopping_mall", "restaurant"]
        case .driving:
            return ["tourist_attraction", "amusement_park", "shopping_mall", "restaurant", "park"]
        case .transit:
            return ["station_nearby", "cafe", "museum", "shopping_mall", "restaurant"]
        case .cycling:
            return ["park", "tourist_attraction", "cafe", "scenic_spot", "restaurant"]
        }
    }
}