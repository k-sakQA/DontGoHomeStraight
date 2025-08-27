import Foundation
import CoreLocation

class GooglePlacesAPIClient {
    private let apiKey: String
    private let session = URLSession.shared
    private let baseURL = "https://maps.googleapis.com/maps/api/place"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func searchPlace(name: String, near location: CLLocationCoordinate2D) async throws -> Place? {
        let encodedQuery = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/textsearch/json?query=\(encodedQuery)&location=\(location.latitude),\(location.longitude)&radius=5000&key=\(apiKey)"
        
        #if DEBUG
        print("🔍 Google Places API Request:")
        print("  Query: \(name)")
        print("  Location: \(location.latitude), \(location.longitude)")
        print("  URL: \(urlString)")
        #endif
        
        guard let url = URL(string: urlString) else {
            #if DEBUG
            print("❌ Invalid URL")
            #endif
            throw PlaceRepositoryError.searchFailed
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlaceRepositoryError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                #if DEBUG
                print("✅ Google Places API Success - Status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📤 Response: \(responseString)")
                }
                #endif
                
                let searchResponse = try JSONDecoder().decode(GooglePlacesSearchResponse.self, from: data)
                
                #if DEBUG
                print("📋 Found \(searchResponse.results.count) results")
                if let firstResult = searchResponse.results.first {
                    print("🎯 First result: \(firstResult.name)")
                } else {
                    print("❌ No results found")
                }
                #endif
                
                return searchResponse.results.first?.toPlace()
                
            case 400:
                #if DEBUG
                print("❌ Google Places API Error 400 - Bad Request")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📤 Error Response: \(responseString)")
                }
                #endif
                throw PlaceRepositoryError.searchFailed
            case 401:
                #if DEBUG
                print("❌ Google Places API Error 401 - Unauthorized (Invalid API Key)")
                #endif
                throw PlaceRepositoryError.apiKeyInvalid
            case 429:
                #if DEBUG
                print("❌ Google Places API Error 429 - Quota Exceeded")
                #endif
                throw PlaceRepositoryError.quotaExceeded
            default:
                #if DEBUG
                print("❌ Google Places API Error \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📤 Error Response: \(responseString)")
                }
                #endif
                throw PlaceRepositoryError.networkError
            }
            
        } catch let error as PlaceRepositoryError {
            #if DEBUG
            print("❌ Google Places API Error: \(error)")
            #endif
            throw error
        } catch {
            #if DEBUG
            print("❌ Google Places API Network Error: \(error)")
            #endif
            throw PlaceRepositoryError.networkError
        }
    }
    
    func searchPlaces(location: CLLocationCoordinate2D, type: String, radius: Int) async throws -> [Place] {
        let urlString = "\(baseURL)/nearbysearch/json?location=\(location.latitude),\(location.longitude)&radius=\(radius)&type=\(type)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw PlaceRepositoryError.searchFailed
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlaceRepositoryError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let searchResponse = try JSONDecoder().decode(GooglePlacesSearchResponse.self, from: data)
                return searchResponse.results.compactMap { $0.toPlace() }
                
            case 401:
                throw PlaceRepositoryError.apiKeyInvalid
            case 429:
                throw PlaceRepositoryError.quotaExceeded
            default:
                throw PlaceRepositoryError.networkError
            }
            
        } catch let error as PlaceRepositoryError {
            throw error
        } catch {
            throw PlaceRepositoryError.networkError
        }
    }
    
    func getNearbyPlaces(location: CLLocationCoordinate2D, radius: Int) async throws -> [Place] {
        let urlString = "\(baseURL)/nearbysearch/json?location=\(location.latitude),\(location.longitude)&radius=\(radius)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw PlaceRepositoryError.searchFailed
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlaceRepositoryError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let searchResponse = try JSONDecoder().decode(GooglePlacesSearchResponse.self, from: data)
                return searchResponse.results.compactMap { $0.toPlace() }
                
            case 401:
                throw PlaceRepositoryError.apiKeyInvalid
            case 429:
                throw PlaceRepositoryError.quotaExceeded
            default:
                throw PlaceRepositoryError.networkError
            }
            
        } catch let error as PlaceRepositoryError {
            throw error
        } catch {
            throw PlaceRepositoryError.networkError
        }
    }
    
    func getPlaceDetails(placeId: String) async throws -> Place? {
        let fields = "name,formatted_address,geometry,types,rating,user_ratings_total,price_level,photos,opening_hours"
        let urlString = "\(baseURL)/details/json?place_id=\(placeId)&fields=\(fields)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw PlaceRepositoryError.invalidPlaceId
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlaceRepositoryError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let detailsResponse = try JSONDecoder().decode(GooglePlaceDetailsResponse.self, from: data)
                return detailsResponse.result?.toPlace()
                
            case 401:
                throw PlaceRepositoryError.apiKeyInvalid
            case 429:
                throw PlaceRepositoryError.quotaExceeded
            default:
                throw PlaceRepositoryError.networkError
            }
            
        } catch let error as PlaceRepositoryError {
            throw error
        } catch {
            throw PlaceRepositoryError.networkError
        }
    }
    
    func validatePlace(name: String, location: CLLocationCoordinate2D) async throws -> Bool {
        guard let place = try await searchPlace(name: name, near: location) else {
            return false
        }
        
        // 距離チェック（5km以内）
        let distance = CLLocation(latitude: location.latitude, longitude: location.longitude)
            .distance(from: CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude))
        
        return distance <= 5000 // 5km
    }
    
    func getPhotoURL(photoReference: String, maxWidth: Int = 400) -> URL? {
        let urlString = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=\(maxWidth)&photo_reference=\(photoReference)&key=\(apiKey)"
        return URL(string: urlString)
    }
    
    func searchPlaceCandidates(query: String, near location: CLLocationCoordinate2D, limit: Int) async throws -> [Place] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/textsearch/json?query=\(encodedQuery)&location=\(location.latitude),\(location.longitude)&radius=5000&key=\(apiKey)"
        
        #if DEBUG
        print("🔍 Google Places API - Search Candidates:")
        print("  Query: \(query)")
        print("  Limit: \(limit)")
        #endif
        
        guard let url = URL(string: urlString) else {
            throw PlaceRepositoryError.searchFailed
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw PlaceRepositoryError.networkError
            }
            
            let searchResponse = try JSONDecoder().decode(GooglePlacesSearchResponse.self, from: data)
            
            #if DEBUG
            print("📋 Found \(searchResponse.results.count) total results")
            #endif
            
            // 指定された数だけ結果を返す
            let places = searchResponse.results.prefix(limit).compactMap { result in
                result.toPlace()
            }
            
            #if DEBUG
            print("✅ Returning \(places.count) candidates")
            for (index, place) in places.enumerated() {
                print("  \(index + 1). \(place.name) - \(place.address)")
            }
            #endif
            
            return Array(places)
            
        } catch {
            #if DEBUG
            print("❌ Search candidates error: \(error)")
            #endif
            throw PlaceRepositoryError.searchFailed
        }
    }
}

