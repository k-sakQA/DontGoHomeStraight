import SwiftUI
import CoreLocation

struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var destinationText = ""
    @State private var selectedTransport: TransportMode = .driving
    @State private var selectedInOut: ActivityType = .indoor
    @State private var selectedVibe: VibeType = .discovery
    @State private var useAI = false
    
    // 住所候補表示用
    @State private var showingSuggestions = false
    @State private var addressSuggestions: [Place] = []
    @State private var isSearching = false
    
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
            viewModel.requestLocationPermission()
            viewModel.startLocationUpdates()
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        HStack(spacing: 16) {
            // ロゴ
            // 画面左上のロゴ（blueを使用、1.5倍 = 72pt -> 108pt）
            LogoView(size: 108, appearance: .light)
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
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "212529"))
                
                Text("寄り道先を探そう！")
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
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // 目的地
                VStack(alignment: .leading, spacing: 8) {
                    Text("目的地")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "6C757D"))
                    
                    VStack(alignment: .leading, spacing: 0) {
                        TextField(
                            "",
                            text: $destinationText
                        )
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(!viewModel.isLocationAvailable)
                        .overlay(
                            Group {
                                if destinationText.isEmpty {
                                    HStack {
                                        Text("例）新宿駅 ／ 住所を入力")
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                }
                            }
                        )
                        .onChange(of: destinationText) { newValue in
                            searchAddressSuggestions(for: newValue)
                        }
                        
                        // 候補リスト
                        if showingSuggestions && !addressSuggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(addressSuggestions.prefix(5), id: \.placeId) { place in
                                    Button(action: {
                                        #if DEBUG
                                        print("🔥 Button tapped for place: \(place.name)")
                                        #endif
                                        selectSuggestion(place)
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(place.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(Color(hex: "212529"))
                                            Text(place.address)
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(hex: "6C757D"))
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if place.placeId != addressSuggestions.prefix(5).last?.placeId {
                                        Divider()
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .zIndex(1000) // 他の要素より前面に表示
                        }
                    }
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
        .frame(maxWidth: .infinity)
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
            .buttonStyle(BlueButtonStyle())
            .disabled(!canStartJourney)
            .opacity(canStartJourney ? 1.0 : 0.6)
        }
        .appCard()
    }
    
    private var locationDisplayText: String {
        if viewModel.isLocationAvailable {
            if viewModel.currentLocation != nil {
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
        
        // すでに目的地が設定されている場合（候補から選択済み）はそのまま進む
        if viewModel.destination != nil {
            viewModel.setTransportMode(selectedTransport)
            viewModel.setMood(Mood(activityType: selectedInOut, vibeType: selectedVibe))
            
            if useAI {
                viewModel.navigateToGenreSelectionAI()
            } else {
                viewModel.navigateToGenreSelection()
            }
            return
        }
        
        // 候補から選択されていない場合は、Google Places APIで解決
        Task {
            if let place = await viewModel.resolveDestination(from: destinationText) {
                let destination = Destination(
                    name: place.name,
                    coordinate: place.coordinate,
                    address: place.address
                )
                viewModel.setDestination(destination)
                viewModel.setTransportMode(selectedTransport)
                viewModel.setMood(Mood(activityType: selectedInOut, vibeType: selectedVibe))
                if useAI {
                    viewModel.navigateToGenreSelectionAI()
                } else {
                    viewModel.navigateToGenreSelection()
                }
            } else {
                viewModel.showErrorMessage("目的地の座標を取得できませんでした。住所を確認してください。")
            }
        }
    }
    
    private func searchAddressSuggestions(for query: String) {
        #if DEBUG
        print("🔍 searchAddressSuggestions called with: \(query)")
        #endif
        
        // 空文字や短すぎる入力の場合は検索しない
        guard query.count >= 2 else {
            addressSuggestions = []
            showingSuggestions = false
            return
        }
        
        guard let currentLocation = viewModel.currentLocation else {
            #if DEBUG
            print("⚠️ Current location not available")
            #endif
            return
        }
        
        isSearching = true
        
        // Google Places APIを使って候補を検索
        Task {
            #if DEBUG
            print("🔍 Starting place search for: \(query)")
            #endif
            
            // 複数の候補を取得
            let places = await viewModel.searchDestinationCandidates(from: query)
            
            await MainActor.run {
                isSearching = false
                addressSuggestions = places
                showingSuggestions = !places.isEmpty
                #if DEBUG
                print("📍 Showing suggestions: \(showingSuggestions), count: \(places.count)")
                for place in places {
                    print("  - \(place.name): \(place.address)")
                }
                #endif
            }
        }
    }
    
    private func selectSuggestion(_ place: Place) {
        #if DEBUG
        print("🎯 selectSuggestion called with: \(place.name)")
        print("   Address: \(place.address)")
        print("   Coordinate: \(place.coordinate)")
        print("   PlaceId: \(place.placeId)")
        #endif
        
        destinationText = place.name
        showingSuggestions = false
        
        // 選択された場所を目的地として設定するだけ（ナビゲーションはしない）
        let destination = Destination(
            name: place.name,
            coordinate: place.coordinate,
            address: place.address
        )
        
        #if DEBUG
        print("✅ Selected suggestion: \(destination.name)")
        print("📝 Setting destination in viewModel (no navigation yet)")
        #endif
        
        viewModel.setDestination(destination)
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "E9EDF3"), lineWidth: 1)
                    )
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

// MARK: - CLPlacemark Extension

extension CLPlacemark {
    var formattedAddress: String? {
        guard let name = name else { return nil }
        
        var components: [String] = [name]
        
        if let thoroughfare = thoroughfare {
            components.append(thoroughfare)
        }
        
        if let locality = locality {
            components.append(locality)
        }
        
        if let administrativeArea = administrativeArea {
            components.append(administrativeArea)
        }
        
        if let country = country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
}
