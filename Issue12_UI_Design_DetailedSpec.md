# Issue #12 UIデザイン適用 & 空状態ビュー追加 - 詳細設計書

## 📋 概要

本設計書では、[Issue #12](https://github.com/k-sakQA/DontGoHomeStraight/issues/12)「UIデザイン適用 & 空状態ビュー追加」の実装に必要な詳細設計を定義します。

### 🎯 実装目標
1. **ブランドデザインシステムの適用**
   - Primary Color: `#074CAC` (Brand Blue)を基準とした階層カラーパレット
   - 統一されたタイポグラフィシステム
   - ブランドロゴの統合（ライト/ダークモード対応）
   - 新しいボタンスタイルシステム

2. **空状態ビューの実装**
   - 候補が0件の場合に表示する専用画面
   - ユーザーフレンドリーなメッセージとCTA
   - 将来の広告表示スペースの確保

---

## 🎨 1. ブランドデザインシステム

### 1.1 カラーパレット設計

#### Primary Brand Color
- **Brand Blue**: `#074CAC`

#### 階層カラーパレット（Blue/90〜20）
```swift
// Brand Blue階層カラー
static let brandBlue = Color(hex: "074CAC")      // Base (Blue/100)
static let brandBlue90 = Color(hex: "1E5BB8")   // Blue/90
static let brandBlue80 = Color(hex: "356BC4")   // Blue/80  
static let brandBlue70 = Color(hex: "4C7CD0")   // Blue/70
static let brandBlue60 = Color(hex: "638DDC")   // Blue/60
static let brandBlue50 = Color(hex: "7A9DE8")   // Blue/50
static let brandBlue40 = Color(hex: "91AEF4")   // Blue/40
static let brandBlue30 = Color(hex: "A8BEFF")   // Blue/30
static let brandBlue20 = Color(hex: "BFCFFF")   // Blue/20
static let brandBlue10 = Color(hex: "D6DFFF")   // Blue/10
```

#### Semantic Colors
```swift
// UI Semantic Colors
static let appPrimary = brandBlue            // メインアクション
static let appPrimaryLight = brandBlue30     // ホバー、アクティブ状態
static let appPrimaryDark = brandBlue90      // 押下状態

static let appBackground = Color(hex: "FAFBFC")    // 背景色
static let appSurface = Color.white                // カード背景
static let appSurfaceVariant = Color(hex: "F5F7FA") // セカンダリ背景

static let appOnPrimary = Color.white              // Primary上のテキスト
static let appOnSurface = Color(hex: "1A1C1E")     // Surface上のテキスト
static let appOnSurfaceVariant = Color(hex: "44474E") // セカンダリテキスト
```

#### ダークモード対応
```swift
// Dark Mode Colors
static let appBackgroundDark = Color(hex: "121212")
static let appSurfaceDark = Color(hex: "1E1E1E")
static let appSurfaceVariantDark = Color(hex: "2D2D2D")
static let appOnSurfaceDark = Color(hex: "E6E1E5")
static let appOnSurfaceVariantDark = Color(hex: "C4C7C5")
```

### 1.2 タイポグラフィシステム

```swift
// Typography System
extension Font {
    // 見出し
    static let appDisplayLarge = Font.system(size: 57, weight: .regular)
    static let appDisplayMedium = Font.system(size: 45, weight: .regular)
    static let appDisplaySmall = Font.system(size: 36, weight: .regular)
    
    static let appHeadlineLarge = Font.system(size: 32, weight: .regular)
    static let appHeadlineMedium = Font.system(size: 28, weight: .regular)
    static let appHeadlineSmall = Font.title3.weight(.semibold) // Issue要件
    
    // 本文
    static let appBodyLarge = Font.system(size: 16, weight: .regular)
    static let appBodyMedium = Font.body // Issue要件
    static let appBodySmall = Font.system(size: 12, weight: .regular)
    
    // ラベル
    static let appLabelLarge = Font.system(size: 14, weight: .medium)
    static let appLabelMedium = Font.system(size: 12, weight: .medium)
    static let appLabelSmall = Font.footnote // Issue要件
}
```

### 1.3 ボタンスタイルシステム

#### Brand Filled Button（メインボタン）
```swift
struct BrandFilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBodyLarge.weight(.semibold))
            .foregroundColor(.appOnPrimary)
            .frame(maxWidth: .infinity, minHeight: 52) // Issue要件: 高さ52pt
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16) // Issue要件: 角丸16
                    .fill(Color.appPrimary)
                    .opacity(configuration.isPressed ? 0.9 : 1.0)
            )
            .shadow( // Issue要件: シャドウ付き
                color: Color.appPrimary.opacity(0.3),
                radius: configuration.isPressed ? 8 : 12,
                x: 0,
                y: configuration.isPressed ? 4 : 6
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
```

#### Secondary Button（将来拡張用）
```swift
struct BrandSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBodyMedium.weight(.medium))
            .foregroundColor(.appPrimary)
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appPrimary, lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.thinMaterial)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
```

---

## 🖼️ 2. アセット管理

### 2.1 Assets.xcassets構造

```
Assets.xcassets/
├── Colors/
│   ├── BrandBlue.colorset/
│   ├── BrandBlue90.colorset/
│   ├── BrandBlue80.colorset/
│   ├── BrandBlue70.colorset/
│   ├── BrandBlue60.colorset/
│   ├── BrandBlue50.colorset/
│   ├── BrandBlue40.colorset/
│   ├── BrandBlue30.colorset/
│   ├── BrandBlue20.colorset/
│   ├── BrandBlue10.colorset/
│   ├── AppBackground.colorset/
│   ├── AppSurface.colorset/
│   ├── AppSurfaceVariant.colorset/
│   ├── AppOnPrimary.colorset/
│   ├── AppOnSurface.colorset/
│   └── AppOnSurfaceVariant.colorset/
├── Logos/
│   ├── LogoBlue.imageset/
│   │   └── logo_blue.pdf
│   └── LogoWhite.imageset/
│       └── logo_white.pdf
└── AppIcon.appiconset/
```

### 2.2 カラーセット設定例

#### BrandBlue.colorset/Contents.json
```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.675",
          "green" : "0.298",
          "red" : "0.027"
        }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "0.800",
          "green" : "0.450",
          "red" : "0.200"
        }
      },
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

### 2.3 ロゴ使用方法

```swift
// ダークモード対応ロゴ表示
struct AppLogo: View {
    @Environment(\.colorScheme) private var colorScheme
    let height: CGFloat = 56
    
    var body: some View {
        Image(colorScheme == .dark ? "LogoWhite" : "LogoBlue")
            .resizable()
            .scaledToFit()
            .frame(height: height)
    }
}
```

---

## 📱 3. 空状態ビュー設計

### 3.1 EmptyStateView実装

```swift
import SwiftUI

struct EmptyStateView: View {
    @Environment(\.colorScheme) private var colorScheme
    let onBackToHome: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: geometry.size.height * 0.15)
                    
                    // ロゴセクション
                    logoSection
                    
                    // メッセージセクション  
                    messageSection
                    
                    // 広告プレースホルダー
                    adPlaceholderSection
                    
                    // CTAボタン
                    ctaSection
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 24)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(backgroundView)
    }
    
    // MARK: - Components
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            AppLogo()
                .scaleEffect(1.2)
                .opacity(0.9)
            
            Text("まっすぐ帰りたくない")
                .font(.appHeadlineSmall)
                .foregroundColor(.appOnSurface)
        }
    }
    
    private var messageSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "map")
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.appPrimary.opacity(0.6))
            
            Text("候補が見つかりませんでした")
                .font(.appHeadlineSmall)
                .foregroundColor(.appOnSurface)
                .multilineTextAlignment(.center)
            
            Text("条件を変更して再度お試しください")
                .font(.appBodyMedium)
                .foregroundColor(.appOnSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }
    
    private var adPlaceholderSection: some View {
        VStack(spacing: 12) {
            Text("広告エリア")
                .font(.appLabelSmall)
                .foregroundColor(.appOnSurfaceVariant)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(.thinMaterial)
                .frame(height: 120)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "rectangle.3.group")
                            .font(.system(size: 24))
                            .foregroundColor(.appOnSurfaceVariant.opacity(0.6))
                        
                        Text("広告表示予定地")
                            .font(.appLabelSmall)
                            .foregroundColor(.appOnSurfaceVariant.opacity(0.8))
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.appPrimary.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var ctaSection: some View {
        Button(action: onBackToHome) {
            Label("トップ画面に戻る", systemImage: "arrow.uturn.backward")
                .font(.appBodyLarge.weight(.semibold))
        }
        .buttonStyle(BrandFilledButtonStyle())
    }
    
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color.appBackground,
                Color.appSurfaceVariant.opacity(0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// MARK: - Preview
#Preview {
    EmptyStateView {
        print("Back to home tapped")
    }
}

#Preview("Dark Mode") {
    EmptyStateView {
        print("Back to home tapped")
    }
    .preferredColorScheme(.dark)
}
```

### 3.2 空状態判定ロジック

```swift
// AppViewModel.swift に追加
extension AppViewModel {
    
