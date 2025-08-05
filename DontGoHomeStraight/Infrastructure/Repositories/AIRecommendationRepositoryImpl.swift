import Foundation
import CoreLocation

class AIRecommendationRepositoryImpl: AIRecommendationRepository {
    private let openAIClient: OpenAIAPIClient
    
    init(apiKey: String) {
        self.openAIClient = OpenAIAPIClient(apiKey: apiKey)
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
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH時mm分"
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        
        let currentTimeString = dateFormatter.string(from: currentTime)
        
        // 移動距離の計算
        let distance = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            .distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude))
        let distanceKm = distance / 1000.0
        
        // 除外スポットの処理
        let excludedText = excludedPlaceIds.isEmpty ? "なし" : excludedPlaceIds.joined(separator: ", ")
        
        return """
        【経由地推薦依頼】
        
        ■基本情報
        現在地: 緯度\(currentLocation.latitude), 経度\(currentLocation.longitude)
        目的地: 緯度\(destination.latitude), 経度\(destination.longitude)
        移動距離: 約\(String(format: "%.1f", distanceKm))km
        現在時刻: \(currentTimeString)
        移動手段: \(transportMode.displayName)
        
        ■ユーザーの気分
        \(mood.description)
        - アクティビティ: \(mood.activityType.displayName) \(mood.activityType.emoji)
        - バイブ: \(mood.vibeType.displayName) \(mood.vibeType.emoji)
        
        ■制約条件
        - 除外スポット: \(excludedText)
        - 飲食店: 30%（1件）
        - その他スポット: 70%（2件）
        - 現在地と目的地の間、または少し迂回した場所
        - 実在する具体的な店名・施設名
        
        上記の条件に基づいて、魅力的な経由地を3つ提案してください。
        ユーザーの気分と移動手段を考慮し、楽しい寄り道体験を提供してください。
        """
    }
}

// MARK: - Helper Extensions

private extension Mood {
    var detailedDescription: String {
        switch (activityType, vibeType) {
        case (.indoor, .jazzy):
            return "落ち着いた室内で、ジャズが似合うような洗練された雰囲気を求めています"
        case (.indoor, .discovery):
            return "室内で新しい発見や学びがある場所を探しています"
        case (.indoor, .exciting):
            return "室内でワクワクするような刺激的な体験を求めています"
        case (.outdoor, .jazzy):
            return "屋外で、ジャズが似合うような洗練された雰囲気の場所を求めています"
        case (.outdoor, .discovery):
            return "屋外で新しい発見や驚きがある場所を探しています"
        case (.outdoor, .exciting):
            return "屋外でワクワクするような活動的な体験を求めています"
        }
    }
}

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