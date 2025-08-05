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
                return searchResponse.results.first?.toPlace()
                
            case 400:
                throw PlaceRepositoryError.searchFailed
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
        let fields = "name,formatted_address,geometry,types,rating,price_level,photos,opening_hours"
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
    
    private enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case formattedAddress = "formatted_address"
        case geometry, types, rating, vicinity
        case priceLevel = "price_level"
        case photos
        case openingHours = "opening_hours"
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
            vicinity: vicinity
        )
    }
    
    private func determineGenre(from types: [String]?) -> Genre {
        guard let types = types else {
            return Genre(name: "スポット", category: .other, googleMapType: "establishment")
        }
        
        // レストラン系の判定
        let restaurantTypes = ["restaurant", "food", "meal_takeaway", "meal_delivery", "cafe", "bar", "bakery"]
        if types.contains(where: { restaurantTypes.contains($0) }) {
            let genreName = mapTypeToGenreName(types.first ?? "restaurant")
            return Genre(name: genreName, category: .restaurant, googleMapType: types.first ?? "restaurant")
        }
        
        // その他のジャンル
        let genreName = mapTypeToGenreName(types.first ?? "establishment")
        return Genre(name: genreName, category: .other, googleMapType: types.first ?? "establishment")
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