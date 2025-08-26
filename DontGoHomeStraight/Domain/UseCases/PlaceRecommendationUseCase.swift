import Foundation
import CoreLocation

protocol PlaceRecommendationUseCase {
    func getRecommendations(
        currentLocation: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mood: Mood,
        transportMode: TransportMode
    ) async throws -> [Genre]
    
    func clearCache() async throws
    
    func getPhotoURL(photoReference: String, maxWidth: Int) -> URL?
}

class PlaceRecommendationUseCaseImpl: PlaceRecommendationUseCase {
    private let aiRepository: AIRecommendationRepository
    private let placeRepository: PlaceRepository
    private let cacheRepository: CacheRepository
    
    init(
        aiRepository: AIRecommendationRepository,
        placeRepository: PlaceRepository,
        cacheRepository: CacheRepository
    ) {
        self.aiRepository = aiRepository
        self.placeRepository = placeRepository
        self.cacheRepository = cacheRepository
    }
    
    func getRecommendations(
        currentLocation: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        mood: Mood,
        transportMode: TransportMode
    ) async throws -> [Genre] {
        // 1) 除外リスト
        let excludedPlaceIds = await cacheRepository.getExcludedPlaceIds()
        
        // 2) OpenAIから候補（10件）
        let request = AIRecommendationRequest(
            currentLocation: currentLocation,
            destination: destination,
            currentTime: Date(),
            mood: mood,
            transportMode: transportMode,
            excludedPlaceIds: excludedPlaceIds
        )
        #if DEBUG
        print("🧠 LLM: requesting candidates…")
        #endif
        let candidates = try await aiRepository.getRecommendations(request: request)
        #if DEBUG
        print("🧠 LLM: received \(candidates.count) candidates")
        #endif
        if candidates.isEmpty { return [] }
        
        // 3) Places Text Search で place 解決（name -> Place）
        #if DEBUG
        print("📍 Places: resolving \(candidates.count) names near currentLocation…")
        #endif
        let resolvedPlaces = try await placeRepository.searchPlaces(
            names: candidates.map { $0.name },
            near: currentLocation
        )
        #if DEBUG
        print("📍 Places: resolved \(resolvedPlaces.count) places")
        #endif
        if resolvedPlaces.isEmpty { return [] }
        
        // 3.5) ルート回廊幅で事前フィルタ（出発地-目的地の線分からの最短距離）
        let corridorWidth = corridorWidthMeters(for: transportMode)
        var prefiltered: [Place] = resolvedPlaces.filter { place in
            let d = distanceToSegmentMeters(
                from: currentLocation,
                to: destination,
                point: place.coordinate
            )
            return d <= corridorWidth
        }
        #if DEBUG
        print("🧭 Prefilter: within corridor(width=\(Int(corridorWidth))m) = \(prefiltered.count)")
        #endif
        // フォールバック：ゼロ件なら、出発地/目的地のいずれかから交通手段別半径で再評価
        if prefiltered.isEmpty {
            let radial = maxRadiusMeters(for: transportMode)
            prefiltered = resolvedPlaces.filter { place in
                let dStart = place.distance(from: currentLocation)
                let dEnd = place.distance(from: destination)
                return min(dStart, dEnd) <= radial
            }
            #if DEBUG
            print("🧭 Prefilter Fallback: within radial(\(Int(radial))m) from start/end = \(prefiltered.count)")
            #endif
            if prefiltered.isEmpty { return [] }
        }

        // 3.6) 補助取得: 候補が少ない場合は回廊沿いにタイプ検索して補強
        if prefiltered.count < 3 {
            let existingIds = Set(prefiltered.map { $0.placeId })
            var ids = existingIds
            var augmented: [Place] = []
            let points = corridorSamplePoints(origin: currentLocation, destination: destination)
            let types = recommendedTypesForMood(mood)
            let augRadius = max(Int(corridorWidth), 1000)
            for p in points {
                for t in types {
                    do {
                        let places = try await placeRepository.searchPlaces(location: p, type: t, radius: augRadius)
                        for pl in places {
                            if ids.contains(pl.placeId) { continue }
                            augmented.append(pl)
                            ids.insert(pl.placeId)
                        }
                    } catch {
                        #if DEBUG
                        print("⚠️ Augment search failed for type=\(t): \(error)")
                        #endif
                    }
                }
            }
            if augmented.isEmpty == false {
                prefiltered.append(contentsOf: augmented)
                #if DEBUG
                print("➕ Prefilter Augment: added=\(augmented.count), total=\(prefiltered.count)")
                #endif
            }
        }
        
        // name -> LLMCandidate のマップ
        let nameToCandidate: [String: LLMCandidate] = Dictionary(uniqueKeysWithValues: candidates.map { ($0.name, $0) })
        
        // 4) Distance Matrix で current -> place の所要時間（秒）
        #if DEBUG
        print("🕒 DM: requesting durations for \(prefiltered.count) destinations, mode=\(transportMode.rawValue)…")
        #endif
        let dmClient = GoogleDistanceMatrixClient(apiKey: Environment.googlePlacesAPIKey)
        let dmInputs = prefiltered.map { $0.coordinate }
        let durationsSec = try await dmClient.getDurationsSeconds(
            origin: currentLocation,
            destinations: dmInputs,
            mode: transportMode
        )
        #if DEBUG
        print("🕒 DM: received durations count=\(durationsSec.count)")
        #endif
        
        // 5) open_now 判定は使用しない（営業時間に関わらず候補に含める）
        
        // 6) 30分以内、除外 place_id をフィルタ（段階的フォールバック付き）
        let maxDurationLimits = [30.0, 40.0, 50.0, 60.0] // 分単位
        var eligible: [ScoredPlace] = []
        var usedTimeLimit: Double = 30.0
        
        for timeLimit in maxDurationLimits {
            let maxDurationSeconds = timeLimit * 60.0
            eligible = []
            
            for (idx, place) in prefiltered.enumerated() {
                guard idx < durationsSec.count else { continue }
                let duration = durationsSec[idx]
                guard duration.isFinite, duration <= maxDurationSeconds else { continue }
                if excludedPlaceIds.contains(place.placeId) { continue }
                let candidateCategory = nameToCandidate[place.name]?.category ?? place.genre.category
                eligible.append(ScoredPlace(place: place, candidateCategory: candidateCategory, durationSec: duration))
            }
            
            #if DEBUG
            print("✅ Filter: eligible=\(eligible.count) within \(Int(timeLimit))min")
            #endif
            
            if !eligible.isEmpty {
                usedTimeLimit = timeLimit
                break
            }
        }
        
        if eligible.isEmpty {
            // フォールバック: 60分でも0件のとき、所要時間が短い順に暫定候補を作る
            #if DEBUG
            print("⚠️ Eligible empty after 60min. Fallback by shortest durations…")
            #endif
            let fallbackLimitSec: TimeInterval = 90 * 60
            var tmp: [ScoredPlace] = []
            for (idx, place) in prefiltered.enumerated() {
                guard idx < durationsSec.count else { continue }
                let duration = durationsSec[idx]
                guard duration.isFinite else { continue }
                if excludedPlaceIds.contains(place.placeId) { continue }
                if duration <= fallbackLimitSec {
                    let cat = nameToCandidate[place.name]?.category ?? determineCategoryFromPlaceType(place.genre.googleMapType)
                    tmp.append(ScoredPlace(place: place, candidateCategory: cat, durationSec: duration))
                }
            }
            if tmp.isEmpty {
                // 上限なしで最短3件
                var any: [ScoredPlace] = []
                for (idx, place) in prefiltered.enumerated() {
                    guard idx < durationsSec.count else { continue }
                    let duration = durationsSec[idx]
                    guard duration.isFinite else { continue }
                    if excludedPlaceIds.contains(place.placeId) { continue }
                    let cat = nameToCandidate[place.name]?.category ?? determineCategoryFromPlaceType(place.genre.googleMapType)
                    any.append(ScoredPlace(place: place, candidateCategory: cat, durationSec: duration))
                }
                eligible = Array(any.sorted { $0.durationSec < $1.durationSec }.prefix(3))
            } else {
                eligible = Array(tmp.sorted { $0.durationSec < $1.durationSec }.prefix(6))
            }
            usedTimeLimit = 90.0
            #if DEBUG
            print("✅ Fallback eligible by duration: \(eligible.count)")
            #endif
            if eligible.isEmpty { return [] }
        }

        // 6.5) open_now をスコアリング用に取得（フィルタはしない）
        var openNowMap: [String: Bool] = [:]
        do {
            let detailsClient = GooglePlaceDetailsOpenClient(placeRepository: placeRepository)
            for sp in eligible {
                // 主に屋内のみ取得して呼び出し数を抑制
                if isIndoor(place: sp.place) {
                    if let isOpen = try? await detailsClient.isOpenNow(placeId: sp.place.placeId) {
                        openNowMap[sp.place.placeId] = isOpen
                    }
                }
            }
        }
        #if DEBUG
        if openNowMap.isEmpty == false {
            let openCount = openNowMap.values.filter { $0 }.count
            print("✅ Open-now fetched: total=\(openNowMap.count), open=\(openCount)")
        }
        #endif
        
        // 7) スコアリング（open_now にボーナス）
        let scored = scorePlaces(eligible: eligible, primaryRoute: nil, openNowMap: openNowMap)
            .sorted { $0.score > $1.score }
        
        // 8) 30/70構成を強制
        let restaurants = scored.filter { $0.candidateCategory == .restaurant }
        let others = scored.filter { $0.candidateCategory == .other }
        
        var picked: [ScoredPlace] = []
        if let topRestaurant = restaurants.first { picked.append(topRestaurant) }
        for s in others { if picked.count < 3 { picked.append(s) } }
        if picked.count < 3 {
            for s in restaurants { if picked.contains(where: { $0.place.placeId == s.place.placeId }) == false && picked.count < 3 { picked.append(s) } }
        }
        
        var finalThree = Array(picked.prefix(3))
        if finalThree.isEmpty {
            return []
        }
        // 不足時のフォールバック: open_now 無視＋時間上限を緩和して最短所要時間順に補完
        if finalThree.count < 3 {
            let fallbackLimitMinutes: Double = 90.0
            let maxSec = fallbackLimitMinutes * 60.0
            var pickedIds = Set(finalThree.map { $0.place.placeId })
            var candidates: [(place: Place, duration: TimeInterval)] = []
            for (idx, place) in prefiltered.enumerated() {
                guard idx < durationsSec.count else { continue }
                if pickedIds.contains(place.placeId) { continue }
                if excludedPlaceIds.contains(place.placeId) { continue }
                let duration = durationsSec[idx]
                guard duration.isFinite, duration <= maxSec else { continue }
                candidates.append((place, duration))
            }
            candidates.sort { $0.duration < $1.duration }
            for c in candidates {
                // カテゴリは place の type から決定
                let cat = determineCategoryFromPlaceType(c.place.genre.googleMapType)
                finalThree.append(ScoredPlace(place: c.place, candidateCategory: cat, durationSec: c.duration))
                pickedIds.insert(c.place.placeId)
                if finalThree.count >= 3 { break }
            }
            #if DEBUG
            if candidates.isEmpty == false {
                print("⚠️ Fallback fill used: up to \(Int(fallbackLimitMinutes))min, added=\(finalThree.count))")
            }
            #endif
        }
        
        // 9) ジャンルを返す（寄り道タイムを名称に付与: "ジャンル名 (XX分)")
        var genres: [Genre] = []
        for sp in finalThree {
            let category = determineCategoryFromPlaceType(sp.place.genre.googleMapType)
            let baseName = mapPlaceTypeToGenreName(sp.place.genre.googleMapType, category: category)
            let mins = Int(round(sp.durationSec / 60.0))
            let displayName = "\(baseName) (\(mins)分)"
            var hintText: String? = nil
            do {
                let hintInput = PlaceHintInput(
                    spotName: sp.place.name,
                    category: category,
                    isIndoor: isIndoor(place: sp.place),
                    vibe: mood.vibeType,
                    transportMode: transportMode
                )
                hintText = try await aiRepository.generateHint(for: hintInput)
            } catch {
                #if DEBUG
                print("⚠️ Hint generation failed for \(sp.place.name): \(error)")
                #endif
            }
            let g = Genre(
                name: displayName,
                category: category,
                googleMapType: sp.place.genre.googleMapType,
                hint: hintText,
                durationMinutes: Int(round(sp.durationSec / 60.0))
            )
            genres.append(g)
        }
        #if DEBUG
        print("🎯 Picked spots (\(finalThree.count)):")
        for sp in finalThree {
            let mins = Int(round(sp.durationSec / 60.0))
            let openLabel = (openNowMap[sp.place.placeId] == true) ? " (open)" : ""
            print("  • \(sp.place.name) [\(sp.place.genre.googleMapType)] ~ \(mins) min\(openLabel)")
        }
        #endif
        #if DEBUG
        print("📋 Received Genres: \(genres.count) items")
        for g in genres { print("  • \(g.name) [\(g.googleMapType)]") }
        #endif
        
        #if DEBUG
        if usedTimeLimit > 30.0 {
            print("⚠️ Time fallback: used \(Int(usedTimeLimit))min limit")
        }
        #endif
        
        // キャッシュ保存と除外
        await cacheRepository.savePlacesForGenres(places: finalThree.map { $0.place }, genres: genres)
        for sp in finalThree { await cacheRepository.addExcludedPlaceId(sp.place.placeId) }
        
        return genres
    }
    
