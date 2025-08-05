import Foundation

enum Environment {
    enum Keys {
        static let openAIAPIKey = "OPENAI_API_KEY"
        static let googleMapsAPIKey = "GOOGLE_MAPS_API_KEY"
        static let googlePlacesAPIKey = "GOOGLE_PLACES_API_KEY"
    }
    
    static func value(for key: String) -> String {
        guard let value = Bundle.main.infoDictionary?[key] as? String else {
            #if DEBUG
            // 開発環境用のフォールバック
            switch key {
            case Keys.openAIAPIKey:
                return "sk-dev-openai-key"
            case Keys.googleMapsAPIKey:
                return "dev-google-maps-key"
            case Keys.googlePlacesAPIKey:
                return "dev-google-places-key"
            default:
                fatalError("環境変数 \(key) が設定されていません")
            }
            #else
            fatalError("環境変数 \(key) が設定されていません")
            #endif
        }
        return value
    }
    
    static var openAIAPIKey: String {
        return value(for: Keys.openAIAPIKey)
    }
    
    static var googleMapsAPIKey: String {
        return value(for: Keys.googleMapsAPIKey)
    }
    
    static var googlePlacesAPIKey: String {
        return value(for: Keys.googlePlacesAPIKey)
    }
}

enum BuildConfiguration {
    case debug
    case staging
    case release
    
    static var current: BuildConfiguration {
        #if DEBUG
        return .debug
        #elseif STAGING
        return .staging
        #else
        return .release
        #endif
    }
}

struct AppConfiguration {
    static let shared = AppConfiguration()
    
    let apiTimeout: TimeInterval
    let cacheSize: Int
    let logLevel: LogLevel
    let isAnalyticsEnabled: Bool
    let arrivalThreshold: Double // 到着判定の閾値（メートル）
    
    private init() {
        switch BuildConfiguration.current {
        case .debug:
            apiTimeout = 60.0
            cacheSize = 50 * 1024 * 1024 // 50MB
            logLevel = .debug
            isAnalyticsEnabled = false
            arrivalThreshold = 100.0 // デバッグ時は広めに設定
            
        case .staging:
            apiTimeout = 30.0
            cacheSize = 100 * 1024 * 1024 // 100MB
            logLevel = .info
            isAnalyticsEnabled = true
            arrivalThreshold = 75.0
            
        case .release:
            apiTimeout = 15.0
            cacheSize = 200 * 1024 * 1024 // 200MB
            logLevel = .warning
            isAnalyticsEnabled = true
            arrivalThreshold = 50.0
        }
    }
}

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}