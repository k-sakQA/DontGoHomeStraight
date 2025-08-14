import SwiftUI
import CoreLocation

struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // アプリタイトル
            VStack(spacing: 16) {
                Text("まっすぐ帰りたくない")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("今日は寄り道してみませんか？")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // メインアイコン
            VStack(spacing: 20) {
                Image(systemName: "map")
                    .font(.system(size: 80))
                    .foregroundColor(.appPrimary)
                
                Text("🗺️ 今日はどこへ？")
                    .font(.title2)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // 位置情報状態表示
            locationStatusView
            
            // メインボタン
            VStack(spacing: 16) {
                if viewModel.isLocationAvailable {
                    Button(action: {
                        viewModel.navigateToDestinationSetting()
                    }) {
                        HStack {
                            Image(systemName: "location")
                            Text("目的地を設定する")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appPrimary)
                        .cornerRadius(12)
                    }
                    
                    // キャッシュ削除ボタン
                    Button(action: {
                        Task {
                            await viewModel.clearRecommendationCache()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "trash")
                            }
                            Text("キャッシュ削除")
                        }
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(8)
                    }
                    .disabled(viewModel.isLoading)
                } else {
                    Button(action: {
                        viewModel.requestLocationPermission()
                    }) {
                        HStack {
                            Image(systemName: "location.slash")
                            Text("位置情報を許可する")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appAccent)
                        .cornerRadius(12)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
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
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let currentLocation = viewModel.currentLocation {
                Text("現在地: \(formatCoordinate(currentLocation))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.appSurfaceAlt)
        .cornerRadius(8)
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
                .foregroundColor(.appPrimary)
            
            Text("位置情報について")
                .font(.headline)
            
            Text("現在地から目的地への最適な経由地を提案するために位置情報を使用します。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .padding()
        .background(Color.appPrimary.opacity(0.1))
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
                .foregroundColor(.appPrimary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.appSurfaceAlt)
        .cornerRadius(8)
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
                        .font(.title3)
                        .fontWeight(.semibold)
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