    private func maxRadiusMeters(for mode: TransportMode) -> CLLocationDistance {
        switch mode {
        case .walking:
            return 2_000
        case .cycling:
            return 5_000
        case .driving:
            return 20_000
        case .transit:
            return 10_000
        }
    }

    private func corridorWidthMeters(for mode: TransportMode) -> CLLocationDistance {
        switch mode {
        case .walking:
            return 800
        case .cycling:
            return 1_200
        case .driving:
            return 2_000
        case .transit:
            return 1_500
        }
    }
    
    private func determineCategoryFromPlaceType(_ googleMapType: String) -> GenreCategory {
        switch googleMapType {
        case "restaurant", "cafe", "bar", "meal_takeaway", "bakery":
            return .restaurant
        default:
            return .other
        }
    }
    
    private func mapPlaceTypeToGenreName(_ googleMapType: String, category: GenreCategory) -> String {
        switch googleMapType {
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
        default:
            return category == .restaurant ? "グルメ" : "スポット"
        }
    }
    
    func clearCache() async throws {
        await cacheRepository.clearCache()
    }
    
    func getPhotoURL(photoReference: String, maxWidth: Int) -> URL? {
        return placeRepository.getPhotoURL(photoReference: photoReference, maxWidth: maxWidth)
    }
}

