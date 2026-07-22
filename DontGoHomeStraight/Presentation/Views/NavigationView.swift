import SwiftUI
import MapKit

struct NavigationView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showingGoogleMapsAlert = false
    @State private var arrivalCheckTimer: Timer?
    @State private var timeElapsed = 0
    
    var body: some View {
        ZStack {
            LinearGradient.appBackgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー情報
                    headerSection
                    
                    // 経路情報
                    if let route = viewModel.currentRoute {
                        routeInfoCard(route)
                    }
                    
                    // 到着チェック状況
                    arrivalCheckCard
                    
                    // アクションボタン
                    actionButtons
                }
                .padding()
            }
        }
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
        VStack(spacing: 12) {
            Text("経路案内開始！")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "212529"))
            
            Text("Google Mapsアプリでナビゲーションが開始されます")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "6C757D"))
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private func routeInfoCard(_ route: NavigationRoute) -> some View {
        VStack(spacing: 16) {
            // 選択されたジャンル
            if let selectedGenre = viewModel.selectedGenre {
                VStack(alignment: .leading, spacing: 12) {
                    Text("選択した寄り道")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "6C757D"))
                    
                    HStack(spacing: 12) {
                        // マスクされたスポット名
                        Text("＊＊＊＊＊＊＊＊")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(Color(hex: "0D1B3A"))
                        
                        Spacer()
                        
                        Text(selectedGenre.category.displayName)
                            .font(.system(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedGenre.category == .restaurant ? Color(hex: "FFC107").opacity(0.18) : Color(hex: "3A7DFF").opacity(0.18))
                            .cornerRadius(4)
                    }
                    
                    if let hint = selectedGenre.hint {
                        Text("ヒント：" + hint)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "4B5563"))
                    }
                }
                .appCard()
            }
            
            // 経路詳細
            VStack(alignment: .leading, spacing: 12) {
                Text("経路情報")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "6C757D"))
                
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: route.transportMode.icon)
                            .foregroundColor(Color(hex: "3A7DFF"))
                            .frame(width: 20)
                        Text("移動手段")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "6C757D"))
                        Spacer()
                        Text(route.transportMode.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "212529"))
                    }
                    
                    if route.totalDistance > 0 {
                        HStack {
                            Image(systemName: "ruler")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            Text("総距離")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "6C757D"))
                            Spacer()
                            Text(route.formattedDistance)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "212529"))
                        }
                    }
                    
                    if route.estimatedDuration > 0 {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(Color(hex: "FFC107"))
                                .frame(width: 20)
                            Text("予想時間")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "6C757D"))
                            Spacer()
                            Text(route.formattedDuration)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "212529"))
                        }
                    }
                }
            }
            .appCard()
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
                        .background(selectedGenre.category == .restaurant ? Color.appAccent.opacity(0.18) : Color.appPrimary.opacity(0.18))
                        .cornerRadius(4)
                }
            }
            .appCard()
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
                    color: .appPrimary
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
                        color: .appAccent
                    )
                }
            }
        }
        .appCard()
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
    private var arrivalCheckCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(Color(hex: "3A7DFF"))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("🎯 到着をお待ちください")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "212529"))
                    
                    Text("経由地に近づくと自動で検知します")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "6C757D"))
                }
                
                Spacer()
            }
            
            // 経過時間
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(Color(hex: "6C757D"))
                
                Text("経過時間: \(formatElapsedTime(timeElapsed))")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6C757D"))
                
                Spacer()
            }
        }
        .padding(18)
        .background(Color(hex: "FFC107").opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "FFC107").opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                openGoogleMaps()
            }) {
                HStack {
                    Image(systemName: "map")
                    Text("Google Maps起動")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Button(action: {
                viewModel.navigateToHome()
            }) {
                Text("経路案内を終了")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
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
                // Live Activityの残り距離を更新
                let distance = waypoint.distance(from: currentLocation)
                viewModel.updateDetourLiveActivityDistance(distance)

                let isArrived = viewModel.checkArrival(
                    currentLocation: currentLocation,
                    waypoint: waypoint,
                    threshold: 100.0 // 100m以内で到着とみなす
                )

                if isArrived {
                    DispatchQueue.main.async {
                        viewModel.registerArrival(place: waypoint)
                        stopArrivalCheck()
                    }
                }
            }
        }
    }
    
    private func openGoogleMaps() {
        guard let route = viewModel.currentRoute,
              let finalDestination = viewModel.destination else { return }
        
        Task {
            do {
                // 経由地経由で最終目的地に向かうナビゲーション
                _ = try await viewModel.startNavigationWithRoute(
                    origin: route.origin,
                    destination: finalDestination.coordinate,  // 最終目的地を指定
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
                .tint(.appPrimary)
        }
        .padding()
        .background(Color.appSurfaceAlt)
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