    /// 推奨場所が空かどうかを判定
    var hasNoRecommendations: Bool {
        recommendedPlaces.isEmpty
    }
    
    /// 空状態画面への遷移
    func navigateToEmptyState() {
        // 現在の画面に応じて適切な処理を実行
        switch currentScreen {
        case .genreSelection, .navigation:
            // 空状態を表示する条件
            if hasNoRecommendations {
                showEmptyState = true
            }
        default:
            break
        }
    }
    
    /// 空状態からホームに戻る
    func returnToHomeFromEmptyState() {
        // 状態をリセット
        resetAppState()
        // ホーム画面に遷移
        currentScreen = .home
        showEmptyState = false
    }
}
```

---

## 🧭 4. ナビゲーション実装

### 4.1 NavigationStack対応

現在のアプリは`NavigationView`ベースですが、空状態ビューからの戻り処理でNavigationStackも考慮します。

```swift
// ContentView.swift の更新
struct ContentView: View {
    @StateObject private var appViewModel = DependencyContainer.shared.appViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                // メイン画面
                mainContent
                
                // 空状態オーバーレイ
                if appViewModel.showEmptyState {
                    EmptyStateView {
                        appViewModel.returnToHomeFromEmptyState()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                // エラー・ローディング表示
                if appViewModel.showError {
                    errorOverlay
                }
                
                if appViewModel.isLoading {
                    loadingOverlay
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appViewModel.showEmptyState)
    }
    
    // ... 既存のコード
}
```

### 4.2 空状態表示判定

```swift
// GenreSelectionView.swift での空状態判定例
struct GenreSelectionView: View {
    @ObservedObject var viewModel: AppViewModel
    
