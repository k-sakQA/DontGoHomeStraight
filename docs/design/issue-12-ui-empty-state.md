# Issue #12 詳細設計書（UIデザイン適用 / 空状態ビュー）

## 目的 / スコープ
- 目的: Issue #12 の要件（UIデザイン適用と空状態ビュー追加）をSwiftUIで実装できるようにする詳細設計。
- 対象: iOSアプリ（SwiftUI、NavigationStack前提）。既存ホーム画面のテーマ適用と新規 EmptyStateView の追加。

## 前提・想定
- 開発環境: Xcode 15+, iOS 16+（NavigationStack / ColorScheme / @Environment(\.dismiss) 利用可）
- 既存: ホーム画面 HomeView（仮）、Assets.xcassets。ダークモード対応は未徹底想定。
- 要件（Issueより）：
  - プライマリカラー #074CAC の階調（90%〜20%）を Assets.xcassets に登録
  - タイポ: 見出し .title3.weight(.semibold)、本文 .body、副文 .footnote
  - ロゴ: logo_blue.pdf（ライト）、logo_white.pdf（ダーク）を登録し外観に応じて切替
  - ブランドフィルドボタン: 角丸16、高さ52pt、シャドウ付き
  - 既存ホーム画面に上記テーマ適用
  - 候補0件時の空状態ビュー追加（ロゴ/メッセージ/広告プレースホルダ/トップへ戻るボタン）
  - 戻る処理: NavigationStack は path.removeAll()、それ以外は dismiss()

## デザイントークン
- カラー
  - ベース: #074CAC（ブランドブルー）
  - 登録名（推奨）: Brand/Primary, Brand/Primary90, ..., Brand/Primary20
  - 実装: Assets.xcassets の Named Color として管理し、 Color(Brand/Primary) で参照
- タイポ
  - 見出し: .title3.weight(.semibold)
  - 本文: .body
  - 副文: .footnote
- コーナー/シャドウ
  - 角丸: 16
  - 高さ: 52pt（ボタン）
  - シャドウ: color .black.opacity(0.12), radius 12, x 0, y 4
- スペーシング目安
  - セクション間24、要素間12、画面左右16

## アセット設計
- Colors: Brand/Primary, Brand/Primary90〜20（Any/Dark同値で登録、将来差異はDarkに設定）
- Images: logo_blue.pdf, logo_white.pdf（Image Set へ）
- ダークモード切替: ColorScheme に応じてロゴを出し分け

## コンポーネント設計
- Color拡張
  - Color.brandPrimary などのトークン化（Brand/Primary〜20まで）
- Typographyヘルパ
  - AppFont.heading/body/footnote を定義
- LogoView
  - ダーク/ライトでロゴ切替、サイズ可変
- BrandButton
  - 角丸16/高さ52/シャドウ/ローディング・無効状態をサポート
- EmptyStateView
  - ロゴ/メッセージ/広告プレースホルダ/戻るボタン
  - navigationPath を Binding<[AnyHashable]>? で受け、存在時 removeAll()、非存在時 dismiss()

## 既存ホーム画面への適用
- 背景: Color(uiColor: .systemBackground)
- テキスト: .primary / .secondary と AppFont の併用
- ボタン: 主要CTAは BrandButton へ置換
- 空状態条件: candidates.isEmpty で EmptyStateView を表示（例: EmptyStateView(navigationPath: )）

## ファイル構成（提案）
- Sources/DesignSystem/Color/Color+Brand.swift
- Sources/DesignSystem/Typography/AppFont.swift
- Sources/DesignSystem/Components/LogoView.swift
- Sources/DesignSystem/Components/BrandButton.swift
- Sources/Shared/EmptyState/EmptyStateView.swift
- Assets.xcassets（カラーセット/ロゴ）

## インターフェース仕様（抜粋）
- LogoView(size: CGFloat = 96)
- BrandButton(title: String, action: () -> Void, isLoading: Bool = false, isEnabled: Bool = true)
- EmptyStateView(navigationPath: Binding<[AnyHashable]>? = nil, titleText: String = ..., buttonTitle: String = ...)

## 実装手順
1) Assets にカラーセット追加（Brand/Primary ほか）
2) ロゴ画像を imageset に追加
3) Color+Brand.swift / AppFont.swift を追加
4) LogoView.swift / BrandButton.swift を追加
5) EmptyStateView.swift を追加
6) HomeView にテーマ適用と空状態分岐を追加
7) アクセシビリティとダークモード確認
8) プレビュー/実機で検証

## 受け入れ基準
- デザイントークンの利用徹底、ライト/ダークでロゴ切替
- BrandButton: 高さ52/角丸16/シャドウ、無効・ローディング状態の見た目と操作不可
- EmptyStateView: 構成要素が揃い、戻る動作が path.removeAll() または dismiss()
- HomeView: 背景/テキスト/CTAが新テーマに準拠
- アクセシビリティ: 主ボタンに適切な accessibilityLabel

## テスト観点
- BrandButton の isLoading/isEnabled の分岐
- EmptyStateView の Light/Dark スナップショット
- HomeView 候補0件/ありの分岐
- ナビゲーション: path.removeAll() / dismiss() の確認

## リスク・注意
- NavigationStack の path 型が [AnyHashable] 前提。既存との差異に注意
- ロゴ画像の余白/透過により視覚的バランスが崩れる可能性
- カラー階調はブランドガイドに合わせ、視認性検証を行う
