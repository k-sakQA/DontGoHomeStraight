import Foundation

class VisitedSpotRepositoryImpl: VisitedSpotRepository {
    private let userDefaults: UserDefaults

    private enum Keys {
        static let visitedSpots = "visited_spots_v1"
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func getAll() -> [VisitedSpot] {
        guard let data = userDefaults.data(forKey: Keys.visitedSpots) else { return [] }
        do {
            let spots = try JSONDecoder().decode([VisitedSpot].self, from: data)
            return spots.sorted { $0.lastVisitedAt > $1.lastVisitedAt }
        } catch {
            #if DEBUG
            print("❌ 図鑑データのデコードに失敗: \(error)")
            #endif
            return []
        }
    }

    @discardableResult
    func record(place: Place, mood: Mood?) -> VisitedSpot {
        var spots = getAll()

        if let index = spots.firstIndex(where: { $0.id == place.placeId }) {
            var existing = spots[index]
            existing.visitCount += 1
            existing.lastVisitedAt = Date()
            existing.moodDescription = mood?.description ?? existing.moodDescription
            spots[index] = existing
            save(spots)
            return existing
        }

        let newSpot = VisitedSpot(place: place, mood: mood)
        spots.insert(newSpot, at: 0)
        save(spots)
        return newSpot
    }

    func clear() {
        userDefaults.removeObject(forKey: Keys.visitedSpots)
    }

    private func save(_ spots: [VisitedSpot]) {
        do {
            let data = try JSONEncoder().encode(spots)
            userDefaults.set(data, forKey: Keys.visitedSpots)
        } catch {
            #if DEBUG
            print("❌ 図鑑データの保存に失敗: \(error)")
            #endif
        }
    }
}
