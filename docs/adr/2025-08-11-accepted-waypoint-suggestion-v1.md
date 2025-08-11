## ADR: waypoint-suggestion-v1 を採択（30分以内の寄り道候補をシステム側で決定）

- 種別: ADR（Architecture Decision Record）
- ステータス: Accepted（採択）
- 決定日: 2025-08-11
- 参照: Issue [#6](https://github.com/k-sakQA/DontGoHomeStraight/issues/6), RFC PR [#7](https://github.com/k-sakQA/DontGoHomeStraight/pull/7), 合意コミット [`405ec4a`](https://github.com/k-sakQA/DontGoHomeStraight/pull/7/commits/405ec4a4840c90e59210781b36dce3ffe991825e)

### Context

OpenAIの出力に依存した候補地提案は、基準ルートから逸脱し「寄り道」定義（基準ルートに対する追加所要時間が30分以内）を満たさない場合がある。日替わりの新鮮さとランダム性も求められる。候補地の探索・評価・選定は地図APIで厳密に行い、LLMは説明文・コピー生成に限定する方針とする。

### Decision

- 追加所要時間のハード上限（30分）を100%満たす候補のみ提示する。
- カテゴリ配分を厳守（飲食30% / 非飲食70%。3件提示なら飲食=1・非飲食=2）。
- 軽い品質フィルタ（rating ≥ 3.4 かつ reviews ≥ 5。閾値は設定化）。
- 決定的ランダム（dailySeed/runSeed; HMAC）。秒単位で揺らぎを与える。
- 0件時フォールバック: 回廊半径を +200m して再探索（1回まで）。
- テレメトリ（収集数・30分通過数・提示数等）と短期キャッシュ（ルート/Matrix）。
- Feature flag `detour.system_picker` の背後で段階リリース。

### Acceptance Criteria（要約）

- 全候補について (T(P) - T0) ≤ 30分。
- 3件提示時、飲食=1・非飲食=2。
- rating=3.4, reviews=5 はフィルタ通過。
- 同一入力・同一タイムスタンプ（秒まで）で決定的（結果不変）。
- 秒差で揺らぎにより候補入れ替えが起こりうる。
- 0件時は回廊半径+200mで再探索。なお0件なら「候補がありません…」を返す。

### Out of Scope

- LLMによる最終選定（表現用途のみ）。
- 30分超過候補の提示。
- ルート可視化UIの刷新、高度な個人最適化。

### Risks & Mitigations

- APIクォータ超過: バッチ/キャッシュ、上限時は“候補なし”でフェイルセーフ。
- 地点偏り: 有名税・層化・冒険枠で分散。
- 時刻依存偏り: bucketローテで回廊の注目ゾーンをローテーション。

### Rollout

- `detour.system_picker` を用いた%段階リリース → 100%切替 → 旧ロジック削除。
- 監視: ゼロ件率、APIエラー率、提示→訪問率、レイテンシ P95。

### QA観点 / Test Plan（要約）

- 境界値: 30分ちょうど/30分+1秒の除外確認。
- モード別: 車/自転車/徒歩/交通機関で回廊幅と交通考慮が効くこと。
- 決定的ランダムの再現性（同秒一致/秒違いで差分）。
- 営業中フィルタ（open_now 対応ケース）。
- SLO: 例 P95 < 2.5s。

### Consequences

- 実装は `feat/waypoint-suggestion-v1` ブランチで行い、当ADRの Acceptance Criteria に準拠する。
- 仕様議論はADR改訂として扱い、実装PRでは仕様議論の揺り戻しを避ける。

