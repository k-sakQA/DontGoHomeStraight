import SwiftUI
import CoreLocation

struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var destinationText = ""
    @State private var selectedTransport: TransportMode = .driving
    @State private var selectedInOut: ActivityType = .indoor
    @State private var selectedVibe: VibeType = .discovery
    @State private var useAI = false
    
    var body: some View {
        ZStack {
            LinearGradient.appBackgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // ヘッダー
                    headerSection
                    
                    // フォームカード
                    VStack(spacing: 16) {
                        // 現在地・目的地カード
                        locationCard
                        
                        // 設定カード
                        settingsCard
                    }
                    
                    // 提案エンジンカード
                    engineCard
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.startLocationUpdates()
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: 16) {
            // ロゴ
            LogoView(size: 44)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "3A7DFF"), Color(hex: "6AA9FF")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("まっすぐ帰りたくない")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "212529"))
                
                Text("今日は寄り道してみませんか？")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6C757D"))
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var locationCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 12) {
                // 現在地
                VStack(alignment: .leading, spacing: 8) {
                    Text("現在地")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "6C757D"))
                    
                    HStack {
                        TextField(
                            "位置情報を取得中...",
                            text: .constant(locationDisplayText)
                        )
                        .disabled(true)
                        .textFieldStyle(ModernTextFieldStyle())
                    }
                }
                
                // 目的地
                VStack(alignment: .leading, spacing: 8) {
                    Text("目的地")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "6C757D"))
                    
                    TextField(
                        "例）長野駅 ／ 住所を入力",
                        text: $destinationText
                    )
                    .textFieldStyle(ModernTextFieldStyle())
                    .disabled(!viewModel.isLocationAvailable)
                }
            }
        }
        .appCard()
    }
    
    @ViewBuilder
    private var settingsCard: some View {
        VStack(spacing: 16) {
            // 移動手段
            VStack(alignment: .leading, spacing: 8) {
                Text("移動手段")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "6C757D"))
                
                HStack(spacing: 10) {
                    ForEach(TransportMode.allCases, id: \.self) { mode in
                        Button(action: { selectedTransport = mode }) {
                            Text(mode.displayName)
                        }
                        .buttonStyle(ChipStyle(isSelected: selectedTransport == mode))
                    }
                }
            }
            
            // 屋内・屋外
            VStack(alignment: .leading, spacing: 8) {
                Text("屋内 / 屋外")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "6C757D"))
                
                HStack(spacing: 10) {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        Button(action: { selectedInOut = type }) {
                            Text(type.displayName)
                        }
                        .buttonStyle(ChipStyle(isSelected: selectedInOut == type))
                    }
                }
            }
            
            // 気分
            VStack(alignment: .leading, spacing: 8) {
                Text("気分")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "6C757D"))
                
                HStack(spacing: 10) {
                    ForEach(VibeType.allCases, id: \.self) { vibe in
                        Button(action: { selectedVibe = vibe }) {
                            Text(vibe.displayName)
                        }
                        .buttonStyle(ChipStyle(isSelected: selectedVibe == vibe))
                    }
                }
            }
        }
        .appCard()
    }
    
    @ViewBuilder
    private var engineCard: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("提案エンジン")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "6C757D"))
                
                Menu {
                    Button("Google Maps API") { useAI = false }
                    Button("AI") { useAI = true }
                } label: {
                    HStack {
                        Text(useAI ? "AI" : "Google Maps API")
                            .foregroundColor(Color(hex: "212529"))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(Color(hex: "6C757D"))
                    }
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "E9EDF3"), lineWidth: 1)
                    )
                }
            }
            
            // メインボタン
            Button(action: startJourney) {
                Text("寄り道を3つ提案する")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BluePrimaryButtonStyle())
            .disabled(!canStartJourney)
        }
        .appCard()
    }
    
    private var locationDisplayText: String {
        if viewModel.isLocationAvailable {
            if let location = viewModel.currentLocation {
                return "現在地（取得済み）"
            }
            return "位置情報を取得中..."
        } else {
            return "位置情報が利用できません"
        }
    }
    
    private var canStartJourney: Bool {
        viewModel.isLocationAvailable && !destinationText.isEmpty
    }
    
    private func startJourney() {
        guard canStartJourney else { return }
        
        // 入力文字列をジオコーディングして正確な緯度経度を取得
        let query = destinationText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.isEmpty == false else { return }
        let geocoder = CLGeocoder()
        viewModel.isLoading = true
        geocoder.geocodeAddressString(query) { placemarks, error in
            DispatchQueue.main.async {
                self.viewModel.isLoading = false
                if let loc = placemarks?.first?.location {
                    let coordinate = loc.coordinate
                    let address = placemarks?.first?.name ?? query
                    let dest = Destination(
                        name: query,
                        coordinate: coordinate,
                        address: address
                    )
                    self.viewModel.setDestination(dest)
                    self.viewModel.setTransportMode(self.selectedTransport)
                    self.viewModel.setMood(Mood(activityType: self.selectedInOut, vibeType: self.selectedVibe))
                    if self.useAI {
                        self.viewModel.navigateToGenreSelectionAI()
                    } else {
                        self.viewModel.navigateToGenreSelection()
                    }
                } else {
                    self.viewModel.showErrorMessage("目的地を特定できませんでした")
                }
            }
        }
    }
    
    private func formatCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        return String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
    }
}

// MARK: - Modern Text Field Style

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "E9EDF3"), lineWidth: 1)
            )
            .font(.system(size: 16))
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