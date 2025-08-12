import SwiftUI

struct GenreSelectionView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedGenre: Genre?
    
    var body: some View {
        VStack(spacing: 24) {
            // ローディング状態
            if viewModel.isLoading {
                loadingView
            } else {
                // ヘッダー情報
                headerSection
                
                // ジャンル選択
                genreSelectionSection
                
                Spacer()
                
                // ナビゲーションボタン
                navigationButton
            }
        }
        .padding()
        .navigationTitle("どのジャンルにする？")
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
        VStack(spacing: 16) {
            Text("🎯")
                .font(.system(size: 50))
            
            Text("寄り道の提案ができました！")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("どのジャンルの場所に寄り道しますか？")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // 重要な注意事項
            importantNoticeView
        }
    }
    
    @ViewBuilder
    private var importantNoticeView: some View {
        HStack(spacing: 8) {
            Image(systemName: "eye.slash.fill")
                .foregroundColor(.orange)
            
            Text("※スポット名は到着まで秘密！")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var genreSelectionSection: some View {
        if viewModel.recommendedGenres.isEmpty {
            emptyStateView
        } else {
            VStack(spacing: 16) {
                ForEach(Array(viewModel.recommendedGenres.enumerated()), id: \.element.id) { index, genre in
                    GenreCard(
                        genre: genre,
                        index: index + 1,
                        isSelected: selectedGenre?.id == genre.id,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedGenre = genre
                            }
                        }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("候補地がありません")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("今日はまっすぐ帰りましょう🎵")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("最初に戻る") {
                viewModel.navigateToHome()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    @ViewBuilder
    private var navigationButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                guard let selectedGenre = selectedGenre else { return }
                viewModel.setSelectedGenre(selectedGenre)
                viewModel.navigateToNavigation()
            }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("ここに決定！")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedGenre != nil ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(selectedGenre == nil)
            
            Text("選択したジャンルの場所へ\nGoogle Mapsでナビゲーションを開始します")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
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
                            .foregroundColor(isSelected ? .blue : .primary)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                    }
                    
                    Text(genre.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
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
            return .orange
        case .other:
            return .blue
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            return Color.gray.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        isSelected ? .blue : .gray.opacity(0.3)
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
        .background(Color.gray.opacity(0.1))
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
                            .foregroundColor(isSelected ? .blue : .primary)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    Text(genre.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
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
            return .orange
        case .other:
            return .blue
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.15)
        } else {
            return Color.gray.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        isSelected ? .blue : .gray.opacity(0.3)
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