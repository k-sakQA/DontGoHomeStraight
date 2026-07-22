import SwiftUI
import CoreLocation

/// 寄り道図鑑: 訪問したスポットをカードとして収集・閲覧する画面
struct CollectionView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedSpot: VisitedSpot?

    /// 図鑑のジャンルバッジ枠（固定12種）
    private let badgeGenres: [Genre] = Genre.commonRestaurantGenres + Genre.commonOtherGenres

    private var spots: [VisitedSpot] {
        viewModel.visitedSpots
    }

    var body: some View {
        ZStack {
            LinearGradient.appBackgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    statsCard

                    genreBadgeCard

                    if spots.isEmpty {
                        emptyCollectionCard
                    } else {
                        collectedCardsSection
                    }

                    Button(action: {
                        viewModel.closeCollection()
                    }) {
                        Text("ホームに戻る")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding()
            }
        }
        .navigationTitle("寄り道図鑑")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSpot) { spot in
            SpotDetailSheet(spot: spot, viewModel: viewModel)
        }
    }

    // MARK: - Stats

    @ViewBuilder
    private var statsCard: some View {
        HStack(spacing: 0) {
            statItem(value: "\(spots.count)", label: "スポット", emoji: "📖")
            statDivider
            statItem(value: "\(collectedBadgeCount)/\(badgeGenres.count)", label: "ジャンル", emoji: "🏅")
            statDivider
            statItem(value: "\(secretCount)", label: "シークレット", emoji: "👑")
        }
        .appCard()
    }

    private var collectedBadgeCount: Int {
        badgeGenres.filter { isBadgeCollected($0) }.count
    }

    private var secretCount: Int {
        spots.filter { $0.rarity == .secret }.count
    }

    @ViewBuilder
    private func statItem(value: String, label: String, emoji: String) -> some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 20))
            Text(value)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(Color(hex: "0D1B3A"))
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "6C757D"))
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var statDivider: some View {
        Rectangle()
            .fill(Color(hex: "E9EDF3"))
            .frame(width: 1, height: 44)
    }

    // MARK: - Genre Badges

    @ViewBuilder
    private var genreBadgeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ジャンルバッジ")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "6C757D"))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 12) {
                ForEach(badgeGenres, id: \.googleMapType) { genre in
                    genreBadge(genre)
                }
            }

            Text("そのジャンルの寄り道に到着するとバッジが解放されます")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "ADB5BD"))
        }
        .appCard()
    }

    private func isBadgeCollected(_ genre: Genre) -> Bool {
        return spots.contains { spot in
            spot.googleMapType == genre.googleMapType || spot.genreName == genre.name
        }
    }

    @ViewBuilder
    private func genreBadge(_ genre: Genre) -> some View {
        let collected = isBadgeCollected(genre)

        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        collected
                        ? (genre.category == .restaurant ? Color(hex: "FFC107").opacity(0.25) : Color(hex: "3A7DFF").opacity(0.18))
                        : Color(hex: "E9EDF3")
                    )
                    .frame(width: 48, height: 48)

                if collected {
                    Text(genre.category.emoji)
                        .font(.system(size: 24))
                } else {
                    Text("?")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundColor(Color(hex: "ADB5BD"))
                }
            }

            Text(genre.name)
                .font(.system(size: 10, weight: collected ? .semibold : .regular))
                .foregroundColor(collected ? Color(hex: "212529") : Color(hex: "ADB5BD"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Collected Cards

    @ViewBuilder
    private var collectedCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("コレクション")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "6C757D"))
                .padding(.horizontal, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 2), spacing: 14) {
                ForEach(spots) { spot in
                    Button(action: { selectedSpot = spot }) {
                        SpotCollectionCard(spot: spot, viewModel: viewModel)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var emptyCollectionCard: some View {
        VStack(spacing: 14) {
            Text("🗺️")
                .font(.system(size: 48))

            Text("まだコレクションがありません")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "212529"))

            Text("寄り道スポットに到着すると\nカードが図鑑に追加されます")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "6C757D"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .appCard()
    }
}

// MARK: - Spot Collection Card

struct SpotCollectionCard: View {
    let spot: VisitedSpot
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // サムネイル
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        spot.genreCategory == .restaurant
                        ? Color(hex: "FFC107").opacity(0.25)
                        : Color(hex: "C5D9FF")
                    )
                    .frame(height: 90)

                if let photoReference = spot.photoReference,
                   let url = viewModel.getPhotoURL(photoReference: photoReference, maxWidth: 200) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Text(spot.categoryEmoji)
                            .font(.system(size: 36))
                    }
                    .frame(height: 90)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(12)
                } else {
                    Text(spot.categoryEmoji)
                        .font(.system(size: 36))
                }
            }

            // レアリティ
            HStack(spacing: 4) {
                ForEach(0..<spot.rarity.stars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                }
                Text(spot.rarity.displayName)
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(Color(hex: spot.rarity.colorHex))

            Text(spot.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "212529"))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(minHeight: 32, alignment: .top)

            HStack {
                Text(spot.formattedLastVisit)
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "ADB5BD"))
                Spacer()
                if spot.visitCount > 1 {
                    Text("×\(spot.visitCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "3A7DFF"))
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    spot.rarity == .secret ? Color(hex: "D4A017").opacity(0.5) : Color(hex: "E9EDF3"),
                    lineWidth: spot.rarity == .secret ? 1.5 : 1
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Spot Detail Sheet

struct SpotDetailSheet: View {
    let spot: VisitedSpot
    @ObservedObject var viewModel: AppViewModel
    @SwiftUI.Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient.appBackgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // ヒーロー画像
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                spot.genreCategory == .restaurant
                                ? Color(hex: "FFC107").opacity(0.25)
                                : Color(hex: "C5D9FF")
                            )
                            .frame(height: 180)

                        if let photoReference = spot.photoReference,
                           let url = viewModel.getPhotoURL(photoReference: photoReference, maxWidth: 400) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(20)
                        } else {
                            Text(spot.categoryEmoji)
                                .font(.system(size: 64))
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 4) {
                            ForEach(0..<spot.rarity.stars, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                            }
                            Text(spot.rarity.displayName)
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(Color(hex: spot.rarity.colorHex))

                        Text(spot.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color(hex: "212529"))

                        Text(spot.address)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "6C757D"))

                        Divider()

                        detailRow(label: "ジャンル", value: "\(spot.categoryEmoji) \(spot.genreName)")
                        detailRow(label: "はじめての訪問", value: formatted(spot.firstVisitedAt))
                        detailRow(label: "訪問回数", value: "\(spot.visitCount)回")
                        if let mood = spot.moodDescription {
                            detailRow(label: "そのときの気分", value: mood)
                        }
                        if let rating = spot.rating {
                            detailRow(label: "評価", value: String(format: "★%.1f", rating))
                        }
                    }
                    .appCard()

                    Button(action: { dismiss() }) {
                        Text("閉じる")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "6C757D"))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "212529"))
        }
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    SwiftUI.NavigationView {
        CollectionView(viewModel: {
            let vm = AppViewModel.preview
            vm.visitedSpots = [
                VisitedSpot(
                    place: Place(
                        name: "隠れ家カフェ ことり",
                        coordinate: CLLocationCoordinate2D(latitude: 35.66, longitude: 139.70),
                        address: "東京都渋谷区",
                        genre: Genre(name: "カフェ", category: .restaurant, googleMapType: "cafe"),
                        rating: 4.6,
                        placeId: "p1",
                        userRatingsTotal: 87
                    ),
                    mood: Mood(activityType: .indoor, vibeType: .jazzy)
                ),
                VisitedSpot(
                    place: Place(
                        name: "代々木公園",
                        coordinate: CLLocationCoordinate2D(latitude: 35.67, longitude: 139.69),
                        address: "東京都渋谷区",
                        genre: Genre(name: "公園", category: .other, googleMapType: "park"),
                        rating: 4.2,
                        placeId: "p2",
                        userRatingsTotal: 20000
                    ),
                    mood: Mood(activityType: .outdoor, vibeType: .discovery)
                )
            ]
            return vm
        }())
    }
}

#Preview("Empty") {
    SwiftUI.NavigationView {
        CollectionView(viewModel: AppViewModel.preview)
    }
}
