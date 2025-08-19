import SwiftUI
import CoreLocation

struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // アプリタイトル
                VStack(spacing: 16) {
                    Text("まっすぐ帰りたくない")
                        .font(AppFont.navigationTitle)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("今日は寄り道してみませんか？")
                        .font(AppFont.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // メインロゴ
                VStack(spacing: 20) {
                    LogoView(size: 120)
                    
                    Text("🗺️ 今日はどこへ？")
                        .font(AppFont.heading)
                        .foregroundColor(.brandPrimary)
                }
            
            Spacer()
            
            // 位置情報状態表示
            locationStatusView
            
            // メインボタン
            VStack(spacing: 16) {
                if viewModel.isLocationAvailable {
                    BrandButton.primary(
                        title: "目的地を設定する",
                        action: {
                            viewModel.navigateToDestinationSetting()
                        }
                    )
                    
                    // キャッシュ削除ボタン
                    BrandButton.secondary(
                        title: "キャッシュ削除",
                        isLoading: viewModel.isLoading,
                        isEnabled: !viewModel.isLoading,
                        action: {
                            Task {
                                await viewModel.clearRecommendationCache()
                            }
                        }
                    )
                } else {
                    BrandButton.primary(
                        title: "位置情報を許可する",
                        action: {
                            viewModel.requestLocationPermission()
                        }
                    )
                }
            }
            
            Spacer()
            }
            .padding()
        }
        .onAppear {
            viewModel.startLocationUpdates()
        }
    }
    
    @ViewBuilder
    private var locationStatusView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: locationStatusIcon)
                    .foregroundColor(locationStatusColor)
                Text(locationStatusText)
                    .font(AppFont.body)
                    .foregroundColor(.secondary)
            }
            
            if let currentLocation = viewModel.currentLocation {
                Text("現在地: \(formatCoordinate(currentLocation))")
                    .font(AppFont.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .appCard()
    }
    
    private var locationStatusIcon: String {
        switch viewModel.locationPermissionStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return viewModel.isLocationAvailable ? "location.fill" : "location"
        case .denied, .restricted:
            return "location.slash"
        case .notDetermined:
            return "location"
        @unknown default:
            return "location"
        }
    }
    
    private var locationStatusColor: Color {
        switch viewModel.locationPermissionStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return viewModel.isLocationAvailable ? .green : .orange
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .gray
        @unknown default:
            return .gray
        }
    }
    
    private var locationStatusText: String {
        switch viewModel.locationPermissionStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return viewModel.isLocationAvailable ? "位置情報取得中" : "位置情報を取得しています..."
        case .denied, .restricted:
            return "位置情報が拒否されています"
        case .notDetermined:
            return "位置情報の許可が必要です"
        @unknown default:
            return "位置情報の状態を確認中"
        }
    }
    
    private func formatCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        return String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }
}

// MARK: - Preview

#Preview {
    HomeView(viewModel: AppViewModel.preview)
}

// MARK: - Home View Specific Components

struct LocationPermissionGuideView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "info.circle")
                .font(.title)
                .foregroundColor(.brandPrimary)
            
            Text("位置情報について")
                .font(AppFont.heading)
                .foregroundColor(.primary)
            
            Text("現在地から目的地への最適な経由地を提案するために位置情報を使用します。")
                .font(AppFont.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .padding()
        .background(Color.brandPrimary20)
        .cornerRadius(12)
    }
}

struct AppFeatureView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.brandPrimary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.heading)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(AppFont.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.brandPrimary20)
        .cornerRadius(12)
    }
}

// MARK: - Extended Home View with Features

struct ExtendedHomeView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // メインセクション
                HomeView(viewModel: viewModel)
                
                // アプリの特徴紹介
                VStack(alignment: .leading, spacing: 16) {
                    Text("アプリの特徴")
                        .font(AppFont.heading)
                        .foregroundColor(.brandPrimary)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 12) {
                        AppFeatureView(
                            icon: "brain.head.profile",
            title: "寄り道を提案する",
                            description: "あなたの気分に合わせてAIが最適な経由地を提案"
                        )
                        
                        AppFeatureView(
                            icon: "eye.slash",
                            title: "サプライズ体験",
                            description: "到着するまでスポット名は秘密！ワクワクをお届け"
                        )
                        
                        AppFeatureView(
                            icon: "map",
                            title: "Google Maps連携",
                            description: "慣れ親しんだGoogle Mapsでスムーズにナビゲーション"
                        )
                    }
                    .padding(.horizontal)
                }
                
                // 位置情報ガイド
                LocationPermissionGuideView()
                    .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
        }
    }
}