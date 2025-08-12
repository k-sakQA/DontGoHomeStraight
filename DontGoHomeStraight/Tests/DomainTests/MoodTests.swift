// #if canImport(XCTest)
import XCTest
@testable import DontGoHomeStraight

final class MoodTests: XCTestCase {
    
    // MARK: - Test Mood Creation
    
    func test_気分の作成_正常ケース() {
        // Given
        let activityType = ActivityType.outdoor
        let vibeType = VibeType.exciting
        
        // When
        let mood = Mood(activityType: activityType, vibeType: vibeType)
        
        // Then
        XCTAssertEqual(mood.activityType, .outdoor)
        XCTAssertEqual(mood.vibeType, .exciting)
        XCTAssertEqual(mood.description, "アウトドア + ワクワク")
    }
    
    // MARK: - Test ActivityType
    
    func test_アクティビティタイプ_表示名() {
        // Given & When & Then
        XCTAssertEqual(ActivityType.indoor.displayName, "インドア")
        XCTAssertEqual(ActivityType.outdoor.displayName, "アウトドア")
    }
    
    func test_アクティビティタイプ_絵文字() {
        // Given & When & Then
        XCTAssertEqual(ActivityType.indoor.emoji, "🏠")
        XCTAssertEqual(ActivityType.outdoor.emoji, "🌳")
    }
    
    // MARK: - Test VibeType
    
    func test_バイブタイプ_表示名() {
        // Given & When & Then
        XCTAssertEqual(VibeType.jazzy.displayName, "Jazzy")
        XCTAssertEqual(VibeType.discovery.displayName, "発見！")
        XCTAssertEqual(VibeType.exciting.displayName, "ワクワク")
    }
    
    func test_バイブタイプ_絵文字() {
        // Given & When & Then
        XCTAssertEqual(VibeType.jazzy.emoji, "🎷")
        XCTAssertEqual(VibeType.discovery.emoji, "🔍")
        XCTAssertEqual(VibeType.exciting.emoji, "✨")
    }
    
    // MARK: - Test Mood Validation
    
    func test_気分の組み合わせ検証_全パターンが有効() {
        // Given
        let activityTypes = ActivityType.allCases
        let vibeTypes = VibeType.allCases
        
        // When & Then
        for activityType in activityTypes {
            for vibeType in vibeTypes {
                let isValid = Mood.isValidCombination(activityType: activityType, vibeType: vibeType)
                XCTAssertTrue(isValid, "\(activityType) + \(vibeType) の組み合わせが無効です")
            }
        }
    }
    
    // MARK: - Test Mood Equality
    
    func test_気分の等価性_同じ組み合わせ() {
        // Given
        let mood1 = Mood(activityType: .indoor, vibeType: .jazzy)
        let mood2 = Mood(activityType: .indoor, vibeType: .jazzy)
        
        // When & Then
        XCTAssertEqual(mood1, mood2)
    }
    
    func test_気分の等価性_異なる組み合わせ() {
        // Given
        let mood1 = Mood(activityType: .indoor, vibeType: .jazzy)
        let mood2 = Mood(activityType: .outdoor, vibeType: .exciting)
        
        // When & Then
        XCTAssertNotEqual(mood1, mood2)
    }
    
    // MARK: - Test Codable
    
    func test_気分のエンコード_デコード() throws {
        // Given
        let originalMood = Mood(activityType: .outdoor, vibeType: .discovery)
        
        // When
        let encodedData = try JSONEncoder().encode(originalMood)
        let decodedMood = try JSONDecoder().decode(Mood.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalMood, decodedMood)
    }
}
// #endif