// MARK: - Scoring and helpers

private struct ScoredPlace: Hashable {
    let place: Place
    let candidateCategory: GenreCategory
    let durationSec: TimeInterval
    var score: Double = 0
}

private extension PlaceRecommendationUseCaseImpl {
    // LLM用のタイプ配列に近いが、ユースケース内で使う簡易ヘルパー
    func recommendedTypesForMood(_ mood: Mood) -> [String] {
        switch (mood.activityType, mood.vibeType) {
        case (.indoor, .jazzy):
            return ["cafe", "bar", "museum", "art_gallery", "library"]
        case (.indoor, .discovery):
            return ["museum", "library", "book_store", "art_gallery", "aquarium"]
        case (.indoor, .exciting):
            return ["shopping_mall", "movie_theater", "amusement_center", "game_center"]
        case (.outdoor, .jazzy):
            return ["park", "garden", "scenic_viewpoint", "cafe", "tourist_attraction"]
        case (.outdoor, .discovery):
            return ["tourist_attraction", "park", "historical_site", "zoo", "botanical_garden"]
        case (.outdoor, .exciting):
            return ["amusement_park", "adventure_park", "sports_complex", "beach", "hiking_area"]
        }
    }

    // 既存のSystemWaypointSuggestionUseCaseに合わせた3点サンプリング
    func corridorSamplePoints(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        func interp(_ t: Double) -> CLLocationCoordinate2D {
            CLLocationCoordinate2D(
                latitude: origin.latitude + (destination.latitude - origin.latitude) * t,
                longitude: origin.longitude + (destination.longitude - origin.longitude) * t
            )
        }
        return [0.25, 0.5, 0.75].map { interp($0) }
    }
    // 2地点を結ぶ線分までの点の最短距離（メートル）。近距離前提の簡易球面→平面近似。
    func distanceToSegmentMeters(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D, point p: CLLocationCoordinate2D) -> CLLocationDistance {
        // 基準緯度の平均でメートル換算係数を安定化
        let lat0 = (a.latitude + b.latitude + p.latitude) / 3.0
        let metersPerLat = 111_132.0
        let metersPerLon = cos(lat0 * .pi / 180.0) * 111_320.0
        func toXY(_ c: CLLocationCoordinate2D) -> (x: Double, y: Double) {
            let x = (c.longitude) * metersPerLon
            let y = (c.latitude) * metersPerLat
            return (x, y)
        }
        let A = toXY(a)
        let B = toXY(b)
        let P = toXY(p)
        let ABx = B.x - A.x
        let ABy = B.y - A.y
        let APx = P.x - A.x
        let APy = P.y - A.y
        let ab2 = ABx*ABx + ABy*ABy
        if ab2 <= 1e-6 {
            // a==b の退避
            let dx = P.x - A.x
            let dy = P.y - A.y
            return sqrt(dx*dx + dy*dy)
        }
        // 直線上の射影係数 t を線分 [0,1] にクランプ
        var t = (APx*ABx + APy*ABy) / ab2
        if t < 0 { t = 0 } else if t > 1 { t = 1 }
        let Qx = A.x + t*ABx
        let Qy = A.y + t*ABy
        let dx = P.x - Qx
        let dy = P.y - Qy
        return sqrt(dx*dx + dy*dy)
    }

