import SwiftUI

struct GenreSelectionView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedGenre: Genre?
    @State private var flippedCardIds: Set<String> = []
    
    var body: some View {
        ZStack {
            LinearGradient.appBackgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // ローディング状態
                    if viewModel.isLoading {
                        loadingView
                    } else {
                        // ヘッダー情報
                        headerSection
                        
                        // 寄り道カード
                        genreCardsSection
                        
                        // ナビ開始について
                        navigationInfoCard
                    }
                }
                .padding()
            }
        }
        .navigationTitle("寄り道を選択")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
            
            Text("AIがあなたの気分に合った")
                .font(.headline)
            Text("素敵な寄り道先を探しています...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let mood = viewModel.selectedMood {
                MoodSummaryView(mood: mood)
            }
            
            Spacer()
        }
        .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    private var headerSection: some View {
        if !viewModel.recommendedGenres.isEmpty {
            VStack(spacing: 16) {
                Text("寄り道カードが届きました！")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "212529"))

                Text("カードをめくって、運命の寄り道を選ぼう")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6C757D"))
            }
        }
    }
    

    
    @ViewBuilder
    private var genreCardsSection: some View {
        if viewModel.recommendedGenres.isEmpty {
            emptyStateView
        } else {
            VStack(spacing: 16) {
                ForEach(Array(viewModel.recommendedGenres.prefix(3).enumerated()), id: \.element.id) { index, genre in
                    FlipCardView(
                        isFlipped: flippedCardIds.contains(genre.id),
                        onFlip: {
                            flippedCardIds.insert(genre.id)
                        },
                        front: {
                            ModernGenreCard(
                                genre: genre,
                                duration: estimatedDuration(for: genre),
                                onTap: {
                                    selectedGenre = genre
                                    viewModel.setSelectedGenre(genre)
                                    viewModel.navigateToNavigation()
                                }
                            )
                        },
                        back: {
                            DetourCardBack(index: index + 1)
                        }
                    )
                }
                // ネイティブ広告（アプリUIに溶け込むカード）
                sponsoredCard
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 14) {
                Text("🌙")
                    .font(.system(size: 52))

                Text("候補地がありません")
                    .font(.title3)
                    .fontWeight(.medium)

                Text("今日はまっすぐ帰りましょう🎵")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "212529"))
            }
            .frame(maxWidth: .infinity)
            .appCard()

            // まっすぐ帰る日も、ちょっとだけ楽しく
            TriviaCardView()

            Button("最初に戻る") {
                viewModel.navigateToHome()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var navigationInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ナビ開始について")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "6C757D"))
            
            Text("選択後は Google マップで経路案内へ。スポット名は伏せたまま、到着 50m 手前でアプリに戻って種明かしを表示します。")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "6C757D"))
                .lineSpacing(4)
        }
        .appCard()
    }
    
    private func estimatedDuration(for genre: Genre) -> String {
        // 実際の計算された時間を使用、ない場合はフォールバック値
        if let minutes = genre.durationMinutes {
            return "~\(minutes)分"
        }
        // フォールバック：ジャンルごとのデフォルト値
        switch genre.category {
        case .restaurant:
            return "~18分"
        case .other:
            return "~15分"
        }
    }
}

// MARK: - Sponsored Card

extension GenreSelectionView {
    @ViewBuilder
    var sponsoredCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("寄り道スポンサー")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "0D1B3A"))
                Spacer()
                Text("Ad")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.6))
                    .cornerRadius(6)
                    .accessibilityLabel("広告")
            }
            .padding(.bottom, 2)
            
            // AdMobポリシー準拠: 固定高さで表示
            NativeAdContainerView(adUnitId: Environment.adMobNativeAdUnitId)
                .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)  // 幅を最大化、高さ固定
                .clipped()  // はみ出し防止
                .cornerRadius(12)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color(hex: "EDF3FF"), Color(hex: "E6EEFF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 25, x: 0, y: 10)
    }
}

// MARK: - Raw Native Ad Section (no frame/background)

extension GenreSelectionView {
    @ViewBuilder
    var rawNativeAdSection: some View {
        if FeatureFlags.adsEnabled {
            #if canImport(GoogleMobileAds)
            AdMobNativeAdView(adUnitId: Environment.adMobNativeAdUnitId)
            #else
            EmptyView()
            #endif
        } else {
            EmptyView()
        }
    }
}

// MARK: - Modern Genre Card

struct ModernGenreCard: View {
    let genre: Genre
    let duration: String
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                // 時間バッジ
                Text(duration)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "3A7DFF"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .stroke(Color(hex: "DCE7FF"), lineWidth: 1)
                    )
                    .cornerRadius(999)
                
                // マスクされた名前
                Text("＊＊＊＊＊＊＊＊")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(Color(hex: "0D1B3A"))
                    .tracking(0.04)
                
                // ヒント
                Text("ヒント：" + (genre.hint ?? genre.description))
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "4B5563"))
                    .lineLimit(2)
            }
            
            Button(action: onTap) {
                Text("この寄り道を選ぶ")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color(hex: "EDF3FF"), Color(hex: "E6EEFF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 25, x: 0, y: 10)
    }
}

