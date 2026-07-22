# Live Activity（ロック画面・Dynamic Island）セットアップ手順

ナビ中に「？？？まで あと○○m」をロック画面と Dynamic Island に常駐表示する機能です。

アプリ本体側の実装（`Infrastructure/LiveActivity/` 配下の開始・距離更新・到着時の種明かし）は
すでに組み込み済みで、**Widget Extension ターゲットを Xcode で追加するだけ**で有効になります。
ターゲットを追加しなくてもアプリ本体は今まで通り動作します（Live Activity が表示されないだけ）。

## 手順（Xcode で約2分）

1. Xcode で `DontGoHomeStraight.xcodeproj` を開く
2. **File > New > Target...** を選択
3. **Widget Extension** を選び **Next**
4. 以下のように設定して **Finish**
   - Product Name: `DontGoHomeStraightWidget`（この名前にすると本リポジトリのフォルダと一致します）
   - **Include Live Activity: チェックを入れる**
   - Include Configuration App Intent: チェックを外す
5. 「Activate scheme?」と聞かれたら **Activate**
6. Xcode がテンプレートとして生成した以下のファイルを削除する（Move to Trash）
   - `DontGoHomeStraightWidget/DontGoHomeStraightWidget.swift`
   - `DontGoHomeStraightWidget/DontGoHomeStraightWidgetBundle.swift`
   - `DontGoHomeStraightWidget/DontGoHomeStraightWidgetLiveActivity.swift`
   - （`Assets.xcassets` は残してOK）
7. 本リポジトリの `DontGoHomeStraightWidget/` フォルダにある以下のファイルを
   Widget ターゲットに追加する（ドラッグ&ドロップ、Target Membership は `DontGoHomeStraightWidgetExtension` のみ）
   - `DontGoHomeStraightWidgetBundle.swift`
   - `DetourLiveActivityWidget.swift`
   - `DetourActivityAttributes.swift`
8. ビルドして実機で確認

## 動作確認

1. アプリで目的地・気分を設定し、寄り道カードを選んで経路案内を開始
2. 端末をロックすると、ロック画面に「？？？？？？ へ寄り道中」とジャンル・ヒント・残り距離が表示される
3. 経由地に近づくと距離と文言が更新され（5秒間隔）、到着すると「ここは「◯◯」でした！」と種明かしされる
4. 到着後30分、またはナビ中断時に表示が消える

## 注意

- `DetourActivityAttributes.swift` は **アプリ本体側**（`DontGoHomeStraight/Infrastructure/LiveActivity/`）にも
  同じ定義があります。両者の構造を一致させてください（一致しないと Live Activity が表示されません）。
- 設定 > アプリ > まっすぐ帰りたくない で「Live Activity」がオンになっている必要があります。
- シミュレータでも動作しますが、Dynamic Island の確認は iPhone 15 Pro 以降のシミュレータ/実機を使ってください。
