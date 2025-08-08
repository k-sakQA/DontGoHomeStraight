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
        #if DEBUG
        print("🤖 OpenAI API Call Start")
        print("📝 API Key: \(String(apiKey.prefix(10)))...")
        print("📍 Prompt: \(request.toPrompt())")
        #endif
        
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
                #if DEBUG
                print("✅ OpenAI API Success - Status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📤 Response: \(responseString)")
                }
                #endif
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                return try parseRecommendations(from: openAIResponse)
                
            case 401:
                #if DEBUG
                print("❌ OpenAI API Error - Unauthorized (401)")
                #endif
                throw AIRecommendationError.apiKeyInvalid
                
            case 429:
                #if DEBUG
                print("❌ OpenAI API Error - Quota Exceeded (429)")
                #endif
                throw AIRecommendationError.quotaExceeded
                
            default:
                #if DEBUG
                print("❌ OpenAI API Error - Status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📤 Error Response: \(responseString)")
                }
                #endif
                throw AIRecommendationError.aiServiceUnavailable
            }
            
        } catch let error as AIRecommendationError {
            #if DEBUG
            print("❌ OpenAI API Error: \(error)")
            #endif
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
        
        #if DEBUG
        print("🔍 Parsing content: \(content)")
        #endif
        
        // JSONレスポンスをパース
        do {
            let jsonData = content.data(using: .utf8) ?? Data()
            let recommendations = try JSONDecoder().decode([AIRecommendationResponse].self, from: jsonData)
            
            #if DEBUG
            print("✅ JSON Parse Success - \(recommendations.count) items:")
            for (index, rec) in recommendations.enumerated() {
                print("  \(index + 1). \(rec.name) (\(rec.category))")
            }
            #endif
            
            return recommendations.map { $0.name }
        } catch {
            #if DEBUG
            print("❌ JSON Parse Failed: \(error)")
            print("Trying fallback parsing...")
            #endif
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
        あなたは日本国内の寄り道スポット提案の専門家です。

        【タスク】
        ユーザーの現在地から目的地へ向かうルート上、またはルートから少し迂回した場所で、
        移動時間が現在地から30分以内で行ける実在のスポットを3つ提案してください。

        【重要な制約】
        1. 飲食店を1件（30%）、それ以外を2件（70%）必ず含めること
        2. 現在地→目的地のルート上、またはルートから30分以内で行けるスポットに限定
        3. 除外リストに含まれるスポットは絶対に提案しない
        4. ユーザーの気分と移動手段を考慮する
        5. Google Places APIで検索可能な具体的な店名・施設名にする
        6. 室内施設の場合は営業時間中のものだけにする
        7. 提案理由に「寄り道時間内に行ける」ことを明記する

        【回答形式】
        以下のJSON形式で厳密に回答してください：
        [
          {
            "name": "具体的なスポット名",
            "category": "restaurant",
            "reason": "推薦理由（寄り道時間内で行けることを含める）"
          },
          {
            "name": "具体的なスポット名",
            "category": "other",
            "reason": "推薦理由（寄り道時間内で行けることを含める）"
          },
          {
            "name": "具体的なスポット名",
            "category": "other",
            "reason": "推薦理由（寄り道時間内で行けることを含める）"
          }
        ]
        ※categoryは"restaurant"または"other"のみ
        ※必ず3件提案する
        ※nameは実在する具体的な店名・施設名にする
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