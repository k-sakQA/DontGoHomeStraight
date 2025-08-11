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