    var body: some View {
        // ... 既存のUI
        
        .onChange(of: viewModel.recommendedPlaces) { places in
            // 推奨場所の取得完了後に空状態をチェック
            if places.isEmpty && !viewModel.isLoading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.navigateToEmptyState()
                }
            }
        }
    }
}
```

---

## 🔄 5. 既存コードの更新

### 5.1 DesignSystem.swift の更新

```swift
// DontGoHomeStraight/Presentation/Design/DesignSystem.swift

import SwiftUI

// MARK: - Color + Hex initializer
extension Color {
    init(hex: String, alpha: Double = 1.0) {
        // ... 既存のコード
    }
}

// MARK: - Brand Color System
extension Color {
    // Primary Brand Colors
    static let brandBlue = Color(hex: "074CAC")
    static let brandBlue90 = Color(hex: "1E5BB8")
    static let brandBlue80 = Color(hex: "356BC4")
    static let brandBlue70 = Color(hex: "4C7CD0")
    static let brandBlue60 = Color(hex: "638DDC")
    static let brandBlue50 = Color(hex: "7A9DE8")
    static let brandBlue40 = Color(hex: "91AEF4")
    static let brandBlue30 = Color(hex: "A8BEFF")
    static let brandBlue20 = Color(hex: "BFCFFF")
    static let brandBlue10 = Color(hex: "D6DFFF")
    
