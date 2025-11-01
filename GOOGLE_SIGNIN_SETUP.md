# Google Sign-In セットアップガイド

Google Sign-Inの実装が完了しました。Firebase Consoleでの設定を行う必要があります。

## 1. SHA-1フィンガープリントの取得

### デバッグ用のSHA-1（開発時）

```bash
cd android
./gradlew signingReport
```

または

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**SHA-1フィンガープリント**をコピーしてください。
例: `A1:B2:C3:D4:E5:F6:...`

### リリース用のSHA-1（本番環境）

リリースビルド用のキーストアがある場合：

```bash
keytool -list -v -keystore /path/to/your-release-key.jks -alias your-key-alias
```

## 2. Firebase Consoleでの設定

### 手順：

1. [Firebase Console](https://console.firebase.google.com/) にアクセス

2. プロジェクト「snapmap-b7266」を選択

3. **左メニュー** → 「プロジェクトの設定」（⚙️アイコン）

4. **「マイアプリ」セクション** → Androidアプリを選択

5. **「SHA証明書フィンガープリント」** セクションで：
   - 「証明書を追加」をクリック
   - 上記で取得した**SHA-1フィンガープリント**を貼り付け
   - 「保存」をクリック

6. **google-services.jsonをダウンロード**
   - 「google-services.json」ボタンをクリックしてダウンロード
   - `android/app/google-services.json` に配置

## 3. Firebase AuthenticationでGoogle Sign-Inを有効化

1. Firebase Console → 左メニュー「Authentication」

2. 「Sign-in method」タブをクリック

3. 「Google」を選択

4. 「有効にする」をONに切り替え

5. **プロジェクトのサポートメール**を選択（必須）

6. 「保存」をクリック

## 4. iOS設定（iOSでも使用する場合）

### Info.plistに追加：

`ios/Runner/Info.plist` を開いて、以下を追加：

```xml
<!-- Google Sign-In -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <!-- Firebase ConsoleのiOSアプリ設定から取得したREVERSED_CLIENT_ID -->
      <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
    </array>
  </dict>
</array>
```

**REVERSED_CLIENT_IDの取得方法：**

1. `ios/Runner/GoogleService-Info.plist` を開く
2. `REVERSED_CLIENT_ID` の値をコピー
3. 上記の`YOUR-CLIENT-ID`部分を置き換え

## 5. 動作確認

1. アプリをビルド＆実行

```bash
flutter run
```

2. ログイン画面で「Googleでログイン」ボタンをタップ

3. Googleアカウント選択画面が表示される

4. アカウントを選択してログイン

5. マップ画面に遷移すれば成功！

## トラブルシューティング

### エラー: PlatformException(sign_in_failed)

**原因:** SHA-1フィンガープリントが設定されていない、または間違っている

**解決策:**
1. SHA-1フィンガープリントを再確認
2. Firebase Consoleで正しく設定されているか確認
3. google-services.jsonを再ダウンロードして配置
4. アプリを完全に再ビルド: `flutter clean && flutter run`

### エラー: ApiException: 10

**原因:** google-services.jsonが正しく配置されていない

**解決策:**
1. `android/app/google-services.json` が存在するか確認
2. Firebase Consoleから最新版をダウンロード
3. アプリを再ビルド

### エラー: Developer Error

**原因:** OAuth クライアントIDの設定が正しくない

**解決策:**
1. Firebase Console → Authentication → Sign-in method → Googleが有効か確認
2. Google Cloud Console → 認証情報でOAuthクライアントIDを確認

## セキュリティ注意事項

- ✅ `google-services.json` は `.gitignore` に追加済み
- ✅ リリースビルドには必ずリリース用のSHA-1を使用
- ✅ 本番環境では適切なOAuth同意画面を設定

## 完了チェックリスト

- [ ] SHA-1フィンガープリントを取得
- [ ] Firebase ConsoleでSHA-1を設定
- [ ] google-services.jsonをダウンロードして配置
- [ ] Firebase AuthenticationでGoogle Sign-Inを有効化
- [ ] アプリで動作確認
- [ ] iOS設定（iOSを使用する場合）
