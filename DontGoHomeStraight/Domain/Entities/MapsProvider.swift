import Foundation

/// 経路案内に使用する地図アプリの選択肢
enum MapsProvider: String, CaseIterable, Codable {
    case google
    case apple

    var displayName: String {
        switch self {
        case .google: return "Google Maps"
        case .apple: return "Apple Maps"
        }
    }

    var icon: String {
        switch self {
        case .google: return "map.fill"
        case .apple: return "map"
        }
    }
}

// MARK: - Preference Persistence

/// 前回選んだ地図アプリをUserDefaultsに記憶しておくヘルパー
/// （毎回選び直す手間を減らすため。デフォルトはGoogle Maps）
enum MapsProviderPreference {
    private static let key = "preferred_maps_provider"

    static func load(userDefaults: UserDefaults = .standard) -> MapsProvider {
        guard let raw = userDefaults.string(forKey: key),
              let provider = MapsProvider(rawValue: raw) else {
            return .google
        }
        return provider
    }

    static func save(_ provider: MapsProvider, userDefaults: UserDefaults = .standard) {
        userDefaults.set(provider.rawValue, forKey: key)
    }
}
