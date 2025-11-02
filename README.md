# MapDiary

地図上で写真を共有する Flutter アプリケーション

![Flutter](https://img.shields.io/badge/Flutter-3.19.5-blue)
![Firebase](https://img.shields.io/badge/Firebase-Latest-orange)

## 概要

MapDiary は、位置情報と写真を組み合わせて投稿・共有できるソーシャルマップアプリです。ユーザーは特定の場所で撮影した写真を地図上にピン留めでき、他のユーザーがその場所で最近何があったかを確認できます。

投稿は 30 日間表示され、プライバシーに配慮した設計になっています。

## 主な機能

### 🔐 認証

- **メールアドレス/パスワード認証**
  - サインアップ（表示名設定あり）
  - ログイン
- **Google 認証**
  - Google アカウントでのワンタップログイン

### 📸 投稿機能

- **投稿フロー**: 写真選択 → 設定入力 → 確認 → 投稿完了
- **必須項目**
  - 📷 写真（カメラ撮影 or ギャラリー選択）
  - 🏷️ カテゴリ（日常 / 風景 / 動物 / 食事）
  - 📍 場所（現在地取得 or 場所検索）
- **任意項目**
  - 💬 キャプション
- **投稿時の特徴**
  - Google Places API による場所検索
  - 現在地の自動取得（GPS）
  - プライバシー警告モーダル
  - 30 日間表示の通知

### 🗺️ 地図画面

- **Google Maps 統合**
  - カテゴリごとに色分けされたマーカー
  - マーカータップで投稿詳細へ遷移
- **検索機能**
  - Pill 形状の検索バー（Google Places API）
  - 検索結果から場所選択して地図移動
- **操作**
  - 現在地へ移動ボタン
  - 投稿作成ボタン（カメラアイコン）
  - カテゴリフィルタボタン（開発中）

### 📄 投稿詳細

- 投稿画像（フルサイズ）
- ユーザー情報
  - プロフィール画像
  - 表示名（リアルタイム取得）
  - 投稿日時
- カテゴリ表示
- キャプション
- 場所情報
- ❤️ いいね機能
- メニュー（自分の投稿: 削除 / 他人の投稿: 報告）

### 👤 プロフィール

- **プロフィール編集**
  - 表示名の変更
  - プロフィール画像の設定
  - **変更は既存投稿にも即座に反映**

### 🏷️ カテゴリ

| カテゴリ | アイコン            | マーカー色 |
| -------- | ------------------- | ---------- |
| 日常     | 🏠 Icons.home       | オレンジ   |
| 風景     | 🌄 Icons.landscape  | 緑         |
| 動物     | 🐾 Icons.pets       | ピンク     |
| 食事     | 🍴 Icons.restaurant | 赤         |

## データ仕様

### ⏰ 投稿の表示期限

- **期限**: 投稿から 30 日間
- **動作**: 30 日経過後、地図やリストに表示されなくなる
- **データ保持**: Firestore には削除されずに保存される（将来の機能拡張用）
- **目的**: プライバシー保護とストレージ効率の両立

### 📍 位置情報

- **取得方法**:
  1. 現在地を取得ボタン（Geolocator 使用）
  2. 場所検索（Google Places API Text Search）
- **表示形式**:
  - 場所検索時: 店名や場所名
  - 現在地使用時: `現在地（緯度, 経度）`

### 🔒 プライバシー

- 投稿前のプライバシー警告モーダル
  - 「人物や住居が特定されないように注意してください」
- 30 日間の自動非表示
- 報告機能

## 技術スタック

### フレームワーク

- **Flutter 3.19.5** / **Dart 3.3.3**

### バックエンド

- **Firebase Authentication** - 認証（Email/Password、Google）
- **Cloud Firestore** - NoSQL データベース
- **Firebase Storage** - 画像保存

### 外部 API

- **Google Maps Flutter** - 地図表示
- **Google Places API Text Search** - 場所検索
- **Geolocator** - 位置情報取得

### 主要パッケージ

```yaml
dependencies:
  provider: ^6.1.1 # 状態管理
  google_maps_flutter: ^2.5.0 # 地図UI
  image_picker: ^1.0.7 # 画像選択
  cached_network_image: ^3.3.1 # 画像キャッシュ
  http: ^1.2.0 # Places API通信
  geolocator: ^11.0.0 # 位置情報
  intl: ^0.19.0 # 日時フォーマット
```

## デザインシステム

### 🎨 テーマ

- **カラースキーム**: Material Design 3
- **プライマリカラー**: ソフトブルー `#64B5F6`
- **コンセプト**: 柔らかく普段遣いできるデザイン
- **角丸**: 16px（ボタン、カード）
- **影**: 控えめ（elevation: 0〜2）

### UI 要素

- Pill 形状の検索バー（borderRadius: 28px）
- フローティングアクションボタン
- 必須項目: 赤色の `*` マーク
- 情報ボックス: カラフルな背景色で視認性向上

## Firestore 構造

### Posts Collection

```javascript
posts/
  {postId}/
    userId: string          // 投稿者UID
    userName: string        // 投稿時の表示名（フォールバック用）
    imageUrl: string        // Storage画像URL
    caption: string?        // キャプション（任意）
    latitude: number        // 緯度
    longitude: number       // 経度
    locationName: string?   // 場所名（任意）
    category: string        // カテゴリ
    tags: array            // タグ（将来実装）
    createdAt: timestamp   // 投稿日時
    likesCount: number     // いいね数
```

### Users Collection

```javascript
users/
  {userId}/
    email: string
    displayName: string
    photoUrl: string?      // プロフィール画像URL
    createdAt: timestamp
```

### Reports Collection

```javascript
reports/
  {reportId}/
    postId: string
    reason: string
    createdAt: timestamp
```

## セットアップ

### 必要な環境

- Flutter SDK 3.0 以上
- Dart SDK 3.0 以上
- Android Studio / Xcode
- Firebase プロジェクト
- Google Cloud Console アカウント

### インストール手順

1. **リポジトリをクローン**

```bash
git clone https://github.com/yourusername/MapDiary.git
cd MapDiary
```

2. **依存関係をインストール**

```bash
flutter pub get
```

3. **Firebase のセットアップ**

```bash
# Firebase CLIをインストール
npm install -g firebase-tools

# FlutterFire CLIをインストール
dart pub global activate flutterfire_cli

# Firebaseプロジェクトを設定
flutterfire configure
```

4. **Firebase Console 設定**

   - Authentication 有効化（Email/Password、Google）
   - Firestore Database 作成
   - Firebase Storage 有効化

5. **Google Maps API 設定**

   Google Cloud Console で以下の API を有効化:

   - Places API
   - Maps SDK for Android
   - Maps SDK for iOS

   API Key を取得して設定:

   ```bash
   # android/local.properties
   GOOGLE_MAPS_API_KEY=your_api_key_here

   # .env
   GOOGLE_MAPS_API_KEY=your_api_key_here
   ```

6. **Firestore インデックス作成**

   - 初回実行時、複合インデックスエラーが出る場合があります
   - エラーメッセージのリンクから Firebase Console でインデックスを作成

7. **アプリを実行**

```bash
flutter run
```

## プロジェクト構成

```
lib/
├── main.dart                      # エントリーポイント
├── models/                        # データモデル
│   ├── post.dart                 # 投稿モデル
│   ├── user_model.dart           # ユーザーモデル
│   ├── post_category.dart        # カテゴリEnum
│   └── place_search_result.dart  # 場所検索結果
├── screens/                       # 画面
│   ├── login_screen.dart         # ログイン/サインアップ
│   ├── map_screen.dart           # 地図メイン画面
│   ├── create_post_screen.dart   # 投稿作成
│   ├── post_detail_screen.dart   # 投稿詳細
│   └── profile_edit_screen.dart  # プロフィール編集
├── services/                      # サービス層
│   ├── auth_service.dart         # 認証サービス
│   ├── firestore_service.dart    # Firestoreサービス
│   ├── storage_service.dart      # Storageサービス
│   └── location_service.dart     # 位置情報・Places API
├── providers/                     # 状態管理
│   └── auth_provider.dart        # 認証状態管理
└── firebase_options.dart          # Firebase設定
```

## 使い方

### 1. アカウント作成

- アプリ起動 → サインアップ
- メールアドレス、パスワード、表示名を入力
- または「Google でログイン」を選択

### 2. 投稿作成

1. 地図画面右下のカメラボタンをタップ
2. 写真を選択（カメラ撮影 or ギャラリー）
3. カテゴリを選択（必須）
4. 場所を設定（現在地取得 or 検索）
5. キャプション入力（任意）
6. 「投稿する」ボタンをタップ
7. プライバシー警告を確認して「OK」

### 3. 投稿閲覧

- 地図上のマーカーをタップ
- 投稿詳細画面で画像、情報を確認
- いいねボタンで反応

### 4. プロフィール編集

- 地図画面右上のメニュー → 「プロフィール編集」
- 表示名、プロフィール画像を変更
- 保存すると既存投稿にも反映

## 開発ロードマップ

### ✅ 完了済み

- [x] ユーザー認証（Email/Password、Google）
- [x] 地図表示（Google Maps）
- [x] 写真投稿（カメラ、ギャラリー）
- [x] 場所検索（Places API）
- [x] カテゴリ分類（4 種類）
- [x] プロフィール編集
- [x] プロフィール画像
- [x] いいね機能
- [x] 報告・削除機能
- [x] 30 日間表示期限
- [x] プライバシー警告

### 🚧 開発中

- [ ] カテゴリフィルタ（UI は実装済み）

### 📋 将来の拡張予定

- [ ] コメント機能
- [ ] タグ機能
- [ ] フォロー機能
- [ ] 通知機能
- [ ] ユーザー投稿履歴（30 日以上前も含む）
- [ ] 管理画面
- [ ] 古いデータ自動削除（Cloud Functions）
- [ ] ダークモード
- [ ] 多言語対応

## トラブルシューティング

### よくある問題

**Q: Google Maps API エラーが出る**

- A: API Key が正しく設定されているか確認
- A: Google Cloud Console で Maps SDK、Places API が有効化されているか確認

**Q: Firestore インデックスエラー**

- A: エラーメッセージのリンクからインデックス作成（数分で完了）

**Q: 位置情報が取得できない**

- A: アプリに位置情報権限が許可されているか確認
- A: 端末の GPS が有効になっているか確認

**Q: プロフィール画像が表示されない**

- A: Firebase Storage の読み取り権限を確認
- A: 画像 URL が正しく保存されているか Firestore Console で確認

## ライセンス

このプロジェクトは開発中です。

## 謝辞

- Flutter チーム
- Firebase チーム
- Google Maps Platform

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Made with ❤️ by MapDiary Team