    // Semantic Colors (Light Mode)
    static let appPrimary = brandBlue
    static let appPrimaryLight = brandBlue30
    static let appPrimaryDark = brandBlue90
    
    static let appBackground = Color(hex: "FAFBFC")
    static let appSurface = Color.white
    static let appSurfaceVariant = Color(hex: "F5F7FA")
    
    static let appOnPrimary = Color.white
    static let appOnSurface = Color(hex: "1A1C1E")
    static let appOnSurfaceVariant = Color(hex: "44474E")
    
    // Dark Mode Colors
    static let appBackgroundDark = Color(hex: "121212")
    static let appSurfaceDark = Color(hex: "1E1E1E")
    static let appSurfaceVariantDark = Color(hex: "2D2D2D")
    static let appOnSurfaceDark = Color(hex: "E6E1E5")
    static let appOnSurfaceVariantDark = Color(hex: "C4C7C5")
    
    // Legacy Support (既存コードとの互換性)
    @available(*, deprecated, message: "Use appPrimary instead")
    static let appAccent = Color(hex: "FFC107")
}

// MARK: - Typography System
extension Font {
    static let appDisplayLarge = Font.system(size: 57, weight: .regular)
    static let appDisplayMedium = Font.system(size: 45, weight: .regular)
    static let appDisplaySmall = Font.system(size: 36, weight: .regular)
    
    static let appHeadlineLarge = Font.system(size: 32, weight: .regular)
    static let appHeadlineMedium = Font.system(size: 28, weight: .regular)
    static let appHeadlineSmall = Font.title3.weight(.semibold)
    
    static let appBodyLarge = Font.system(size: 16, weight: .regular)
    static let appBodyMedium = Font.body
    static let appBodySmall = Font.system(size: 12, weight: .regular)
    
    static let appLabelLarge = Font.system(size: 14, weight: .medium)
    static let appLabelMedium = Font.system(size: 12, weight: .medium)
    static let appLabelSmall = Font.footnote
}
```

### 5.2 AppViewModel.swift の更新

```swift
// AppViewModel.swift に追加するプロパティ
@Published var showEmptyState: Bool = false

// 空状態関連のメソッドを追加
extension AppViewModel {
    var hasNoRecommendations: Bool {
        recommendedPlaces.isEmpty
    }
    
    func navigateToEmptyState() {
        switch currentScreen {
        case .genreSelection, .navigation:
            if hasNoRecommendations {
                showEmptyState = true
            }
        default:
            break
        }
    }
    
    func returnToHomeFromEmptyState() {
        resetAppState()
        currentScreen = .home
        showEmptyState = false
    }
    
