import SwiftUI
import MapKit

struct ArrivalView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var showConfetti = false
    @State private var revealAnimation = false
    
    var body: some View {
        ZStack {
            LinearGradient.appBackgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 到着お祝いセクション
                    celebrationSection
                    
                    // スポット情報の表示
                    if let arrivedPlace = viewModel.arrivedPlace {
                        spotRevealSection(arrivedPlace)
                    }
                    
                    // 完了ボタン
                    completionButton
                }
                .padding()
            }
        }
        .navigationTitle("到着！")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startRevealAnimation()
        }
    }
    
    @ViewBuilder
    private var celebrationSection: some View {
        VStack(spacing: 20) {
            // アニメーション付きお祝いアイコン
            ZStack {
                if showConfetti {
                    ConfettiView()
                }
                
                Text("🎉")
                    .font(.system(size: 80))
                    .scaleEffect(revealAnimation ? 1.2 : 1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: revealAnimation)
            }
            
            VStack(spacing: 8) {
                Text("到着しました！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.appPrimary)
                
                Text("お疲れさまでした")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .opacity(revealAnimation ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.8).delay(0.3), value: revealAnimation)
        }
    }
    
    @ViewBuilder
    private func spotRevealSection(_ place: Place) -> some View {
        VStack(spacing: 20) {
            // 「今回の寄り道先は」メッセージ
            revealMessageSection
            
            // スポット詳細カード
            spotDetailCard(place)
            
            // 追加情報
            if let route = viewModel.currentRoute {
                journeySummaryCard(route)
            }
            
            // 励ましメッセージ
            encouragementSection
        }
        .opacity(revealAnimation ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 1.0).delay(0.6), value: revealAnimation)
    }
    
    @ViewBuilder
    private var revealMessageSection: some View {
        VStack(spacing: 8) {
            Text("今回の寄り道先は")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("✨ 秘密の場所が明らかに！ ✨")
                .font(.subheadline)
                .foregroundColor(.orange)
                .fontWeight(.semibold)
        }
        .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    private func spotDetailCard(_ place: Place) -> some View {
        VStack(spacing: 16) {
            // スポット名（メインの発表）
            VStack(spacing: 8) {
                Text(place.genre.category.emoji)
                    .font(.system(size: 40))
                
                Text(place.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                if !place.address.isEmpty {
                    Text(place.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                place.genre.category == .restaurant ? Color.appAccent.opacity(0.12) : Color.appPrimary.opacity(0.10),
                                place.genre.category == .restaurant ? Color.red.opacity(0.10) : Color.appAccent.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(place.genre.category == .restaurant ? Color.appAccent : Color.appPrimary, lineWidth: 2)
                    )
            )
            
            // スポット詳細情報
            spotDetailsGrid(place)
        }
    }
    
    @ViewBuilder
    private func spotDetailsGrid(_ place: Place) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            spotDetailItem(
                icon: "tag.fill",
                label: "ジャンル",
                value: place.genre.name,
                color: .appPrimary
            )
            
            spotDetailItem(
                icon: "star.fill",
                label: "評価",
                value: place.displayRating,
                color: .yellow
            )
            
            if let priceLevel = place.priceLevel, priceLevel > 0 {
                spotDetailItem(
                    icon: "yensign.circle.fill",
                    label: "価格帯",
                    value: place.displayPriceLevel,
                    color: .green
                )
            }
            
            spotDetailItem(
                icon: "clock.fill",
                label: "営業状況",
                value: place.openStatusText,
                color: place.isOpen == true ? .green : .red
            )
        }
    }
    
    @ViewBuilder
    private func spotDetailItem(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .appCard()
    }
    
    @ViewBuilder
    private func journeySummaryCard(_ route: NavigationRoute) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("今回の旅の記録")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                journeyDetailRow(
                    icon: "figure.walk",
                    label: "移動手段",
                    value: route.transportMode.displayName
                )
                
                if route.totalDistance > 0 {
                    journeyDetailRow(
                        icon: "ruler",
                        label: "移動距離",
                        value: route.formattedDistance
                    )
                }
                
                if let mood = viewModel.selectedMood {
                    journeyDetailRow(
                        icon: "heart.fill",
                        label: "選んだ気分",
                        value: mood.description
                    )
                }
            }
        }
        .appCard()
    }
    
    @ViewBuilder
    private func journeyDetailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.appPrimary)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var encouragementSection: some View {
        VStack(spacing: 12) {
            Text("🌟 素敵な寄り道を！ 🌟")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.appAccent)
            
            Text("新しい発見はありましたか？\nまた次回もお楽しみください。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding()
        .background(Color.appAccent.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appAccent.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var completionButton: some View {
        VStack(spacing: 16) {
            Button(action: {
                viewModel.navigateToHome()
            }) {
                HStack {
                    Image(systemName: "house.fill")
                    Text("完了")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Text("お疲れさまでした！\nまた新しい寄り道をお楽しみください。")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Private Methods
    
    private func startRevealAnimation() {
        withAnimation(.easeInOut(duration: 0.5)) {
            revealAnimation = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showConfetti = true
        }
    }
}

// MARK: - Confetti Animation

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50, id: \.self) { index in
                ConfettiPiece()
                    .offset(
                        x: animate ? CGFloat.random(in: -200...200) : 0,
                        y: animate ? CGFloat.random(in: -300...100) : -50
                    )
                    .opacity(animate ? 0 : 1)
                    .rotationEffect(.degrees(animate ? Double.random(in: 0...360) : 0))
                    .animation(
                        .easeOut(duration: Double.random(in: 1...3))
                        .delay(Double.random(in: 0...0.5)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    private let color: Color
    private let size: CGFloat
    
    init() {
        self.color = colors.randomElement() ?? .appPrimary
        self.size = CGFloat.random(in: 4...8)
    }
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

// MARK: - Animated Reveal Card

struct AnimatedRevealCard: View {
    let place: Place
    @State private var isRevealed = false
    
    var body: some View {
        ZStack {
            // 裏面（秘密カード）
            VStack {
                Image(systemName: "questionmark")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("秘密の場所")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(Color.appSurfaceAlt)
            .cornerRadius(16)
            .rotation3DEffect(
                .degrees(isRevealed ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .opacity(isRevealed ? 0 : 1)
            
            // 表面（実際のスポット情報）
            VStack(spacing: 12) {
                Text(place.genre.category.emoji)
                    .font(.system(size: 40))
                
                Text(place.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(place.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 150)
            .background(Color.appPrimary.opacity(0.1))
            .cornerRadius(16)
            .rotation3DEffect(
                .degrees(isRevealed ? 0 : 180),
                axis: (x: 0, y: 1, z: 0)
            )
            .opacity(isRevealed ? 1 : 0)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    isRevealed = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SwiftUI.NavigationView {
        ArrivalView(viewModel: {
            let vm = AppViewModel.preview
            vm.arrivedPlace = Place(
                name: "スターバックス コーヒー 渋谷スカイ店",
                coordinate: CLLocationCoordinate2D(latitude: 35.6580, longitude: 139.7016),
                address: "東京都渋谷区渋谷2-24-12",
                genre: Genre(name: "カフェ", category: .restaurant, googleMapType: "cafe"),
                rating: 4.2,
                priceLevel: 2,
                isOpen: true,
                placeId: "ChIJ..."
            )
            vm.selectedMood = Mood(activityType: .outdoor, vibeType: .exciting)
            vm.currentRoute = NavigationRoute(
                origin: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
                destination: CLLocationCoordinate2D(latitude: 35.6895, longitude: 139.6917),
                waypoint: vm.arrivedPlace!,
                transportMode: .walking,
                totalDistance: 1500,
                estimatedDuration: 1200
            )
            return vm
        }())
    }
}

#Preview("Museum") {
    SwiftUI.NavigationView {
        ArrivalView(viewModel: {
            let vm = AppViewModel.preview
            vm.arrivedPlace = Place(
                name: "東京国立博物館",
                coordinate: CLLocationCoordinate2D(latitude: 35.7188, longitude: 139.7763),
                address: "東京都台東区上野公園13-9",
                genre: Genre(name: "美術館・博物館", category: .other, googleMapType: "museum"),
                rating: 4.5,
                isOpen: true,
                placeId: "ChIJ..."
            )
            vm.selectedMood = Mood(activityType: .indoor, vibeType: .discovery)
            return vm
        }())
    }
}