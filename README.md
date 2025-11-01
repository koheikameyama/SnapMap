# SnapMap

地図上で写真を共有するモバイルアプリケーション

![Flutter](https://img.shields.io/badge/Flutter-3.19.5-blue)
![Firebase](https://img.shields.io/badge/Firebase-Latest-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## 概要

SnapMapは、地図上で写真を共有できるモバイルアプリケーションです。ユーザーは写真を撮影または選択し、位置情報と共に投稿することができます。他のユーザーの投稿を地図上で見ることができ、猫・風景・旅行・日常など、さまざまなカテゴリの写真を楽しむことができます。

## 主な機能

- **ユーザー認証**: Firebase Authenticationによるメール/パスワード認証
- **地図表示**: Google Mapsを使用した投稿の可視化
- **写真投稿**: カメラ撮影またはギャラリーから写真を選択して投稿
- **位置情報**: 自動的に現在地を取得し、投稿に紐付け
- **カテゴリ分類**: 猫、風景、旅行、日常などのカテゴリで投稿を分類
- **いいね機能**: 投稿にいいねを付ける
- **報告機能**: 不適切な投稿を報告
- **投稿削除**: 自分の投稿を削除

## スクリーンショット

（開発中）

## 技術スタック

### フロントエンド
- **Flutter 3.19.5**: クロスプラットフォームUIフレームワーク
- **Dart 3.3.3**: プログラミング言語

### バックエンド
- **Firebase Authentication**: ユーザー認証
- **Cloud Firestore**: NoSQLデータベース
- **Firebase Storage**: 画像ストレージ

### 地図
- **Google Maps Flutter**: 地図表示

### その他のライブラリ
- **Provider**: 状態管理
- **image_picker**: 画像選択
- **geolocator**: 位置情報取得
- **permission_handler**: 権限管理
- **cached_network_image**: 画像キャッシング

## プロジェクト構成

```
lib/
├── main.dart                 # アプリのエントリーポイント
├── models/                   # データモデル
│   ├── post.dart            # 投稿モデル
│   └── user_model.dart      # ユーザーモデル
├── screens/                  # 画面
│   ├── login_screen.dart    # ログイン画面
│   ├── map_screen.dart      # 地図画面
│   ├── create_post_screen.dart  # 投稿作成画面
│   └── post_detail_screen.dart  # 投稿詳細画面
├── services/                 # サービス層
│   ├── auth_service.dart    # 認証サービス
│   ├── firestore_service.dart  # Firestoreサービス
│   ├── storage_service.dart    # Storageサービス
│   └── location_service.dart   # 位置情報サービス
├── providers/                # 状態管理
│   └── auth_provider.dart   # 認証状態管理
├── widgets/                  # 再利用可能なウィジェット
└── utils/                    # ユーティリティ
```

## セットアップ

### 必要な環境

- Flutter SDK 3.0以上
- Dart SDK 3.0以上
- Android Studio / Xcode
- Firebase プロジェクト
- Google Maps APIキー

### インストール手順

1. **リポジトリをクローン**

```bash
git clone https://github.com/yourusername/SnapMap.git
cd SnapMap
```

2. **依存関係をインストール**

```bash
flutter pub get
```

3. **Firebaseのセットアップ**

詳細は [SETUP.md](SETUP.md) を参照してください。

```bash
# Firebase CLIをインストール
npm install -g firebase-tools

# FlutterFire CLIをインストール
dart pub global activate flutterfire_cli

# Firebaseプロジェクトを設定
flutterfire configure
```

4. **Google Maps APIキーを設定**

- Android: `android/app/src/main/AndroidManifest.xml`の`YOUR_GOOGLE_MAPS_API_KEY_HERE`を置き換え
- iOS: `ios/Runner/Info.plist`の`YOUR_GOOGLE_MAPS_API_KEY_HERE`を置き換え

5. **アプリを実行**

```bash
flutter run
```

## 使い方

1. **アカウント作成**: アプリを起動し、メールアドレスとパスワードでアカウントを作成
2. **ログイン**: 作成したアカウントでログイン
3. **投稿作成**: 右下の青いボタンをタップして写真を撮影または選択
4. **カテゴリ選択**: 投稿のカテゴリを選択
5. **投稿**: 「投稿する」ボタンをタップ
6. **地図表示**: 地図上にピンが表示され、タップすると投稿詳細を確認できます

## 開発ロードマップ

### フェーズ1: MVP（完了）
- [x] ユーザー認証
- [x] 地図表示
- [x] 写真投稿
- [x] 投稿閲覧
- [x] いいね機能
- [x] 報告機能

### フェーズ2: 機能拡張（予定）
- [ ] コメント機能
- [ ] カテゴリフィルター
- [ ] ユーザープロフィール
- [ ] フォロー機能
- [ ] 通知機能
- [ ] 検索機能
- [ ] タグ機能

### フェーズ3: 改善（予定）
- [ ] パフォーマンス最適化
- [ ] オフライン対応
- [ ] 多言語対応
- [ ] ダークモード
- [ ] アニメーション強化

## トラブルシューティング

一般的な問題と解決方法については [SETUP.md](SETUP.md) のトラブルシューティングセクションを参照してください。

## 貢献

貢献を歓迎します！以下の手順で貢献できます：

1. このリポジトリをフォーク
2. 新しいブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add amazing feature'`)
4. ブランチにプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを作成

## ライセンス

このプロジェクトはMITライセンスの下でライセンスされています。

## お問い合わせ

質問やフィードバックがある場合は、Issuesを作成してください。

## 謝辞

- Flutter チーム
- Firebase チーム
- すべてのコントリビューター

---

Made with ❤️ by SnapMap Team
