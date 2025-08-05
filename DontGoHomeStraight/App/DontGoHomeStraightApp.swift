//
//  DontGoHomeStraightApp.swift
//  DontGoHomeStraight
//
//  Created by kazunori.sakata.ts on 2025/08/05.
//

import SwiftUI

@main
struct DontGoHomeStraightApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // アプリ起動時の初期設定
        print("まっすぐ帰りたくない - アプリ起動")
        print("設定: \(AppConfiguration.shared)")
    }
}
