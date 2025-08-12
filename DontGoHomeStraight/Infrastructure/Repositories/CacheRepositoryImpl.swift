import Foundation

class CacheRepositoryImpl: CacheRepository {
    private let userDefaults = UserDefaults.standard
    private let memoryCache = NSCache<NSString, NSData>()
    // 推薦結果の一時マッピング（アプリ起動中のみ有効）
    private var tempGenreToPlaceId: [String: String] = [:]
    
    // UserDefaults Keys
    private enum Keys {
        static let excludedPlaceIds = "excluded_place_ids"
        static let genrePlaceMapping = "genre_place_mapping"
        static let lastCleanupDate = "last_cleanup_date"
    }
    
    init() {
        setupMemoryCache()
        performPeriodicCleanup()
    }
    
    private func setupMemoryCache() {
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 10 * 1024 * 1024 // 10MB
    }
    
    // MARK: - Place-Genre Mapping
    
    func savePlacesForGenres(places: [Place], genres: [Genre]) async {
        // 推薦結果の一時関連付け（マッピングは永続化しない）
        for (index, genre) in genres.enumerated() {
            if index < places.count {
                let place = places[index]
                // メモリだけに積む（UserDefaultsのマッピングは選択時に保存）
                if let data = try? JSONEncoder().encode(place) {
                    memoryCache.setObject(data as NSData, forKey: "place_\(place.placeId)" as NSString)
                }
                tempGenreToPlaceId[genre.id] = place.placeId
            }
        }
        // 永続化はしない
    }

    func saveSelectedPlaceForGenre(place: Place, genre: Genre) async {
        var mapping: [String: String] = getGenrePlaceMapping()
        mapping[genre.id] = place.placeId
        saveGenrePlaceMapping(mapping)
        await savePlaceDetails(place)
    }
    
    func getPlaceForGenre(genre: Genre) async -> Place? {
        // 先に一時マッピングを確認
        if let pid = tempGenreToPlaceId[genre.id] {
            return await getPlaceDetails(placeId: pid)
        }
        // 永続マッピングを参照
        let mapping = getGenrePlaceMapping()
        if let pid = mapping[genre.id] {
            return await getPlaceDetails(placeId: pid)
        }
        return nil
    }
    
    private func getGenrePlaceMapping() -> [String: String] {
        return userDefaults.dictionary(forKey: Keys.genrePlaceMapping) as? [String: String] ?? [:]
    }
    
    private func saveGenrePlaceMapping(_ mapping: [String: String]) {
        userDefaults.set(mapping, forKey: Keys.genrePlaceMapping)
    }
    
    // MARK: - Place Details Cache
    
    private func savePlaceDetails(_ place: Place) async {
        let key = "place_\(place.placeId)"
        
        do {
            let data = try JSONEncoder().encode(place)
            
            // メモリキャッシュ
            memoryCache.setObject(data as NSData, forKey: key as NSString)
            
            // UserDefaultsにも保存（永続化）
            userDefaults.set(data, forKey: key)
            
        } catch {
            #if DEBUG
            print("❌ スポット詳細の保存に失敗: \(error)")
            #endif
        }
    }
    
    private func getPlaceDetails(placeId: String) async -> Place? {
        let key = "place_\(placeId)"
        
        // メモリキャッシュから取得
        if let data = memoryCache.object(forKey: key as NSString) {
            do {
                return try JSONDecoder().decode(Place.self, from: data as Data)
            } catch {
                #if DEBUG
                print("❌ メモリキャッシュからのデコードに失敗: \(error)")
                #endif
            }
        }
        
        // UserDefaultsから取得
        if let data = userDefaults.data(forKey: key) {
            do {
                let place = try JSONDecoder().decode(Place.self, from: data)
                
                // メモリキャッシュに再保存
                memoryCache.setObject(data as NSData, forKey: key as NSString)
                
                return place
            } catch {
                #if DEBUG
                print("❌ UserDefaultsからのデコードに失敗: \(error)")
                #endif
            }
        }
        
        return nil
    }
    
    // MARK: - Excluded Places Management
    
    func saveExcludedPlaceIds(_ placeIds: [String]) async {
        userDefaults.set(placeIds, forKey: Keys.excludedPlaceIds)
    }
    
    func getExcludedPlaceIds() async -> [String] {
        return userDefaults.stringArray(forKey: Keys.excludedPlaceIds) ?? []
    }
    
    func addExcludedPlaceId(_ placeId: String) async {
        var excludedIds = await getExcludedPlaceIds()
        
        // 重複チェック
        if !excludedIds.contains(placeId) {
            excludedIds.append(placeId)
            
            // 最大100件まで保持（古いものから削除）
            if excludedIds.count > 100 {
                excludedIds.removeFirst(excludedIds.count - 100)
            }
            
            await saveExcludedPlaceIds(excludedIds)
        }
    }
    
