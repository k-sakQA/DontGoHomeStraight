# APIキーの設定方法

このアプリでは、以下のAPIキーが必要です：
- OpenAI API Key
- Google Places API Key

## セットアップ手順（推奨）

### 1. Config.plistファイルを作成

1. `DontGoHomeStraight/App/Config/Config.sample.plist` を同じフォルダにコピー
2. ファイル名を `Config.plist` に変更
3. 実際のAPIキーを記載

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>OPENAI_API_KEY</key>
	<string>sk-実際のOpenAI APIキー</string>
	<key>GOOGLE_PLACES_API_KEY</key>
	<string>実際のGoogle Places APIキー</string>
</dict>
</plist>
```

### 2. Xcodeプロジェクトに追加

1. XcodeでConfig.plistファイルをプロジェクトに追加
2. Target membershipを確認してアプリのターゲットにチェック

## 安全性について

- `Config.plist` は `.gitignore` に追加済みで、GitHubにアップロードされません
- `Config.sample.plist` はサンプルファイルとしてGitHubに保存されます
- 実際のAPIキーはローカル環境にのみ保存されます

## APIキーの取得方法

### OpenAI API Key
1. [OpenAI Platform](https://platform.openai.com/) にアクセス
2. アカウント作成・ログイン
3. API Keys セクションで新しいキーを作成

### Google Places API Key
1. [Google Cloud Console](https://console.cloud.google.com/) にアクセス
2. プロジェクトを作成
3. **Places API** を有効化
4. 認証情報でAPIキーを作成
5. APIキーの制限で「Places API」を選択

## トラブルシューティング

アプリ実行時にAPIキーのエラーが出る場合：
1. Config.plistファイルがプロジェクトに追加されているか確認
2. APIキーが正しく記載されているか確認
3. デバッグコンソールでWarningメッセージを確認