# 詳細設計書: ユーザーによる寄り道提案方式の選択（AI / Google Maps API）

- 対象Issue: [#9 ユーザーによる設定変更（AI or GoogleMAP APIを選択）](https://github.com/k-sakQA/DontGoHomeStraight/issues/9)
- 対象ブランチ: `suggestion-select`
- 目的: 既存の実装を壊さずに、ユーザーが「AI」または「Google Maps API」を選択して寄り道候補を取得できるようにする。
- 非目標: 既存のFeature FlagやConfig/Info.plistの既定値を変更しない。重複呼び出し・二重遷移を発生させない。

---

## 1. 現状の構成（要点）
- DI: `App/DependencyContainer.swift`
  - `placeRecommendationUseCase: PlaceRecommendationUseCaseImpl`（AI→Places→DM→スコアリング 方式）
  - `systemWaypointSuggestionUseCase: SystemWaypointSuggestionUseCase`（Google ポリライン方式）
- VM: `Presentation/ViewModels/AppViewModel.swift`
  - `getRecommendations()` 内で `FeatureFlags.detourSystemPicker` により方式を切替
    - true: `systemWaypointSuggestionUseCase.getRecommendations(...)`
    - false: `placeRecommendationUseCase.getRecommendations(...)`
  - 取得後、`recommendedGenres` を更新し `.genreSelection` へ遷移
- 画面: `Presentation/Views/MoodSelectionView.swift`
  - 気分選択後の「寄り道を提案する」ボタン押下で `viewModel.navigateToGenreSelection()`（内部で `getRecommendations()` 実行）
- Feature Flag: `App/Config/FeatureFlags.swift`
  - `detourSystemPicker` は `Config.plist`/`Info.plist` から読み取り（既定: false）。

注意: 既存のデフォルト動作やフラグの既定値は変更しない。

---

## 2. 変更方針（最小差分）
- 既存の「寄り道を提案する」ボタンの動作はそのまま（= 現在のFeature Flagに従う）。
- 新規で「AIで提案する」ボタンを Mood 選択画面に追加し、強制的にAI方式のみを呼び出す経路を追加。
- ViewModel 側に「方式を明示指定して推薦する」ための軽いオーバーロードを追加する（既存メソッドは温存）。
- DIや設定ファイルに変更は加えない。

---

## 3. 追加/変更する最小ファイル一覧
- 追加: `Domain/Entities/SuggestionMethod.swift`
  - 方式の明示指定用の小さな列挙
- 変更: `Presentation/ViewModels/AppViewModel.swift`
  - `getRecommendations(using: SuggestionMethod)` の追加
  - 既存 `getRecommendations()` は後方互換用として残し、内部で `using` に委譲
- 変更: `Presentation/Views/MoodSelectionView.swift`
  - 既存「寄り道を提案する」ボタンはそのまま
  - 新たに「AIで提案する」ボタンを追加（AI方式を明示指定）

注: ラベル文言の変更（例: 既存ボタンを「Googleで提案する」へ改名）は任意。最小差分では変更しない。

---

## 4. 仕様詳細（ロジック）
### 4.1 SuggestionMethod（新規）
- 目的: 呼び出し側から方式を明示指定するための型
- 案:
```swift
enum SuggestionMethod {
    case ai
    case google
}
```

### 4.2 AppViewModel 変更（最小）
- 新規メソッド（公開）:
```swift
func navigateToGenreSelection(using method: SuggestionMethod) {
    // 既存の前提チェック（currentLocation, destination, selectedMood, selectedTransportMode）を満たした上で
    Task { await getRecommendations(using: method) }
}
```
- 新規メソッド（非公開/内部）:
```swift
private func getRecommendations(using method: SuggestionMethod) async {
    // 既存 getRecommendations() の前提チェック/状態制御（isLoading, showError, recommendedGenres 更新、画面遷移）を踏襲
    // 分岐のみ明示方式で切替（Feature Flag をバイパス）
    switch method {
    case .google:
        guard let sys = systemWaypointSuggestionUseCase else {
            // フォールバック: 既存方式（AI） or エラー通知
            // ここではユーザー通知の方針（"Google方式が利用できません"等）
            return
        }
        // sys.getRecommendations(...)
    case .ai:
        // placeRecommendationUseCase.getRecommendations(...)
    }
}
```
- 既存メソッド（変更）:
```swift
private func getRecommendations() async {
    // 従来どおり Feature Flag で切替
    let defaultMethod: SuggestionMethod = FeatureFlags.detourSystemPicker ? .google : .ai
    await getRecommendations(using: defaultMethod)
}
```
- ポイント:
  - isLoading/エラー処理/画面遷移の一貫性維持（既存コードを再利用）。
  - 二重呼び出し防止: ボタン押下時はそれぞれ Task を1つだけ生成し、`isLoading` でガード可能。

### 4.3 MoodSelectionView 変更（最小）
- 既存の「寄り道を提案する」ボタンは変更しない（= 既存フロー維持）。
- 新規ボタン「AIで提案する」追加:
```swift
Button(action: {
    guard let mood = currentMood else { return }
    viewModel.setMood(mood)
    viewModel.navigateToGenreSelection(using: .ai)
}) {
    HStack { Image(systemName: "brain.head.profile"); Text("AIで提案する") }
}
.disabled(currentMood == nil)
```
- UI配置: 既存ボタンの直下、同じ幅/角丸/フォントで、色は差別化（例: .purple）
- アクセシビリティ: ラベル `"AIで提案する"` を VoiceOver 対応

---

## 5. エラー/フォールバック方針
- Google方式（SystemWaypointSuggestionUseCase）が利用不可（nil）の場合
  - 明示エラー表示（"Google方式が利用できません"）
  - 可能なら AI 方式を案内（ワンタップで切替）
- AI方式がエラー/候補0件
  - 既存のエラー表示/空メッセージを踏襲
- 二重処理防止
  - `isLoading` を true にして二重タップを抑止

---

## 6. ビルド/設定への配慮（重要）
- Feature Flag 既定値や Config/Info.plist の値は一切変更しない
- `DependencyContainer` のDI定義も変更不要（両方式は既に初期化済み）
- 新規ファイル `SuggestionMethod.swift` の追加のみで既存参照を壊さない
- 既存の関数シグネチャや呼び出し元（テスト含む）を極力温存

---

## 7. テスト観点
- 単体
  - AppViewModel.getRecommendations(using: .ai) が AI 経路のみを呼ぶ
  - AppViewModel.getRecommendations(using: .google) が System経路のみを呼ぶ
  - isLoading の制御とエラー伝播
- UI
  - MoodSelectionView に2つのボタンが表示され、気分未選択時はどちらも disabled
  - 方式に応じて候補取得→ `.genreSelection` 遷移

---

## 8. 実装手順（最小差分）
1) `Domain/Entities/SuggestionMethod.swift` を追加
2) `AppViewModel` に `getRecommendations(using:)` と `navigateToGenreSelection(using:)` を追加
3) `MoodSelectionView` に「AIで提案する」ボタンを追加
4) ビルド確認（設定の変更は不要）

---

## 9. 影響範囲
- Presentation 層（`MoodSelectionView`, `AppViewModel`）
- Domain/Entities に軽量Enum追加
- DI・設定・既存テストへの影響は最小

---

## 10. 付記（任意機能）
- 設定画面でデフォルト方式を選択（UserDefaults）
  - 実装する場合も、既定値は従来どおり Feature Flag に委譲し上書きしない
- ロギング: 方式選択、所要時間、候補数、エラー種類