    func clearExcludedPlaces() async {
        userDefaults.removeObject(forKey: Keys.excludedPlaceIds)
    }
    
    // MARK: - Cache Management
    
    func clearCache() async {
        // メモリキャッシュクリア
        memoryCache.removeAllObjects()
        tempGenreToPlaceId.removeAll()
        
        // UserDefaultsのキャッシュデータクリア
        let mapping = getGenrePlaceMapping()
        for placeId in mapping.values {
            userDefaults.removeObject(forKey: "place_\(placeId)")
        }
        
        // マッピングデータクリア
        userDefaults.removeObject(forKey: Keys.genrePlaceMapping)
        
        // 除外リストクリア
        userDefaults.removeObject(forKey: Keys.excludedPlaceIds)
        
        #if DEBUG
        print("🧹 キャッシュと除外リストをクリアしました")
        #endif
    }
    
    private func performPeriodicCleanup() {
        let lastCleanupDate = userDefaults.object(forKey: Keys.lastCleanupDate) as? Date ?? Date.distantPast
        let daysSinceLastCleanup = Date().timeIntervalSince(lastCleanupDate) / (24 * 60 * 60)
        
        // 7日に1回クリーンアップ
        if daysSinceLastCleanup >= 7 {
            Task {
                await cleanupOldData()
                userDefaults.set(Date(), forKey: Keys.lastCleanupDate)
            }
        }
    }
    
    private func cleanupOldData() async {
        let excludedIds = await getExcludedPlaceIds()
        
        // 除外リストが50件を超えた場合、古いものから削除
        if excludedIds.count > 50 {
            let newExcludedIds = Array(excludedIds.suffix(50))
            await saveExcludedPlaceIds(newExcludedIds)
        }
        
        #if DEBUG
        print("🧹 古いデータをクリーンアップしました")
        #endif
    }
}

// MARK: - Secure Cache for Sensitive Data

extension CacheRepositoryImpl {
    
    /// センシティブなデータの暗号化保存
    func saveSecureData<T: Codable>(_ data: T, key: String) async throws {
        do {
            let jsonData = try JSONEncoder().encode(data)
            let encryptedData = try encryptData(jsonData)
            userDefaults.set(encryptedData, forKey: "secure_\(key)")
        } catch {
            throw CacheError.encryptionFailed
        }
    }
    
    /// センシティブなデータの復号化取得
    func getSecureData<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        guard let encryptedData = userDefaults.data(forKey: "secure_\(key)") else {
            return nil
        }
        
        do {
            let decryptedData = try decryptData(encryptedData)
            return try JSONDecoder().decode(type, from: decryptedData)
        } catch {
            throw CacheError.decryptionFailed
        }
    }
    
    private func encryptData(_ data: Data) throws -> Data {
        // 簡易的な暗号化（実際のアプリではより強固な暗号化を使用）
        let key = "DontGoHomeStraight_Key_2025"
        let keyData = key.data(using: .utf8)!
        
        var encryptedData = Data()
        for i in 0..<data.count {
            let keyIndex = i % keyData.count
            let encryptedByte = data[i] ^ keyData[keyIndex]
            encryptedData.append(encryptedByte)
        }
        
        return encryptedData
    }
    
    private func decryptData(_ encryptedData: Data) throws -> Data {
        // 暗号化と同じ処理で復号化
        return try encryptData(encryptedData)
    }
}

// MARK: - Cache Statistics

extension CacheRepositoryImpl {
    
    /// キャッシュ統計の取得
    func getCacheStatistics() async -> CacheStatistics {
        let excludedCount = await getExcludedPlaceIds().count
        let mappingCount = getGenrePlaceMapping().count
        let memoryCount = memoryCache.countLimit
        
        return CacheStatistics(
            excludedPlacesCount: excludedCount,
            cachedMappingsCount: mappingCount,
            memoryCacheCount: memoryCount,
            lastCleanupDate: userDefaults.object(forKey: Keys.lastCleanupDate) as? Date
        )
    }
}

// MARK: - Cache Statistics Model

struct CacheStatistics {
    let excludedPlacesCount: Int
    let cachedMappingsCount: Int
    let memoryCacheCount: Int
    let lastCleanupDate: Date?
    
    var description: String {
        return """
        キャッシュ統計:
        - 除外スポット数: \(excludedPlacesCount)
        - キャッシュマッピング数: \(cachedMappingsCount)
        - メモリキャッシュ制限: \(memoryCacheCount)
        - 最後のクリーンアップ: \(lastCleanupDate?.formatted() ?? "未実行")
        """
    }
}