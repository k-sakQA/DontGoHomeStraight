//
//  DontGoHomeStraightApp.swift
//  DontGoHomeStraight
//
//  Created by kazunori.sakata.ts on 2025/08/05.
//

import SwiftUI
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@main
struct DontGoHomeStraightApp: App {
    
    init() {
        setupApp()
    }
    
    var body: some Scene {
        WindowGroup {
            AnimatedContentView()
                .tint(.appPrimary)
                .background(Color.appBackground)
                // 必要に応じて固定ライトを外す/残す
                // .preferredColorScheme(.light)
        }
    }
    
    private func setupApp() {
        // アプリ起動時の初期設定
        #if DEBUG
        print("🚀 まっすぐ帰りたくない - アプリ起動")
        print("📱 Build Configuration: \(BuildConfiguration.current)")
        print("⚙️ App Configuration: API Timeout: \(AppConfiguration.shared.apiTimeout)s")
        print("📍 Arrival Threshold: \(AppConfiguration.shared.arrivalThreshold)m")
        #endif
        
        // 依存関係の初期化
        _ = DependencyContainer.shared
        
        #if DEBUG
        print("✅ Dependency Container initialized")
        #endif
        
        // Initialize AdMob
        if FeatureFlags.adsEnabled {
            #if canImport(GoogleMobileAds)
            let appId = Environment.adMobAppId
            if appId.isEmpty == false {
                MobileAds.shared.start(completionHandler: nil)
                #if DEBUG
                print("📣 AdMob initialized")
                // Using Google demo ad units, no test device IDs required on iOS 12+ SDK
                #endif
            }
            #endif
        }
    }
}

// MARK: - App Configuration Display

extension AppConfiguration: CustomStringConvertible {
    var description: String {
        return """
        AppConfiguration {
            apiTimeout: \(apiTimeout)s
            cacheSize: \(cacheSize / (1024 * 1024))MB
            logLevel: \(logLevel.rawValue)
            analytics: \(isAnalyticsEnabled)
            arrivalThreshold: \(arrivalThreshold)m
        }
        """
    }
}
