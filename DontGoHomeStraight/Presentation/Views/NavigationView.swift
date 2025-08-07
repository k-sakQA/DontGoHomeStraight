import SwiftUI
import MapKit

struct NavigationView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showingGoogleMapsAlert = false
    @State private var arrivalCheckTimer: Timer?
    @State private var timeElapsed = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // ヘッダー情報
            headerSection
            
            // 経路情報
            if let route = viewModel.currentRoute {
                routeInfoSection(route)
            }
            
            Spacer()
            
            // 到着チェック状況
            arrivalCheckSection
            
            // Google Maps起動ボタン
            googleMapsButton
            
            // ホームに戻るボタン
            homeButton
        }
        .padding()
        .navigationTitle("経路案内")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startArrivalCheck()
        }
        .onDisappear {
            stopArrivalCheck()
        }
        .alert("Google Mapsが見つかりません", isPresented: $showingGoogleMapsAlert) {
            Button("OK") { }
        } message: {
            Text("Google Mapsアプリがインストールされていません。App Storeからダウンロードしてください。")
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("🚀")
                .font(.system(size: 60))
            
            Text("経路案内開始！")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Google Mapsアプリで\nナビゲーションが開始されます")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private func routeInfoSection(_ route: NavigationRoute) -> some View {
        VStack(spacing: 16) {
            // 選択されたジャンル
            selectedGenreCard
            
            // 経路詳細
            routeDetailsCard(route)
        }
    }
    
    @ViewBuilder
    private var selectedGenreCard: some View {
        if let selectedGenre = viewModel.selectedGenre {
            VStack(spacing: 8) {
                HStack {
                    Text("選択ジャンル")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Text(selectedGenre.category.emoji)
                        .font(.title2)
                    
                    Text(selectedGenre.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(selectedGenre.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(selectedGenre.category == .restaurant ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private func routeDetailsCard(_ route: NavigationRoute) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("経路情報")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            VStack(spacing: 8) {
                routeDetailRow(
                    icon: "location.circle",
                    label: "移動手段",
                    value: route.transportMode.displayName,
                    color: .blue
                )
                
                if route.totalDistance > 0 {
                    routeDetailRow(
                        icon: "ruler",
                        label: "総距離",
                        value: route.formattedDistance,
                        color: .green
                    )
                }
                
                if route.estimatedDuration > 0 {
                    routeDetailRow(
                        icon: "clock",
                        label: "予想時間",
                        value: route.formattedDuration,
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func routeDetailRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    @ViewBuilder
    private var arrivalCheckSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("🎯 到着をお待ちください")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("経由地に近づくと自動で検知します")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 経過時間
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.secondary)
                
                Text("経過時間: \(formatElapsedTime(timeElapsed))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var googleMapsButton: some View {
        Button(action: {
            openGoogleMaps()
        }) {
            HStack {
                Image(systemName: "map")
                Text("Google Maps起動")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var homeButton: some View {
        Button(action: {
            viewModel.navigateToHome()
        }) {
            Text("経路案内を終了")
                .font(.subheadline)
                .foregroundColor(.red)
                .underline()
        }
    }
    
    // MARK: - Private Methods
    
    private func startArrivalCheck() {
        // 5秒間隔で到着チェック
        arrivalCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            checkArrival()
            timeElapsed += 5
        }
        
        // 1秒間隔で経過時間更新
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if arrivalCheckTimer == nil {
                timer.invalidate()
                return
            }
            timeElapsed += 1
        }
    }
    
    private func stopArrivalCheck() {
        arrivalCheckTimer?.invalidate()
        arrivalCheckTimer = nil
    }
    
    private func checkArrival() {
        guard let currentLocation = viewModel.currentLocation,
              let selectedGenre = viewModel.selectedGenre else {
            return
        }
        
        Task {
            if let waypoint = await viewModel.getWaypointForGenre(selectedGenre) {
                let isArrived = viewModel.checkArrival(
                    currentLocation: currentLocation,
                    waypoint: waypoint,
                    threshold: 100.0 // 100m以内で到着とみなす
                )
                
                if isArrived {
                    DispatchQueue.main.async {
                        viewModel.arrivedPlace = waypoint
                        viewModel.currentScreen = .arrival
                        stopArrivalCheck()
                    }
                }
            }
        }
    }
    
    private func openGoogleMaps() {
        guard let route = viewModel.currentRoute else { return }
        
        Task {
            do {
                _ = try await viewModel.startNavigationWithRoute(
                    origin: route.origin,
                    destination: route.destination,
                    selectedGenre: viewModel.selectedGenre!,
                    transportMode: route.transportMode
                )
            } catch {
                if error is LocationError {
                    showingGoogleMapsAlert = true
                }
            }
        }
    }
    
    private func formatElapsedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        
        if minutes > 0 {
            return "\(minutes)分\(remainingSeconds)秒"
        } else {
            return "\(remainingSeconds)秒"
        }
    }
}

// MARK: - Supporting Views

struct PulsingTargetView: View {
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 100, height: 100)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isPulsing)
            
            Circle()
                .fill(Color.blue)
                .frame(width: 20, height: 20)
            
            Image(systemName: "target")
                .font(.system(size: 12))
                .foregroundColor(.white)
        }
        .onAppear {
            isPulsing = true
        }
    }
}

struct LocationStatusIndicator: View {
    let isLocationAvailable: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isLocationAvailable ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(isLocationAvailable ? "位置情報取得中" : "位置情報なし")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct NavigationProgressView: View {
    let progress: Double // 0.0 to 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("進行状況")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            ProgressView(value: progress)
                .tint(.blue)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    SwiftUI.NavigationView {
        NavigationView(viewModel: {
            let vm = AppViewModel.preview
            vm.selectedGenre = Genre(name: "カフェ", category: .restaurant, googleMapType: "cafe")
            vm.currentRoute = NavigationRoute(
                origin: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
                destination: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917),
                waypoint: Place(
                    name: "秘密のカフェ",
                    coordinate: CLLocationCoordinate2D(latitude: 35.6850, longitude: 139.7500),
                    address: "東京都渋谷区",
                    genre: Genre(name: "カフェ", category: .restaurant, googleMapType: "cafe"),
                    placeId: "test_place_id"
                ),
                transportMode: .walking,
                totalDistance: 1500,
                estimatedDuration: 1200
            )
            return vm
        }())
    }
}

#Preview("No Route") {
    SwiftUI.NavigationView {
        NavigationView(viewModel: AppViewModel.preview)
    }
}