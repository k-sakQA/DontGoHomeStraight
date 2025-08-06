import Foundation
import CoreLocation

class AIRecommendationRepositoryImpl: AIRecommendationRepository {
    private let openAIClient: OpenAIAPIClient
    
    init(apiClient: OpenAIAPIClient) {
        self.openAIClient = apiClient
    }
    
    func getRecommendations(request: AIRecommendationRequest) async throws -> [String] {
        do {
            let recommendations = try await openAIClient.getRecommendations(request: request)
            
            // 最大3件までに制限
            return Array(recommendations.prefix(3))
            
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

// MARK: - Extensions for AIRecommendationRequest

extension AIRecommendationRequest {
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