import Foundation

enum Environment {
    enum Keys {
        static let openAIAPIKey = "OPENAI_API_KEY"
        static let googlePlacesAPIKey = "GOOGLE_PLACES_API_KEY"
        static let adMobAppId = "ADMOB_APP_ID"
        static let adMobNativeAdUnitId = "ADMOB_NATIVE_AD_UNIT_ID"
    }
    
    static func value(for key: String) -> String {
        // まず設定ファイルから読み込みを試行
        if let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let configDict = NSDictionary(contentsOfFile: configPath),
           let value = configDict[key] as? String,
           !value.isEmpty && !value.hasPrefix("YOUR_") {
            return value
        }
        
        // 次にInfo.plistから読み込み（環境変数形式）
        if let value = Bundle.main.infoDictionary?[key] as? String,
           !value.isEmpty && !value.hasPrefix("$(") {
            return value
        }
        
        #if DEBUG
        // 開発環境用のフォールバック
        print("⚠️ APIキー '\(key)' が設定されていません。Config.plistファイルを確認してください。")
        switch key {
        case Keys.openAIAPIKey:
            return "sk-dev-openai-key"
        case Keys.googlePlacesAPIKey:
            return "dev-google-places-key"
        case Keys.adMobAppId:
            // Google sample AdMob App ID
            return "ca-app-pub-3940256099942544~1458002511"
        case Keys.adMobNativeAdUnitId:
            // Google sample Native Advanced Ad Unit ID
            return "ca-app-pub-3940256099942544/3986624511"
        default:
            fatalError("環境変数 \(key) が設定されていません")
        }
        #else
        fatalError("環境変数 \(key) が設定されていません。本番環境ではAPIキーが必要です。")
        #endif
    }
    
    static var openAIAPIKey: String {
        return value(for: Keys.openAIAPIKey)
    }
    
    static var googlePlacesAPIKey: String {
        return value(for: Keys.googlePlacesAPIKey)
    }
    
    static var adMobAppId: String {
        return value(for: Keys.adMobAppId)
    }
    
    static var adMobNativeAdUnitId: String {
        return value(for: Keys.adMobNativeAdUnitId)
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