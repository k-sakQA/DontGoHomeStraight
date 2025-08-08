# まっすぐ帰りたくない

*寄り道を楽しむためのiOSアプリケーション*

---

## ✨ 概要

「まっすぐ帰りたくない」は、日常のルーティンに小さな発見と楽しみを加えるiOSアプリケーションです。AI技術を活用して、あなたの気分や興味に基づいた最適な寄り道スポットを提案し、いつもとは違った帰り道を案内します。

## 🎯 コンセプト

現代の忙しい生活において、私たちはしばしば同じ道を歩き、同じルーティンを繰り返しています。このアプリは、そんな日常に小さな冒険と発見をもたらし、新しい体験への扉を開きます。

## 🛠 技術スタック

### フロントエンド
- **SwiftUI** - モダンなUI構築
- **UIKit** - iOS 15.0+対応
- **Core Location** - 高精度位置情報
- **MapKit** - ネイティブ地図表示

### AI・外部サービス
- **OpenAI API (GPT-4)** - インテリジェントな提案生成
- **Google Maps SDK** - 詳細な地図データ
- **Google Places API** - 場所情報の取得
- **Google Directions API** - 最適ルート計算

### アーキテクチャ
- **Clean Architecture** - 保守性の高い設計
- **MVVM** - データバインディング
- **Combine** - リアクティブプログラミング
- **XCTest** - テスト駆動開発

## 📱 主な機能

- 🎯 **気分に基づく提案** - その日の気分に合わせたスポット提案
- 🗺️ **インテリジェントルート** - AI による最適経路計算
- 🔍 **ジャンル選択** - カフェ、書店、公園など多彩なカテゴリ
- 🚶‍♂️ **移動手段対応** - 徒歩、自転車、公共交通機関
- 📍 **現在地連携** - リアルタイム位置情報との統合

## 🚀 セットアップ

### 必要な環境
```
Xcode 14.0+
iOS 15.0+
macOS 12.0+
```

### インストール手順

1. **リポジトリのクローン**
   ```bash
   git clone https://github.com/k-sakQA/DontGoHomeStraight.git
   cd DontGoHomeStraight
   ```

2. **API キーの設定**
   ```bash
   # API_KEYS_SETUP.md を参照してキーを設定
   cp Config/APIKeys.example.swift Config/APIKeys.swift
   ```

3. **プロジェクトの起動**
   ```bash
   open DontGoHomeStraight.xcodeproj
   ```

4. **ビルド・実行**
   - Xcodeでプロジェクトを開く
   - Target Device を選択
   - ⌘+R でビルド・実行

## 📖 使用方法

1. **目的地の設定** - 帰宅先や目的地を入力
2. **気分の選択** - 今日の気分やテーマを選択
3. **移動手段の指定** - 徒歩、自転車、電車から選択
4. **ジャンルの選択** - 立ち寄りたいスポットのカテゴリを指定
5. **提案の確認** - AIが生成した寄り道プランを確認
6. **ナビゲーション開始** - 選択したルートでの案内開始

## 🏗️ プロジェクト構造

```
DontGoHomeStraight/
├── App/                    # アプリケーション設定
├── Presentation/           # UI・ViewModel層
│   ├── Views/             # SwiftUI Views
│   ├── ViewModels/        # ビジネスロジック
│   └── Components/        # 再利用可能コンポーネント
├── Domain/                # ドメイン層
│   ├── Entities/          # エンティティ
│   ├── UseCases/          # ユースケース
│   └── Repositories/      # リポジトリインターフェース
├── Infrastructure/        # インフラ層
│   ├── Network/          # API通信
│   ├── Storage/          # データ永続化
│   └── Location/         # 位置情報サービス
└── Tests/                # テストコード
```

## 🤝 貢献について

プロジェクトへの貢献を歓迎します。以下の手順でご参加ください：

1. フォークの作成
2. フィーチャーブランチの作成 (`git checkout -b feature/amazing-feature`)
3. 変更のコミット (`git commit -m 'Add amazing feature'`)
4. ブランチへのプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストの作成

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は [LICENSE](LICENSE) ファイルをご確認ください。

## 👤 作成者

**Sakata Kazunori**
- GitHub: [@k-sakQA](https://github.com/k-sakQA)
- 作成日: 2025年8月5日

---

*日常に小さな冒険を - DontGoHomeStraight*