// MARK: - Response Models

struct GooglePlacesSearchResponse: Codable {
    let results: [GooglePlaceResult]
    let status: String
}

struct GooglePlaceDetailsResponse: Codable {
    let result: GooglePlaceResult?
    let status: String
}

struct GooglePlaceResult: Codable {
    let placeId: String
    let name: String
    let formattedAddress: String?
    let geometry: PlaceGeometry
    let types: [String]?
    let rating: Double?
    let priceLevel: Int?
    let photos: [PlacePhoto]?
    let openingHours: OpeningHours?
    let vicinity: String?
    let userRatingsTotal: Int?
    
    private enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case formattedAddress = "formatted_address"
        case geometry, types, rating, vicinity
        case priceLevel = "price_level"
        case photos
        case openingHours = "opening_hours"
        case userRatingsTotal = "user_ratings_total"
    }
    
    func toPlace() -> Place? {
        let genre = determineGenre(from: types)
        return Place(
                name: name,
                coordinate: CLLocationCoordinate2D(
                    latitude: geometry.location.lat,
                    longitude: geometry.location.lng
                ),
                address: formattedAddress ?? vicinity ?? "",
                genre: genre,
                rating: rating,
                priceLevel: priceLevel,
                photoReference: photos?.first?.photoReference,
                isOpen: openingHours?.openNow,
                placeId: placeId,
                vicinity: vicinity,
                userRatingsTotal: userRatingsTotal
            )
    }
    }
    
    private func determineGenre(from types: [String]?) -> Genre {
        guard let types = types, types.isEmpty == false else {
            return Genre(name: "スポット", category: .other, googleMapType: "establishment")
        }

        // 優先度付きで最も具体的なタイプを選択
        let preferredType = choosePreferredType(from: types)

        // カテゴリ決定（厳密な飲食系のみに限定、"food" は除外）
        let restaurantTypesStrict = ["restaurant", "cafe", "bar", "bakery", "meal_takeaway", "meal_delivery"]
        let isRestaurant = restaurantTypesStrict.contains(preferredType)

        let displayName = mapTypeToGenreName(preferredType)
        return Genre(
            name: displayName,
            category: isRestaurant ? .restaurant : .other,
            googleMapType: preferredType
        )
    }
    
    // 優先度に従いTypesから最も具体的なtypeを選定
    // 先頭の汎用type(establishment/point_of_interest)に引っ張られないようにする
    private func choosePreferredType(from types: [String]) -> String {
        // 優先度: より具体的なものを上位に
        let priority: [String] = [
            // 飲食（厳密）
            "restaurant", "cafe", "bar", "bakery", "meal_takeaway", "meal_delivery",
            // 観光・屋外
            "park", "tourist_attraction", "amusement_park", "zoo",
            // 文化施設
            "museum", "movie_theater", "library", "book_store",
            // 商業施設
            "shopping_mall",
            // 祈り
            "place_of_worship",
            // 生活インフラ
            "convenience_store", "gas_station", "pharmacy", "hospital", "bank", "atm",
        ]

        // 優先リストで最初に一致したtypeを返す
        if let picked = priority.first(where: { types.contains($0) }) {
            return picked
        }

        // それ以外は具体的なものを優先して選ぶ（汎用typeを除外）
        let generic: Set<String> = ["establishment", "point_of_interest"]
        if let nonGeneric = types.first(where: { generic.contains($0) == false }) {
            return nonGeneric
        }

        // 最終手段: 先頭
        return types.first ?? "establishment"
    }
    
    private func mapTypeToGenreName(_ type: String) -> String {
        switch type {
        case "restaurant": return "レストラン"
        case "cafe": return "カフェ"
        case "bar": return "バー"
        case "meal_takeaway": return "テイクアウト"
        case "bakery": return "ベーカリー"
        case "park": return "公園"
        case "museum": return "美術館・博物館"
        case "library": return "図書館"
        case "book_store": return "書店"
        case "shopping_mall": return "ショッピングモール"
        case "movie_theater": return "映画館"
        case "tourist_attraction": return "観光スポット"
        case "place_of_worship": return "神社・寺院"
        case "amusement_park": return "遊園地"
        case "zoo": return "動物園"
        case "gas_station": return "ガソリンスタンド"
        case "hospital": return "病院"
        case "pharmacy": return "薬局"
        case "bank": return "銀行"
        case "atm": return "ATM"
        case "convenience_store": return "コンビニエンスストア"
        default: return "スポット"
        }
    }


