import Foundation

struct Mood {
    let activityType: ActivityType
    let vibeType: VibeType
    
    init(activityType: ActivityType, vibeType: VibeType) {
        self.activityType = activityType
        self.vibeType = vibeType
    }
    
    var description: String {
        return "\(activityType.displayName) + \(vibeType.displayName)"
    }
}

enum ActivityType: String, CaseIterable {
    case indoor = "indoor"
    case outdoor = "outdoor"
    
    var displayName: String {
        switch self {
        case .indoor: return "インドア"
        case .outdoor: return "アウトドア"
        }
    }
    
    var emoji: String {
        switch self {
        case .indoor: return "🏠"
        case .outdoor: return "🌳"
        }
    }
}

enum VibeType: String, CaseIterable {
    case jazzy = "jazzy"
    case discovery = "discovery"
    case exciting = "exciting"
    
    var displayName: String {
        switch self {
        case .jazzy: return "Jazzy"
        case .discovery: return "発見！"
        case .exciting: return "ワクワク"
        }
    }
    
    var emoji: String {
        switch self {
        case .jazzy: return "🎷"
        case .discovery: return "🔍"
        case .exciting: return "✨"
        }
    }
}

// MARK: - Equatable
extension Mood: Equatable {
    static func == (lhs: Mood, rhs: Mood) -> Bool {
        return lhs.activityType == rhs.activityType && lhs.vibeType == rhs.vibeType
    }
}

// MARK: - Codable
extension Mood: Codable {}
extension ActivityType: Codable {}
extension VibeType: Codable {}

// MARK: - Validation
extension Mood {
    static func isValidCombination(activityType: ActivityType, vibeType: VibeType) -> Bool {
        // 現在は全ての組み合わせが有効
        // 将来的に特定の組み合わせを無効にする場合はここで制御
        return true
    }
}