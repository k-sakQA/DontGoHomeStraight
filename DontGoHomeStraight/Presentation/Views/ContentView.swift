//
//  ContentView.swift
//  DontGoHomeStraight
//
//  Created by kazunori.sakata.ts on 2025/08/05.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appViewModel = DependencyContainer.shared.appViewModel
    
    var body: some View {
        SwiftUI.NavigationView {
            ZStack {
                // メイン画面
                mainContent
                
                // エラー表示
                if appViewModel.showError {
                    errorOverlay
                }
                
                // ローディング表示
                if appViewModel.isLoading {
                    loadingOverlay
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // iPadでもスタック形式で表示
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch appViewModel.currentScreen {
        case .home:
            HomeView(viewModel: appViewModel)
        case .destinationSetting:
            DestinationSettingView(viewModel: appViewModel)
        case .transportModeSelection:
            TransportModeSelectionView(viewModel: appViewModel)
        case .moodSelection:
            MoodSelectionView(viewModel: appViewModel)
        case .genreSelection:
            GenreSelectionView(viewModel: appViewModel)
        case .navigation:
            DontGoHomeStraight.NavigationView(viewModel: appViewModel)
        case .arrival:
            ArrivalView(viewModel: appViewModel)
        }
    }
    
    @ViewBuilder
    private var errorOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text("エラーが発生しました")
                    .font(.headline)
                    .fontWeight(.bold)
                
                if let errorMessage = appViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button("OK") {
                    appViewModel.dismissError()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
        }
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                Text("処理中...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 5)
        }
    }
}

// MARK: - Content View Extensions

extension ContentView {
    
    /// デバッグ用の状態表示
    private var debugInfo: some View {
        #if DEBUG
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Screen: \(appViewModel.currentScreen.title)")
                    Text("Location: \(appViewModel.isLocationAvailable ? "✅" : "❌")")
                    if let destination = appViewModel.destination {
                        Text("Dest: \(destination.name)")
                    }
                    if let mood = appViewModel.selectedMood {
                        Text("Mood: \(mood.description)")
                    }
                }
                .font(.caption)
                .padding(8)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
        #else
        EmptyView()
        #endif
    }
}

// MARK: - Custom Navigation Wrapper

struct AppNavigationView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        SwiftUI.NavigationView {
            content
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Screen Transition Animations

extension AnyTransition {
    static var slideFromRight: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
    }
    
    static var slideFromLeft: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading),
            removal: .move(edge: .trailing)
        )
    }
    
    static var fadeScale: AnyTransition {
        .scale.combined(with: .opacity)
    }
}

// MARK: - Animated Content View

struct AnimatedContentView: View {
    @StateObject private var appViewModel = DependencyContainer.shared.appViewModel
    
    var body: some View {
        SwiftUI.NavigationView {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                // メインコンテンツ
                Group {
                    switch appViewModel.currentScreen {
                    case .home:
                        HomeView(viewModel: appViewModel)
                            .transition(.fadeScale)
                    case .destinationSetting:
                        DestinationSettingView(viewModel: appViewModel)
                            .transition(.slideFromRight)
                    case .transportModeSelection:
                        TransportModeSelectionView(viewModel: appViewModel)
                            .transition(.slideFromRight)
                    case .moodSelection:
                        MoodSelectionView(viewModel: appViewModel)
                            .transition(.slideFromRight)
                    case .genreSelection:
                        GenreSelectionView(viewModel: appViewModel)
                            .transition(.slideFromRight)
                    case .navigation:
                        DontGoHomeStraight.NavigationView(viewModel: appViewModel)
                            .transition(.fadeScale)
                    case .arrival:
                        ArrivalView(viewModel: appViewModel)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: appViewModel.currentScreen)
                
                // オーバーレイ
                if appViewModel.showError {
                    errorOverlay
                }
                
                if appViewModel.isLoading {
                    loadingOverlay
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    @ViewBuilder
    private var errorOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    appViewModel.dismissError()
                }
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                Text("エラーが発生しました")
                    .font(.headline)
                    .fontWeight(.bold)
                
                if let errorMessage = appViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button("OK") {
                    appViewModel.dismissError()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
            .transition(.scale.combined(with: .opacity))
        }
        .transition(.opacity)
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                Text("処理中...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
            .shadow(radius: 5)
        }
        .transition(.opacity)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

#Preview("Animated") {
    AnimatedContentView()
}