struct PlaceGeometry: Codable {
    let location: PlaceLocation
}

struct PlaceLocation: Codable {
    let lat: Double
    let lng: Double
}

struct PlacePhoto: Codable {
    let photoReference: String
    let width: Int
    let height: Int
    
    private enum CodingKeys: String, CodingKey {
        case photoReference = "photo_reference"
        case width, height
    }
}

struct OpeningHours: Codable {
    let openNow: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
    }
}

// MARK: - Distance Matrix client

final class GoogleDistanceMatrixClient {
    private let apiKey: String
    private let session = URLSession.shared
    
    init(apiKey: String) { self.apiKey = apiKey }
    
    func getDurationsSeconds(
        origin: CLLocationCoordinate2D,
        destinations: [CLLocationCoordinate2D],
        mode: TransportMode
    ) async throws -> [TimeInterval] {
        guard destinations.isEmpty == false else { return [] }
        let dmBase = "https://maps.googleapis.com/maps/api/distancematrix/json"
        
        func buildURL(modeString: String, addDepartureNow: Bool, destinationsParam: String) -> URL? {
            #if DEBUG
            print("🛠️ DM: build URL (mode=\(modeString), addDepartureNow=\(addDepartureNow)) for destinations size=\(destinationsParam.split(separator: "|").count)")
            #endif
            var components = URLComponents(string: dmBase)
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "origins", value: "\(origin.latitude),\(origin.longitude)"),
                URLQueryItem(name: "destinations", value: destinationsParam),
                URLQueryItem(name: "mode", value: modeString),
                URLQueryItem(name: "language", value: "ja"),
                URLQueryItem(name: "key", value: apiKey)
            ]
            if addDepartureNow {
                queryItems.append(URLQueryItem(name: "departure_time", value: "now"))
            }
            components?.queryItems = queryItems
            let url = components?.url
            #if DEBUG
            if let url = url {
                print("✅ DM: built URL => \(url.absoluteString)")
            } else {
                print("❌ DM: failed to build URL")
            }
            #endif
            return url
        }
        
        func requestDurations(url: URL) async throws -> DistanceMatrixResponse {
            #if DEBUG
            print("🌐 Distance Matrix API URL: \(url.absoluteString)")
            #endif
            do {
                let (data, response) = try await session.data(from: url)
                if let http = response as? HTTPURLResponse {
                    #if DEBUG
                    print("📡 DM HTTP status=\(http.statusCode)")
                    #endif
                    guard (200...299).contains(http.statusCode) else {
                        #if DEBUG
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("📨 DM Error Body: \(responseString)")
                        }
                        #endif
                        throw PlaceRepositoryError.networkError
                    }
                }
                #if DEBUG
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🌐 Distance Matrix API Response: \(responseString)")
                }
                #endif
                return try JSONDecoder().decode(DistanceMatrixResponse.self, from: data)
            } catch {
                #if DEBUG
                print("❌ DM request failed: \(error)")
                #endif
                throw PlaceRepositoryError.networkError
            }
        }
        
        // Google Distance Matrix は elements 上限（origins×destinations <= 100）があるため分割実行
        // origins は常に1想定なので、destinations を最大90件単位で分割する
        func chunked<T>(_ array: [T], size: Int) -> [[T]] {
            guard size > 0 else { return [array] }
            var result: [[T]] = []
            var i = 0
            while i < array.count {
                let end = min(i + size, array.count)
                result.append(Array(array[i..<end]))
                i = end
            }
            return result
        }

        let addDeparture = (mode == .transit)
        // Google Distance Matrix の制約（origins×destinations の次元上限）に合わせて
        // 宛先は 25 件/回に分割（origin は常に 1）
        let maxPerRequest = 25
        let batches = chunked(destinations, size: maxPerRequest)
        var allDurations: [TimeInterval] = []
        
        for (batchIndex, batch) in batches.enumerated() {
            let destinationsParam = batch.map { "\($0.latitude),\($0.longitude)" }.joined(separator: "|")
            guard let firstURL = buildURL(modeString: mode.googleMapsMode, addDepartureNow: addDeparture, destinationsParam: destinationsParam) else {
                allDurations.append(contentsOf: Array(repeating: TimeInterval.infinity, count: batch.count))
                continue
            }
            var dm = try await requestDurations(url: firstURL)
            var row = dm.rows.first
            // Fallback if all ZERO_RESULTS/!OK
            if let r = row, r.elements.allSatisfy({ $0.status != "OK" }) {
                var fallbackModeString: String? = nil
                if mode == .transit || mode == .cycling {
                    fallbackModeString = TransportMode.walking.googleMapsMode
                } else if mode == .walking {
                    fallbackModeString = TransportMode.driving.googleMapsMode
                }
                if let fb = fallbackModeString, let fbURL = buildURL(modeString: fb, addDepartureNow: false, destinationsParam: destinationsParam) {
                    #if DEBUG
                    print("🔁 Distance Matrix fallback with mode=\(fb) for batch #\(batchIndex+1)/\(batches.count)")
                    #endif
                    dm = try await requestDurations(url: fbURL)
                    row = dm.rows.first
                }
            }
            guard let finalRow = row else {
                allDurations.append(contentsOf: Array(repeating: TimeInterval.infinity, count: batch.count))
                continue
            }
            let durations = finalRow.elements.map { el -> TimeInterval in
                if el.status == "OK", let duration = el.duration {
                    return TimeInterval(duration.value)
                }
                #if DEBUG
                print("⚠️ Distance Matrix element status: \(el.status)")
                #endif
                return TimeInterval.infinity
            }
            // 要素不足時はInfで埋める
            if durations.count < batch.count {
                allDurations.append(contentsOf: durations + Array(repeating: TimeInterval.infinity, count: batch.count - durations.count))
            } else {
                allDurations.append(contentsOf: durations.prefix(batch.count))
            }
        }
        return allDurations
    }
}

private struct DistanceMatrixResponse: Codable {
    struct Row: Codable { let elements: [Element] }
    struct Element: Codable {
        let status: String
        let duration: Duration?  // オプショナルに変更
        struct Duration: Codable { let value: Int }
    }
    let rows: [Row]
    let status: String?
}

// MARK: - Place Details helper for open_now
final class GooglePlaceDetailsOpenClient {
    private let placeRepository: PlaceRepository
    init(placeRepository: PlaceRepository) { self.placeRepository = placeRepository }
    func isOpenNow(placeId: String) async throws -> Bool {
        if let place = try await placeRepository.getPlaceDetails(placeId: placeId) {
            return place.isOpen ?? true
        }
        return true
    }
}
