//
//  DontGoHomeStraightApp.swift
//  DontGoHomeStraight
//
//  Created by kazunori.sakata.ts on 2025/08/05.
//

import SwiftUI

@main
struct DontGoHomeStraightApp: App {
    
    init() {
        setupApp()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(.appPrimary)
                .background(Color.appBackground)
                .preferredColorScheme(.light) // ライトモード固定（オプション）
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