// MARK: - Genre Card

struct GenreCard: View {
    let genre: Genre
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // インデックス番号
                Text("\(index)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(circleColor)
                    .clipShape(Circle())
                
                // ジャンル情報
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(genre.category.emoji)
                            .font(.title2)
                        
                        Text(genre.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isSelected ? .appPrimary : .primary)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.appPrimary)
                                .font(.title2)
                        }
                    }
                    
                    Text(genre.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let hint = genre.hint, hint.isEmpty == false {
                        Text("ヒント：\(hint)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text(genre.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding()
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: isSelected ? 3 : 1)
            )
            .cornerRadius(16)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var circleColor: Color {
        switch genre.category {
        case .restaurant:
            return .appAccent
        case .other:
            return .appPrimary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.appPrimary.opacity(0.1)
        } else {
            return Color.appSurfaceAlt
        }
    }
    
    private var borderColor: Color {
        isSelected ? .appPrimary : .gray.opacity(0.3)
    }
}

// MARK: - Mood Summary View

struct MoodSummaryView: View {
    let mood: Mood
    
    var body: some View {
        HStack(spacing: 12) {
            Text(mood.activityType.emoji)
                .font(.title3)
            Text(mood.activityType.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("+")
                .foregroundColor(.secondary)
            
            Text(mood.vibeType.emoji)
                .font(.title3)
            Text(mood.vibeType.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color.appSurfaceAlt)
        .cornerRadius(8)
    }
}

// MARK: - Genre Extensions

extension Genre {
    var description: String {
        switch category {
        case .restaurant:
            return "美味しい食事や飲み物を楽しめる場所"
        case .other:
            switch name {
            case let n where n.contains("公園"):
                return "自然豊かでリラックスできる場所"
            case let n where n.contains("美術館"), let n where n.contains("博物館"):
                return "文化的な発見と学びがある場所"
            case let n where n.contains("図書館"):
                return "静かで知的な時間を過ごせる場所"
            case let n where n.contains("書店"):
                return "本との出会いが楽しめる場所"
            case let n where n.contains("ショッピング"):
                return "お買い物や散策が楽しめる場所"
            case let n where n.contains("神社"), let n where n.contains("寺院"):
                return "心を落ち着けることができる神聖な場所"
            case let n where n.contains("映画"):
                return "エンターテイメントを楽しめる場所"
            default:
                return "新しい発見や体験ができる場所"
            }
        }
    }
}

// MARK: - Enhanced Genre Card with Animation

struct EnhancedGenreCard: View {
    let genre: Genre
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // アニメーション付きインデックス
                ZStack {
                    Circle()
                        .fill(circleColor)
                        .frame(width: 50, height: 50)
                        .scaleEffect(isPressed ? 1.1 : 1.0)
                    
                    Text("\(index)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // ジャンル詳細
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(genre.category.emoji)
                            .font(.title2)
                        
                        Text(genre.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isSelected ? .appPrimary : .primary)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.appPrimary)
                                .font(.title2)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    Text(genre.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let hint = genre.hint, hint.isEmpty == false {
                        Text("ヒント：\(hint)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Text(genre.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            .padding()
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: isSelected ? 3 : 1)
            )
            .cornerRadius(16)
            .scaleEffect(isSelected ? 1.02 : (isPressed ? 0.98 : 1.0))
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var circleColor: Color {
        switch genre.category {
        case .restaurant:
            return .appAccent
        case .other:
            return .appPrimary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.appPrimary.opacity(0.12)
        } else {
            return Color.appSurfaceAlt
        }
    }
    
    private var borderColor: Color {
        isSelected ? .appPrimary : .gray.opacity(0.3)
    }
}

// MARK: - Preview

#Preview {
    SwiftUI.NavigationView {
        GenreSelectionView(viewModel: {
            let vm = AppViewModel.preview
            vm.recommendedGenres = [
                Genre(name: "カフェ", category: .restaurant, googleMapType: "cafe"),
                Genre(name: "公園", category: .other, googleMapType: "park"),
                Genre(name: "美術館", category: .other, googleMapType: "museum")
            ]
            return vm
        }())
    }
}

#Preview("Loading") {
    SwiftUI.NavigationView {
        GenreSelectionView(viewModel: {
            let vm = AppViewModel.preview
            vm.isLoading = true
            vm.selectedMood = Mood(activityType: .outdoor, vibeType: .exciting)
            return vm
        }())
    }
}

#Preview("Empty State") {
    SwiftUI.NavigationView {
        GenreSelectionView(viewModel: {
            let vm = AppViewModel.preview
            vm.recommendedGenres = []
            return vm
        }())
    }
}