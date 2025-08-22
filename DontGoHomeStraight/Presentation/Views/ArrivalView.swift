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
                    // スポット情報の表示
                    if let arrivedPlace = viewModel.arrivedPlace {
                        spotRevealCard(arrivedPlace)
                    }
                    
                    // アクションボタン
                    actionButtons
                }
                .padding()
            }
        }
        .navigationTitle("スポットに到着")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startRevealAnimation()
        }
    }
    

    
    @ViewBuilder
    private func spotRevealCard(_ place: Place) -> some View {
        VStack(spacing: 16) {
            // ヒーロー画像セクション
            heroImageSection(place)
            
            // スポット情報
            spotInfoSection(place)
            
            // 説明文
            descriptionSection(place)
        }
        .appCard()
        .opacity(revealAnimation ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.8).delay(0.3), value: revealAnimation)
    }
    
    @ViewBuilder
    private func heroImageSection(_ place: Place) -> some View {
        ZStack {
            // プレースホルダー背景
            RoundedRectangle(cornerRadius: 22)
                .fill(place.genre.category == .restaurant ? Color(hex: "FFC107").opacity(0.3) : Color(hex: "C5D9FF"))
                .frame(height: 240)
            
            // 写真またはプレースホルダー
            if let photoReference = place.photoReference,
               let photoURL = viewModel.getPhotoURL(photoReference: photoReference, maxWidth: 400) {
                AsyncImage(url: photoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 240)
                        .clipped()
                        .cornerRadius(22)
                } placeholder: {
                    // ローディング中のプレースホルダー
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("写真を読み込み中...")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            } else {
                // 写真がない場合のプレースホルダー
                VStack {
                    Spacer()
                    Text(place.genre.category.emoji)
                        .font(.system(size: 80))
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    private func spotInfoSection(_ place: Place) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ここは「\(place.name)」でした！")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "212529"))
            
            HStack(spacing: 12) {
                Text(place.genre.name)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6C757D"))
                
                if let rating = place.rating, rating > 0 {
                    Text("評価 \(place.displayRating)")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "6C757D"))
                }
                
                if place.isOpen == true {
                    Text("屋外")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "6C757D"))
                }
            }
        }
    }
    
    @ViewBuilder
    private func descriptionSection(_ place: Place) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(getPlaceDescription(place))
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "6C757D"))
                .lineSpacing(4)
        }
    }
    

    

    
    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: {
                // シェア機能（後で実装）
            }) {
                Text("思い出をシェア")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Button(action: {
                viewModel.navigateToLanding()
            }) {
                Text("もう一度提案を受ける")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }
    
    private func getPlaceDescription(_ place: Place) -> String {
        switch place.genre.category {
        case .restaurant:
            if place.genre.name.contains("カフェ") {
                return "美味しいコーヒーと落ち着いた雰囲気。寄り道の疲れをリフレッシュするひとときを。"
            } else {
                return "地元の人々に愛されるグルメスポット。新しい味覚の発見を楽しんでください。"
            }
        case .other:
            if place.genre.name.contains("公園") {
                return "自然豊かでリラックスできる場所。歩き疲れた足を休めて、季節の風景を楽しんでみてはいかがでしょうか。"
            } else if place.genre.name.contains("美術館") || place.genre.name.contains("博物館") {
                return "文化的な発見と学びがある場所。静かな空間でアートや歴史に触れる特別な時間を。"
            } else {
                return "地元の人々に愛される特別な場所。新しい発見や体験があなたを待っています。"
            }
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