    private func resetAppState() {
        destination = nil
        selectedTransportMode = nil
        selectedMood = nil
        selectedGenres = []
        recommendedPlaces = []
        currentRoute = nil
    }
}
```

---

## ✅ 6. 実装チェックリスト

### 6.1 ブランドデザイン適用

- [ ] **Assets.xcassets にブランドカラーをColor Setで登録**
  - [ ] BrandBlue（#074CAC）
  - [ ] BrandBlue90〜10の階層カラー
  - [ ] Semantic Colors（AppPrimary, AppBackground等）
  - [ ] ダークモード対応カラー

- [ ] **ロゴファイルの登録**
  - [ ] logo_blue.pdf（ライト背景用）
  - [ ] logo_white.pdf（ダーク背景用）
  - [ ] LogoBlue.imageset, LogoWhite.imagesetの作成

- [ ] **DesignSystem.swift の更新**
  - [ ] 新しいカラーシステムの定義
  - [ ] タイポグラフィシステムの追加
  - [ ] 既存カラーとの互換性確保

- [ ] **BrandFilledButtonStyle の実装**
  - [ ] 角丸16px、高さ52pt
  - [ ] シャドウ効果
  - [ ] プレス時のアニメーション

### 6.2 既存画面の更新

- [ ] **HomeView の色/コンポーネント置き換え**
  - [ ] 背景色: appBackground
  - [ ] テキスト色: appOnSurface, appOnSurfaceVariant
  - [ ] ボタン: BrandFilledButtonStyle適用

- [ ] **その他のViewの色置き換え**
  - [ ] DestinationSettingView
  - [ ] TransportModeSelectionView
  - [ ] MoodSelectionView
  - [ ] GenreSelectionView
  - [ ] NavigationView
  - [ ] ArrivalView

### 6.3 空状態ビュー実装

- [ ] **EmptyStateView の実装**
  - [ ] ロゴ表示（ダークモード対応）
  - [ ] メッセージ表示
  - [ ] 広告プレースホルダー
  - [ ] CTAボタン（BrandFilledButtonStyle）

- [ ] **AppViewModel の更新**
  - [ ] showEmptyState プロパティ追加
  - [ ] 空状態判定ロジック
  - [ ] ホームへの戻り処理

- [ ] **ContentView の更新**
  - [ ] 空状態オーバーレイ表示
  - [ ] アニメーション効果

- [ ] **各画面での空状態判定**
  - [ ] GenreSelectionView
  - [ ] NavigationView

### 6.4 テスト・検証

- [ ] **ダークモード対応確認**
  - [ ] 全画面でのダークモード表示
  - [ ] ロゴの正しい切り替え
  - [ ] カラーの適切な表示

- [ ] **空状態フロー確認**
  - [ ] 候補0件時の空状態表示
  - [ ] トップ画面への戻り動作
  - [ ] 状態のリセット確認

- [ ] **既存機能の動作確認**
  - [ ] 全画面の表示・操作
  - [ ] ナビゲーションフロー
  - [ ] エラーハンドリング

---

## 📐 7. 実装順序

1. **Assets.xcassets の準備**
   - カラーセットの作成
   - ロゴファイルの配置

2. **DesignSystem.swift の更新**
   - 新しいカラーシステムの定義
   - タイポグラフィシステムの追加

3. **BrandFilledButtonStyle の実装**
   - 新しいボタンスタイルの作成

4. **EmptyStateView の実装**
   - 空状態ビューの作成

5. **AppViewModel の更新**
   - 空状態関連のロジック追加

6. **既存画面の色置き換え**
   - 各Viewファイルの段階的更新

7. **ContentView の更新**
   - 空状態表示ロジックの統合

8. **テスト・検証**
   - 全機能の動作確認

---

## 🔧 8. 技術的考慮事項

### 8.1 パフォーマンス
- カラーアセットの効率的な読み込み
- 画像アセット（PDF）の最適化
- アニメーションのパフォーマンス最適化

### 8.2 アクセシビリティ
- カラーコントラストの確保
- ダイナミックタイプ対応
- VoiceOver対応

### 8.3 互換性
- iOS 15.0+ サポート
- 既存コードとの後方互換性
- 段階的移行の考慮

---

## 📚 9. 参考資料

- [Human Interface Guidelines - Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [Human Interface Guidelines - Typography](https://developer.apple.com/design/human-interface-guidelines/typography)
- [SwiftUI Color and Shape](https://developer.apple.com/documentation/swiftui/color)
- [Managing Assets with Asset Catalogs](https://developer.apple.com/documentation/xcode/managing-assets-with-asset-catalogs)

---

*本設計書は Issue #12 の要件に基づいて作成されています。実装中に仕様変更や追加要件が発生した場合は、適宜更新を行ってください。*