# VSCode/Cursor デバッグ設定

## セットアップ

### 1. 必要な拡張機能のインストール

Cursorの拡張機能パネルで以下をインストール：
- **Dart** (dart-code.dart-code)
- **Flutter** (dart-code.flutter)

推奨拡張機能：
- Flutter Snippets (alexisvt.flutter-snippets)
- Awesome Flutter Snippets (nash.awesome-flutter-snippets)

### 2. デバイスの接続

**Android:**
1. デバイスでUSBデバッグを有効化
2. USBケーブルでMacに接続
3. 「USBデバッグを許可しますか？」を許可

**iOS:**
1. デバイスとMacを同じWi-Fiに接続
2. Xcode > Window > Devices and Simulators でペアリング
3. 「このコンピュータを信頼しますか？」を許可

確認コマンド：
```bash
flutter devices
```

## デバッグの開始方法

### 方法1: デバッグパネルから（推奨）

1. Cursorの左サイドバーから「デバッグ」アイコンをクリック（虫マーク）
2. 上部のドロップダウンから設定を選択：
   - **Flutter: Debug (Android実機)** - Android端末でデバッグ
   - **Flutter: Debug (iPhone実機)** - iPhone実機でデバッグ
   - **Flutter: Debug (デバイス選択)** - 起動時にデバイスを選択
3. 緑色の再生ボタン（▶️）をクリック

### 方法2: キーボードショートカット

- **F5**: デバッグ開始
- **Shift + F5**: デバッグ停止
- **Cmd + Shift + F5** (Mac): ホットリスタート

### 方法3: コマンドパレット

1. **Cmd + Shift + P** (Mac) でコマンドパレットを開く
2. 「Flutter: Select Device」でデバイスを選択
3. 「Flutter: Run Flutter」でデバッグ開始

## デバッグ中の操作

### ホットリロード
- **r**: ターミナルでrを入力、またはファイル保存時に自動リロード
- コードの変更が即座に反映されます

### ホットリスタート
- **R**: ターミナルでRを入力
- **Cmd + Shift + F5**: VSCode/Cursorから実行
- アプリを完全に再起動（状態がリセット）

### ブレークポイント
1. コードの行番号左側をクリックして赤い点を追加
2. その行が実行されるとデバッガーが一時停止
3. 変数の値を確認したり、ステップ実行が可能

### デバッグコンソール
- **Debug Console**タブで変数の値を確認
- 式を評価したり、オブジェクトを調査できます

## トラブルシューティング

### デバイスが認識されない

**Android:**
```bash
# ADBデバイスを確認
adb devices

# ADBサーバーを再起動
adb kill-server
adb start-server
```

**iOS:**
```bash
# デバイスを確認
flutter devices

# iproxyをインストール（必要な場合）
brew install libimobiledevice
```

### ビルドエラー

```bash
# 依存関係を再インストール
flutter clean
flutter pub get

# Androidのビルドキャッシュをクリア
cd android && ./gradlew clean && cd ..

# iOSのビルドキャッシュをクリア
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
```

### ホットリロードが動作しない

1. **Cmd + Shift + P** → 「Flutter: Hot Reload」を実行
2. それでもダメなら **ホットリスタート** (R)
3. 完全に再ビルド: デバッグを停止して再度開始

## モード別の違い

### Debug モード
- デバッグ機能が有効
- ホットリロード/リスタートが使える
- パフォーマンスは低い
- 開発中に使用

### Profile モード
- パフォーマンス分析が可能
- ホットリロードは無効
- リリースに近いパフォーマンス
- パフォーマンステスト時に使用

### Release モード
- 最高のパフォーマンス
- デバッグ機能なし
- リリース前の最終確認に使用

## 便利なショートカット

| 操作 | ショートカット |
|------|---------------|
| デバッグ開始 | F5 |
| デバッグ停止 | Shift + F5 |
| ホットリスタート | Cmd + Shift + F5 |
| コマンドパレット | Cmd + Shift + P |
| クイックフィックス | Cmd + . |
| 定義へジャンプ | F12 |
| 参照を検索 | Shift + F12 |
| ファイル内検索 | Cmd + F |
| プロジェクト内検索 | Cmd + Shift + F |
