# MapDiary セットアップガイド

このガイドでは、MapDiary アプリのセットアップ方法を説明します。

## 必要な環境

- Flutter 3.0 以上
- Dart 3.0 以上
- Firebase アカウント
- Google Maps API キー

## 1. Firebase プロジェクトのセットアップ

### 1.1 Firebase プロジェクトを作成

1. [Firebase Console](https://console.firebase.google.com/)にアクセス
2. 「プロジェクトを追加」をクリック
3. プロジェクト名を「MapDiary」として作成

### 1.2 Firebase CLI をインストール

```bash
# Firebase CLIをインストール
npm install -g firebase-tools

# Firebaseにログイン
firebase login

# FlutterFire CLIをインストール
dart pub global activate flutterfire_cli
```

### 1.3 Flutter アプリと Firebase を連携

プロジェクトのルートディレクトリで以下を実行：

```bash
flutterfire configure
```

プロンプトに従って：

- 既存の Firebase プロジェクト「MapDiary」を選択
- iOS、Android、Web、macOS などプラットフォームを選択
- `firebase_options.dart`ファイルが自動生成されます

### 1.4 Firebase Authentication を有効化

1. Firebase Console で「Authentication」を選択
2. 「始める」をクリック
3. 「メール/パスワード」を有効化

### 1.5 Cloud Firestore を作成

1. Firebase Console で「Firestore Database」を選択
2. 「データベースの作成」をクリック
3. **本番モード**または**テストモード**で開始
   - テストモードの場合は後でセキュリティルールを設定してください

#### Firestore セキュリティルール（例）

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザー情報の読み取りは全員、書き込みは本人のみ
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // 投稿の読み取りは全員、作成は認証済みユーザー、削除は本人のみ
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }

    // 報告は認証済みユーザーのみ作成可能
    match /reports/{reportId} {
      allow read: if false; // 管理者のみ
      allow create: if request.auth != null;
    }
  }
}
```

### 1.6 Firebase Storage を有効化

1. Firebase Console で「Storage」を選択
2. 「始める」をクリック
3. デフォルトのセキュリティルールで開始

#### Storage セキュリティルール（例）

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /posts/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
                   && request.resource.size < 5 * 1024 * 1024 // 5MB以下
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

## 2. Google Maps API キーの取得

### 2.1 Google Cloud Console でプロジェクトを作成

1. [Google Cloud Console](https://console.cloud.google.com/)にアクセス
2. 新しいプロジェクトを作成または既存のプロジェクトを選択

### 2.2 Maps SDK for Android/iOS を有効化

1. 「API とサービス」→「ライブラリ」を選択
2. 「Maps SDK for Android」を検索して有効化
3. 「Maps SDK for iOS」を検索して有効化

### 2.3 API キーを作成

1. 「API とサービス」→「認証情報」を選択
2. 「認証情報を作成」→「API キー」を選択
3. API キーをコピー

## 3. Android 設定

### 3.1 AndroidManifest.xml を編集

`android/app/src/main/AndroidManifest.xml`に以下を追加：

```xml
<manifest ...>
    <application ...>
        <!-- Google Maps APIキー -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_GOOGLE_MAPS_API_KEY"/>

        ...
    </application>

    <!-- 権限 -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
</manifest>
```

### 3.2 build.gradle を編集

`android/app/build.gradle`で`minSdkVersion`を確認：

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // 21以上を推奨
        ...
    }
}
```

## 4. iOS 設定

### 4.1 Info.plist を編集

`ios/Runner/Info.plist`に以下を追加：

```xml
<dict>
    <!-- Google Maps APIキー -->
    <key>GMSApiKey</key>
    <string>YOUR_GOOGLE_MAPS_API_KEY</string>

    <!-- 位置情報の使用許可 -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>地図上に投稿を表示するために位置情報を使用します</string>

    <!-- カメラの使用許可 -->
    <key>NSCameraUsageDescription</key>
    <string>写真を撮影するためにカメラを使用します</string>

    <!-- フォトライブラリの使用許可 -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>写真を選択するためにフォトライブラリにアクセスします</string>

    ...
</dict>
```

### 4.2 Podfile を編集（必要に応じて）

`ios/Podfile`で最小バージョンを確認：

```ruby
platform :ios, '12.0'  # 12.0以上を推奨
```

## 5. main.dart を更新

`lib/main.dart`のコメントアウトされた Firebase 初期化を有効化：

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
```

## 6. 依存関係をインストール

```bash
flutter pub get
```

## 7. アプリを実行

```bash
# Android
flutter run

# iOS
flutter run

# デバッグビルド
flutter run --debug

# リリースビルド
flutter run --release
```

## トラブルシューティング

### Firebase の初期化エラー

- `flutterfire configure`を再実行
- `firebase_options.dart`が生成されているか確認

### Google Maps が表示されない

- API キーが正しく設定されているか確認
- Google Cloud Console で Maps SDK が有効化されているか確認
- API キーの制限を確認（開発時は制限なしを推奨）

### 位置情報が取得できない

- AndroidManifest.xml/Info.plist に権限が追加されているか確認
- 実機で動作確認（シミュレータでは位置情報が正しく動作しないことがある）

### 画像アップロードが失敗する

- Firebase Storage のセキュリティルールで writePermission が許可されているか確認
- ファイルサイズ制限を確認

## サンプルデータの追加

初期状態では投稿がないため、Firebase Console から手動でサンプル投稿を追加することをおすすめします。

### Firestore にサンプル投稿を追加

1. Firebase Console で「Firestore Database」を開く
2. 「posts コレクション」を作成
3. ドキュメントを追加：

```json
{
  "userId": "sample_user",
  "userName": "サンプルユーザー",
  "imageUrl": "https://example.com/sample.jpg",
  "caption": "サンプル投稿です",
  "latitude": 35.6812,
  "longitude": 139.7671,
  "category": "猫",
  "tags": [],
  "createdAt": "2024-01-01T00:00:00.000Z",
  "likesCount": 0
}
```

## 次のステップ

- ユーザーアカウントを作成してログイン
- 写真を投稿して地図上で確認
- いいね機能やコメント機能の追加（オプション）
- カテゴリフィルター機能の実装

## 参考リンク

- [FlutterFire 公式ドキュメント](https://firebase.flutter.dev/)
- [Google Maps Flutter 公式ドキュメント](https://pub.dev/packages/google_maps_flutter)
- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
