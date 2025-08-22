import Foundation
import CoreLocation

class OpenAIAPIClient {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let session = URLSession.shared
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func getRecommendations(request: AIRecommendationRequest) async throws -> [LLMCandidate] {
        #if DEBUG
        print("🤖 OpenAI API Call Start")
        print("📝 API Key: \(String(apiKey.prefix(10)))...")
        print("📍 Prompt: \(request.toPrompt())")
        #endif
        
        let openAIRequest = OpenAIRequest(
            model: "gpt-4-turbo",
            messages: [
                ChatMessage(role: "system", content: systemPrompt),
                ChatMessage(role: "user", content: request.toPrompt())
            ],
            maxTokens: 800,
            temperature: 0.2
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
    
    func generateHint(for place: PlaceHintInput) async throws -> String {
        #if DEBUG
        print("🤖 OpenAI Hint API Call Start: spot=\(place.spotName)")
        #endif
        let sys = """
        あなたは観光スポットの謎解き案内人です。対象スポット名を直接出さず、日本語で30文字程度の短いヒントを1文で返してください。語尾は体言止めや常体で簡潔に。記号は控えめに。
        """
        let user = """
        スポット: \(place.spotName)
        カテゴリ: \(place.category.displayName)
        屋内/屋外: \(place.isIndoor ? "屋内" : "屋外")
        気分: \(place.vibe.displayName)
        移動手段: \(place.transportMode.displayName)
        """
        let req = OpenAIRequest(
            model: "gpt-4o-mini",
            messages: [
                ChatMessage(role: "system", content: sys),
                ChatMessage(role: "user", content: user)
            ],
            maxTokens: 64,
            temperature: 0.5
        )
        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = try JSONEncoder().encode(req)
        urlRequest.httpBody = body
        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIRecommendationError.networkError
        }
        switch httpResponse.statusCode {
        case 200...299:
            let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            guard let content = openAIResponse.choices.first?.message.content else {
                throw AIRecommendationError.invalidResponse
            }
            let hint = content.trimmingCharacters(in: .whitespacesAndNewlines)
            return String(hint.prefix(40))
        case 401:
            throw AIRecommendationError.apiKeyInvalid
        case 429:
            throw AIRecommendationError.quotaExceeded
        default:
            throw AIRecommendationError.aiServiceUnavailable
        }
    }
    
    private func parseRecommendations(from response: OpenAIResponse) throws -> [LLMCandidate] {
        guard let choice = response.choices.first,
              let content = choice.message.content else {
            throw AIRecommendationError.invalidResponse
        }
        
        #if DEBUG
        print("🔍 Parsing content: \(content)")
        #endif
        
        // Expect pure JSON array of {name, category}
        guard let jsonData = content.data(using: .utf8) else {
            throw AIRecommendationError.invalidResponse
        }
        do {
            let candidates = try JSONDecoder().decode([LLMCandidate].self, from: jsonData)
            return candidates
        } catch {
            // Fallback: attempt to extract JSON substring
            if let start = content.firstIndex(of: "[") , let end = content.lastIndex(of: "]") {
                let jsonSubstring = String(content[start...end])
                let data = Data(jsonSubstring.utf8)
                let candidates = try JSONDecoder().decode([LLMCandidate].self, from: data)
                return candidates
            }
            throw AIRecommendationError.invalidResponse
        }
    }
    
    private var systemPrompt: String {
        return """
        あなたはルート寄り道スポット選定のアシスタントです。以下を厳守してください。
        - 10件の候補を返す
        - 各候補は {"name": string, "category": "restaurant"|"other"} のみ
        - 説明文やコードブロックを含めない
        - JSON配列のみを返す
        - 除外リストの place_id と一致するスポットは出さない（name重複も避ける）
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