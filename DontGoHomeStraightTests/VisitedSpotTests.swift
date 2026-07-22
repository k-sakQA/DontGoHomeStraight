import Testing
import Foundation
import CoreLocation
@testable import DontGoHomeStraight

struct VisitedSpotTests {

    private func makePlace(
        placeId: String = "test-place",
        rating: Double? = nil,
        reviews: Int? = nil
    ) -> Place {
        return Place(
            name: "テストスポット",
            coordinate: CLLocationCoordinate2D(latitude: 35.68, longitude: 139.76),
            address: "東京都千代田区",
            genre: Genre(name: "カフェ", category: .restaurant, googleMapType: "cafe"),
            rating: rating,
            placeId: placeId,
            userRatingsTotal: reviews
        )
    }

    // MARK: - Rarity

    @Test func 高評価かつ口コミが少ないスポットはシークレット() {
        #expect(SpotRarity.evaluate(rating: 4.6, reviewCount: 87) == .secret)
        #expect(SpotRarity.evaluate(rating: 4.4, reviewCount: 199) == .secret)
    }

    @Test func 高評価でも口コミが多いスポットはレア() {
        #expect(SpotRarity.evaluate(rating: 4.6, reviewCount: 5000) == .rare)
        #expect(SpotRarity.evaluate(rating: 4.0, reviewCount: 300) == .rare)
    }

    @Test func 評価が低いか不明なスポットは定番() {
        #expect(SpotRarity.evaluate(rating: 3.5, reviewCount: 10) == .standard)
        #expect(SpotRarity.evaluate(rating: nil, reviewCount: nil) == .standard)
    }

    @Test func 口コミ0件はシークレットにならない() {
        #expect(SpotRarity.evaluate(rating: 5.0, reviewCount: 0) == .rare)
    }

    // MARK: - Entity

    @Test func 訪問スポットはPlaceと気分から生成される() {
        let place = makePlace(rating: 4.5, reviews: 50)
        let mood = Mood(activityType: .indoor, vibeType: .jazzy)
        let spot = VisitedSpot(place: place, mood: mood)

        #expect(spot.id == place.placeId)
        #expect(spot.name == place.name)
        #expect(spot.rarity == .secret)
        #expect(spot.visitCount == 1)
        #expect(spot.moodDescription == mood.description)
    }

    // MARK: - Repository

    @Test func リポジトリは記録と再訪問カウントを行う() {
        let defaults = UserDefaults(suiteName: "VisitedSpotTests-\(UUID().uuidString)")!
        let repository = VisitedSpotRepositoryImpl(userDefaults: defaults)

        #expect(repository.getAll().isEmpty)

        // 初回訪問
        let first = repository.record(place: makePlace(placeId: "spot-a"), mood: nil)
        #expect(first.visitCount == 1)
        #expect(repository.getAll().count == 1)

        // 別スポット
        repository.record(place: makePlace(placeId: "spot-b"), mood: nil)
        #expect(repository.getAll().count == 2)

        // 再訪問はカウントが増え、件数は変わらない
        let revisited = repository.record(
            place: makePlace(placeId: "spot-a"),
            mood: Mood(activityType: .outdoor, vibeType: .discovery)
        )
        #expect(revisited.visitCount == 2)
        #expect(repository.getAll().count == 2)

        // クリア
        repository.clear()
        #expect(repository.getAll().isEmpty)
    }

    @Test func リポジトリは永続化される() {
        let suiteName = "VisitedSpotTests-persist-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let repository = VisitedSpotRepositoryImpl(userDefaults: defaults)
        repository.record(place: makePlace(placeId: "spot-p", rating: 4.8, reviews: 30), mood: nil)

        // 別インスタンスから読める
        let another = VisitedSpotRepositoryImpl(userDefaults: defaults)
        let loaded = another.getAll()
        #expect(loaded.count == 1)
        #expect(loaded[0].id == "spot-p")
        #expect(loaded[0].rarity == .secret)
    }
}

struct DetourTriviaTests {

    @Test func 豆知識は空でない() {
        #expect(!DetourTrivia.all.isEmpty)
        #expect(DetourTrivia.all.allSatisfy { !$0.isEmpty })
    }

    @Test func ランダム取得は現在表示中の豆知識を除外する() {
        let current = DetourTrivia.all[0]
        for _ in 0..<20 {
            #expect(DetourTrivia.random(excluding: current) != current)
        }
    }
}
