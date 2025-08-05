import Foundation
import CoreLocation

class OpenAIAPIClient {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let session = URLSession.shared
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func getRecommendations(request: AIRecommendationRequest) async throws -> [String] {
        let openAIRequest = OpenAIRequest(
            model: "gpt-4",
            messages: [
                ChatMessage(role: "system", content: systemPrompt),
                ChatMessage(role: "user", content: request.toPrompt())
            ],
            maxTokens: 1000,
            temperature: 0.7
        )
        
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(openAIRequest)
            urlRequest.httpBody = jsonData
            
            let (data, response) = try await session.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIRecommendationError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                return try parseRecommendations(from: openAIResponse)
                
            case 401:
                throw AIRecommendationError.apiKeyInvalid
                
            case 429:
                throw AIRecommendationError.quotaExceeded
                
            default:
                throw AIRecommendationError.aiServiceUnavailable
            }
            
        } catch let error as AIRecommendationError {
            throw error
        } catch {
            throw AIRecommendationError.networkError
        }
    }
    
    private func parseRecommendations(from response: OpenAIResponse) throws -> [String] {
        guard let choice = response.choices.first,
              let content = choice.message.content else {
            throw AIRecommendationError.invalidResponse
        }
        
        // JSONレスポンスをパース
        do {
            let jsonData = content.data(using: .utf8) ?? Data()
            let recommendations = try JSONDecoder().decode([AIRecommendationResponse].self, from: jsonData)
            return recommendations.map { $0.name }
        } catch {
            // フォールバック: シンプルな文字列解析
            let lines = content.components(separatedBy: .newlines)
            let spotNames = lines.compactMap { line -> String? in
                // "1. スポット名" のような形式を想定
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.contains(".") {
                    let components = trimmed.components(separatedBy: ".")
                    if components.count > 1 {
                        return components[1].trimmingCharacters(in: .whitespaces)
                    }
                }
                return nil
            }
            
            if spotNames.isEmpty {
                throw AIRecommendationError.invalidResponse
            }
            
            return Array(spotNames.prefix(3))
        }
    }
    
    private var systemPrompt: String {
        return """
        あなたは日本の経由地推薦の専門家です。
        ユーザーの現在地から目的地への移動中に立ち寄れる魅力的なスポットを提案してください。
        
        【重要な制約】
        1. 飲食店を30%、それ以外を70%の割合で含めてください
        2. 現在地と目的地の間、または少し迂回した場所にある実在するスポットのみ
        3. 除外リストに含まれるスポットは提案しないでください
        4. ユーザーの気分と移動手段を考慮してください
        5. Google Places APIで検索可能な具体的な店名・施設名で回答してください
        
        【回答形式】
        以下のJSON形式で厳密に回答してください：
        [
          {
            "name": "具体的なスポット名",
            "category": "restaurant",
            "reason": "推薦理由"
          },
          {
            "name": "具体的なスポット名", 
            "category": "other",
            "reason": "推薦理由"
          },
          {
            "name": "具体的なスポット名",
            "category": "other", 
            "reason": "推薦理由"
          }
        ]
        
        ※categoryは"restaurant"または"other"のいずれかにしてください
        ※必ず3つのスポットを提案してください
        ※nameは実在する具体的な店名・施設名にしてください
        """
    }
}

// MARK: - Request/Response Models

struct OpenAIRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let maxTokens: Int
    let temperature: Double
    
    private enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: MessageResponse
        let finishReason: String?
        
        private enum CodingKeys: String, CodingKey {
            case message
            case finishReason = "finish_reason"
        }
    }
    
    struct MessageResponse: Codable {
        let role: String
        let content: String?
    }
}

struct AIRecommendationResponse: Codable {
    let name: String
    let category: String
    let reason: String
}