    func isIndoor(place: Place) -> Bool {
        // 室内が想定される type 群
        let indoorTypes: Set<String> = [
            "restaurant", "cafe", "bar", "bakery", "shopping_mall", "movie_theater",
            "museum", "library", "book_store"
        ]
        return indoorTypes.contains(place.genre.googleMapType)
    }
    
    func scorePlaces(eligible: [ScoredPlace], primaryRoute: String?, openNowMap: [String: Bool] = [:]) -> [ScoredPlace] {
        // 重み
        let weightDuration = 1.0
        let weightOnRoute = 3.0
        let weightRating = 0.5
        let weightOpenNowBonus = 2.0
        let weightDiversity = 0.5
        
        // ここでは on-route 判定はスキップ（必要なら Directions overview_polyline 近傍判定に置換）
        func onRouteBonus(for _: Place) -> Double { return 0 }
        
        // チェーン・近接の簡易ペナルティ（同名開始 or 300m以内）
        func diversityPenalty(for place: Place, picked: [ScoredPlace]) -> Double {
            for p in picked {
                if p.place.name.split(separator: " ").first == place.name.split(separator: " ").first { return 0.5 }
                let d = p.place.distance(from: place.coordinate)
                if d < 300 { return 0.5 }
            }
            return 0
        }
        
        var out: [ScoredPlace] = []
        for var sp in eligible {
            let durationComponent = -weightDuration * (sp.durationSec / 60.0)
            let onRouteComponent = weightOnRoute * onRouteBonus(for: sp.place)
            let ratingValue = sp.place.rating ?? 0
            let ratingComponent = weightRating * ratingValue
            let openBonus = (openNowMap[sp.place.placeId] == true) ? weightOpenNowBonus : 0
            let penalty = weightDiversity * diversityPenalty(for: sp.place, picked: out)
            sp.score = durationComponent + onRouteComponent + ratingComponent + openBonus - penalty
            out.append(sp)
        }
        return out
    }
}