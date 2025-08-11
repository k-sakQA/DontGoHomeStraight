## RFC: 30分以内の寄り道候補をシステム側で決定する（waypoint-suggestion-v1）

- 文書種別: RFC（Request for Comments）
- ステータス: Draft
- 対象Issue: [RFC #6 候補地提案をシステム側で実行する（AIに任せない）](https://github.com/k-sakQA/DontGoHomeStraight/issues/6)
- 対応ブランチ: `rfc/waypoint-suggestion-v1`

### 運用メモ（ガードレール）

- このRFCに関する生成系/背景タスクは「本PR（`rfc/waypoint-suggestion-v1`）」にのみコミット（PR乱立禁止）
- 受け入れ条件/API制約（常に順守）
  - 30分ハード上限: (T(P) - T0) ≤ 30分のみ提示
  - カテゴリ配分: 飲食=1 / 非飲食=2（3件時、割合は飲食30%/非飲食70%）
  - 品質フィルタ: rating ≥ 3.4, reviews ≥ 5（設定化可）
  - フォールバック: 0件 → 回廊半径を +200m で再探索（1回まで）
  - 決定的ランダム: dailySeed / runSeed（HMAC）で再現性、秒単位で揺らぎ
  - テレメトリ/キャッシュ: 候補総数・30分通過数・Matrix短期キャッシュ
  - Feature flag: `detour.system_picker` を通じて段階リリース

### Context

現状、OpenAIの出力に依存した候補地提案は、基準ルートから大きく逸脱するケースがあり、ユーザー体験としての「寄り道」の定義（基準ルートに対する追加所要時間が30分以内）を満たさない結果が生じうる。また、通勤などで「毎日同じルート」を通るユーザーにも、日替わりの新鮮さとランダム性を提供したい。これらの要件を満たすため、候補地の探索・評価・選定は地図APIによって厳密に行い、AIは説明文・コピー生成などの表現に限定する。

### Goals

- 追加所要時間のハード上限（30分）を100%満たす候補のみを提示する。
- カテゴリ配分を厳守（飲食30% / 非飲食70%。提示が3件のときは飲食=1、非飲食=2）。
- 品質フィルタは緩め：rating ≥ 3.4 かつ reviews ≥ 5（閾値は設定化）。
- 日替わりおよび実行時の分・秒単位での小さな揺らぎを提供する（決定的ランダム）。
- テレメトリ、キャッシュ、フォールバックを備え、安定的に動作する。

### Non-Goals

- LLMに候補地の最終選定を委ねない（LLMは説明文・コピー生成のみに利用）。
- 完全なレコメンド最適化（本RFCでは基礎的なスコアリングと分散のみ）。
- 30分超過候補の提示（本RFCでは許容しない）。

### Acceptance Criteria（Gherkin）

```gherkin
Feature: 30分以内の寄り道候補をシステム側で決定する

  Background:
    Given 現在地・目的地・移動手段・現在時刻が与えられている

  Scenario: 30分上限を満たす候補のみが提示される
    When 候補地の探索と評価を実行する
    Then 提示された全ての候補について (T(P) - T0) ≤ 30分 である

  Scenario: カテゴリ配分（飲食1・非飲食2）
    When 提示結果が3件である
    Then 飲食カテゴリがちょうど1件含まれる
    And 非飲食カテゴリがちょうど2件含まれる

  Scenario: 軽い品質フィルタの適用
    Given 候補に rating=3.4, reviews=5 のスポットが含まれる
    When 候補地のフィルタリングを行う
    Then 当該スポットはフィルタで除外されない

  Scenario: 決定的ランダム（タイムスタンプ固定）
    Given 同一の入力と同一のタイムスタンプ（秒まで）が与えられる
    When 候補選定を2回実行する
    Then 2回の結果は同一である

  Scenario: 時刻の違いによる揺らぎ
    Given 同一の入力でタイムスタンプの秒が異なる
    When 候補選定を実行する
    Then 少なくとも1件の候補が入れ替わる可能性がある

  Scenario: 候補ゼロ時のフォールバック
    Given 初回探索で30分以内の候補が0件である
    When 回廊半径を拡張して再探索する
    Then 0件のままなら “候補がありません…” メッセージを返す
```

### Out of Scope

- ルート可視化UIの刷新（既存UI範囲内での実装に留める）。
- 高度な学習・個人最適化（将来のADR/RFCで別途検討）。
- 広域の観光プランニング（本RFCは通勤等の短距離寄り道に焦点）。

### Approach / Design

- ルート基準時間 T0 の取得
  - Directions API で Origin→Destination の最短所要時間 T0 とポリラインを取得し、短期キャッシュ。
- 回廊（corridor）の生成
  - ポリライン沿いにモード別パラメータでバッファ（例: 徒歩/自転車/車/交通機関で幅を調整）。
- 候補収集（Places Nearby）
  - カテゴリ別に探索。重複排除。軽い品質フィルタ（rating/reviews）を適用。
  - 屋内系は open_now が取得できれば厳格にフィルタ。
- 所要時間の評価
  - Distance/Route Matrix をバッチで実行（O→P, P→D）。
  - 追加所要時間: T(P) = time(O→P) + time(P→D)。条件: T(P) - T0 ≤ 30分。
  - 0件時フォールバック: 回廊半径を +200m して再探索（1回のみ）。
- スコアリングと分散（有名偏重回避）

```
baseScore(P) =
  + w1 * (- extra_minutes)
  + w2 * vibe_match(mood, P.categories)
  + w3 * bayesian_quality(rating, reviews)      // m≈20, c≈3.7
  - w4 * log1p(reviews)                         // “有名税”
  - w5 * recency_penalty(lastShownAt; half-life=7d)
  + w6 * bucket_boost(focusBucket, P)           // 分単位で回廊の注目ゾーンをローテ
```

- 決定的ランダムとカテゴリ配分
  - Seed: `dailySeed = HMAC(userId + routeSignature + yyyy-MM-dd)`
  - Run seed: `runSeed = HMAC(dailySeed + HH:mm:ss)`（分・秒で揺らぎ）
  - Gumbel-Top-k: `score' = base + τ * gumbel(runSeed)`（τは0.5〜1.0で時刻に応じ微調整）
  - 層化: レビュー数パーセンタイルで「有名1：中堅1：ロングテール1」
  - ε-グリーディ: 確率εで“冒険枠”を1件ロングテールから差し替え
  - カテゴリ配分: 飲食=1、非飲食=2 を必ず満たす

### Telemetry / Logging

- 候補総数 / 30分通過数 / 最終提示数
- ユーザー行動（表示・クリック・訪問）と `place_id`
- リトライ/フォールバック発生率、APIコール数・レイテンシ

### Caching

- ルートポリライン（origin, dest, mode, 時間帯）: TTL 数分〜15分
- `place_id` の基本情報: 当日TTL
- Matrix結果の短期キャッシュ: 数分

### Configuration

- 回廊幅、レビュー閾値、τ/ε、層化バケット、フォールバック設定などを構成ファイル化。
- Feature flag: `detour.system_picker` で段階的にロールアウト。

### Risks & Mitigations

- APIクォータ超過: バッチ化・キャッシュ強化。上限時は“候補なし”でフェイルセーフ。
- 地点情報の偏り: 有名税・層化・冒険枠で分散を担保。
- 時刻依存の偏り: bucketローテで回廊の注目ゾーンをローテーション。

### Security / Privacy

- seed計算で `userId` を使う場合はHMACなどのハッシュを用い生IDは保持/送信/ログ出力しない。
- 行動ログの保持期間（例: 90日）を明示し、削除要請に応じられる仕組み。

### Rollout Plan

- Feature flag による%段階リリース → 100%切替 → 旧ロジック削除。
- 監視: ゼロ件率・APIエラー率・提示→訪問率。SLO（例: P95 < 2.5s）。

### QA観点 / Test Plan

- 境界値: 30分ちょうど・30分+1秒での除外確認。
- モード別: 車/自転車/徒歩/交通機関で回廊幅と交通考慮が効くこと。
- 分・秒シードの再現性（同秒一致/秒違いで差分）。
- 有名スポット偏重抑制（レビュー上位の連続提示率が閾値以下）。
- 営業中フィルタ（`open_now` 取得可能なケース）。
- レイテンシSLO（例: P95 < 2.5s）。

### Implementation Tasks

- Routes/Directionsで T0 とポリライン取得
- 回廊サンプリング・バッファ生成（モード別パラメータ）
- Places Nearby収集（カテゴリ/重複排除/軽フィルタ）
- Distance/Route Matrixバッチ（`O→P`, `P→D`）
- 30分ハードフィルタ & 0件フォールバック
- スコアリング（Bayesian平均・有名税・既視感ペナルティ）
- 決定的ランダム（seed, Gumbel-Top-k, 層化, ε-グリーディ）
- カテゴリ配分ロジック（飲食1・非飲食2）
- テレメトリ・ログ・アラート
- ユニット/統合テスト（Gherkin準拠）
- 設定化（回廊幅・τ・ε・レビュー閾値）

### Open Questions

- rating 欠損の扱い（通す/落とす/補完値）→ 提案: 通す + Bayesianで救済
- reviews 閾値（5固定の妥当性）→ 地域差で要調整の余地
- `open_now` が取れないスポットの扱い（屋内系のみ厳格？）

---

本RFCは [Issue #6](https://github.com/k-sakQA/DontGoHomeStraight/issues/6) の提案に基づき作成されています。仕様合意後、ADRとして `/docs/adr/XXXX-accepted-waypoint-suggestion-v1.md` に昇格し、本RFCはクローズ（マージ不要）します。


### 詳細設計（Detailed Design）

#### 1. アーキテクチャ（既存構成との整合）

- レイヤ構成
  - `Domain` 層: ユースケースとエンティティ。新規/変更点は下記。
  - `Infrastructure` 層: Google Maps Platform クライアント群（Directions/Distance Matrix/Places/Place Details）。キャッシュ実装。
  - `Presentation` 層: Feature Flag により旧LLM推薦と切替。UIは既存のジャンル提示フローを流用。
- Feature Flag 切替
  - `detour.system_picker` が true の場合に本ロジックを有効化。false の場合は現行LLMベースを維持。

#### 2. ユースケース/リポジトリ I/F

- 追加ユースケース（案）
  - `SystemWaypointSuggestionUseCase`（新設）
    - `pickWaypoints(current, destination, mood, transportMode, now) -> [Place]`
    - Place を返し、最終的に ViewModel でジャンルへマップ
  - 既存 `PlaceRecommendationUseCase` に behind-the-flag で委譲しても良い
- リポジトリ/ゲートウェイ
  - `RouteRepository`
    - `getPrimaryRoute(origin, destination, mode, departureTime) -> (durationSec: Int, polyline: String)`
  - `PlacesRepository`（既存拡張）
    - `nearbySearch(point, radius, categoryFilters, openNow?) -> [Place]`
    - `getDetailsOpenNow(placeId) -> Bool?`
  - `MatrixRepository`
    - `batchDurations(origin, points[], mode) -> [seconds]`
    - `batchDurations(points[], destination, mode) -> [seconds]`
  - `SeededRandomProvider`
    - `gumbel(seed, index) -> Double`
    - `hmacSHA256(key, message) -> Data`
  - `ConfigRepository`
    - 閾値、回廊幅、τ/ε、キャッシュTTL、フォールバック許容量
  - `TelemetryRepository`
    - イベント送信・SLO集計

#### 3. データモデル（Domain）

- `Place`（既存）拡張使用: `placeId, name, coordinate, genre.googleMapType, rating?, reviews?`
- 新規内部DTO
  - `CorridorSample { coordinate: CLLocationCoordinate2D, radiusMeters: Double }`
  - `CandidateSpot { place: Place, category: GenreCategory, durationExtraMin: Double }`
  - `ScoredCandidate { candidate: CandidateSpot, baseScore: Double, noisyScore: Double }`

#### 4. 外部API（Google Maps Platform）

- Directions/Routes API
  - 入力: origin, destination, mode, departure_time=now
  - 出力: `T0`（秒）と overview_polyline
- Places Nearby Search
  - 入力: location（サンプル点）, radius, type/keyword, open_now（条件により）
- Place Details（Open Now）
  - 入力: `place_id`
  - 出力: `opening_hours.open_now`（optional）
- Distance Matrix / Routes Matrix
  - バッチ: `origin -> P[]` と `P[] -> destination`

#### 5. アルゴリズム詳細

- 回廊サンプリング
  - ポリラインをモード別間隔で等間隔サンプル
    - 徒歩: 200m、 自転車: 300m、 車: 400m（設定化、±レンジ内で調整可）
  - 各サンプルに半径 r を付与
    - 徒歩: 150–250m、 自転車: 300–600m、 車: 600–1000m（設定化）
- 候補収集
  - カテゴリごとに Nearby を実行（飲食: `restaurant|cafe|bakery` / 非飲食: `park|museum|art_gallery|tourist_attraction|shrine|temple|viewpoint|spa|onsen`）
  - `place_id` で重複排除
  - 軽いフィルタ: `rating ≥ 3.4 && reviews ≥ 5`（rating 欠損は通す）
- 時間評価
  - `dm1 = durations(origin, P[])`, `dm2 = durations(P[], destination)` を取得
  - 各 P について `T(P) = dm1[i] + dm2[i]`、条件 `T(P) - T0 ≤ 30分`
- スコアリング（ベイズ品質 + 有名税 + 既視感抑制）
  - ベイズ平均: `bayes = (c*m + r*R) / (c + r)`（m=グローバル平均≈3.7, c≈20, r=reviews, R=rating）
  - 既視感ペナルティ: 同一チェーン/300m近接を軽く減点
  - on-route ボーナス: ルート近傍（±X m）にある場合に加点（後続で導入）
- 決定的ランダム
  - `dailySeed = HMAC(userIdHash, routeSignature + yyyy-MM-dd)`
  - `runSeed = HMAC(dailySeed, HH:mm:ss)`
  - Gumbel-Top-k: `noisy = base + τ * Gumbel(runSeed, idx)`、τを秒で [0.5,1.0] 調整
  - 層化: reviews パーセンタイルで bucket を作成し各層から選抜
  - ε-グリーディ: 確率 ε（例: 0.1）でロングテール差し替え
- カテゴリ配分
  - 飲食=1・非飲食=2 を強制。足りないカテゴリは次善候補で補完
- フォールバック
  - 30分通過0件 → 回廊半径 +200m で一度だけ再探索
  - なお0件 → “候補がありません。今日はまっすぐ帰ろっ🎵” を返却

#### 6. エラーハンドリング/レジリエンス

- APIクォータ/429: バックオフ + 本実行では“候補なし”でフェイルセーフ
- タイムアウト: Matrix/Places は P95 を監視し、遅延時は結果を部分利用
- 欠損データ: rating 欠損はベイズで救済、`open_now` 不明は屋内系のみ注意喚起（将来導入）

#### 7. キャッシュ設計

- キー設計
  - ルート: `route:{mode}:{originGrid}:{destGrid}:{hour}` → polyline, T0（TTL: 5–15分）
  - Places: `place:{placeId}:basic`（TTL: 当日）
  - Matrix: `mx:{mode}:{originGrid}:{destGrid}:{bucket}`（TTL: 数分）
- グリッド/バケット
  - 1e-3 度程度でグリッド化しキャッシュヒットを高める

#### 8. テレメトリ/イベント

- `detour.candidate_collected { total, unique, categories, api_ms }`
- `detour.within_30min { passed, failed, t0_sec, p95_ms }`
- `detour.picked { ids[], categories[], used_tau, epsilon_hit }`
- `detour.fallback { expanded_radius, retried }`
- `detour.error { kind, api, httpStatus }`

#### 9. 設定項目（Config）

- 時間上限（分）既定=30、回廊幅、サンプル間隔、レビュー閾値、τ/ε、層化境界、フォールバック半径増分
- Feature flag: `detour.system_picker`

#### 10. 実装計画（リポジトリ構成反映）

- `Infrastructure/API`
  - `GoogleDirectionsClient.swift`（新規）
  - `GoogleDistanceMatrixClient.swift`（新規）
  - `GooglePlaceDetailsOpenClient.swift`（新規）
  - 既存 `GooglePlacesAPIClient.swift` に Nearby 機能を追加
- `Domain/Repositories`
  - `RouteRepository.swift`（新規）
  - `MatrixRepository.swift`（新規）
  - `SeededRandomProvider.swift`（新規）
- `Domain/UseCases`
  - `SystemWaypointSuggestionUseCase.swift`（新規）
  - 既存 `PlaceRecommendationUseCase` からの切替/委譲
- `Presentation/ViewModels`
  - `AppViewModel` でフラグ判定しユースケース選択

#### 11. テスト計画（詳細）

- ユニット
  - ベイズ品質計算、Gumbel-Top-k 決定性、カテゴリ配分、30分境界
- コンポーネント
  - Matrix/Places をスタブして O→P→D 合成の正当性
- 統合
  - モード別パラメータで0件率/レイテンシSLO確認
- 再現性
  - 同一 input と秒固定で結果不変、秒差で候補揺らぎ

#### 12. ロールアウト/監視

- 段階的: 5% → 25% → 50% → 100%
- 監視: ゼロ件率、APIエラー率、提示→訪問率、レイテンシ P95
