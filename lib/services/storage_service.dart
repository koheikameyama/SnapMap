import 'dart:io';
import 'dart:developer' as developer;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 画像をアップロード
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      // ファイル名を生成（タイムスタンプ + ユーザーID + 元のファイル名）
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = '${userId}_${timestamp}${path.extension(imageFile.path)}';

      // ストレージ参照を作成
      Reference ref = _storage.ref().child('posts').child(fileName);

      // ファイルをアップロード
      UploadTask uploadTask = ref.putFile(imageFile);

      // アップロード完了を待つ
      TaskSnapshot snapshot = await uploadTask;

      // ダウンロードURLを取得
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      developer.log('画像アップロードエラー', error: e, name: 'StorageService');
      rethrow;
    }
  }

  // プロフィール画像をアップロード
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      // ファイル名を生成（ユーザーID + タイムスタンプ）
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = '${userId}_${timestamp}${path.extension(imageFile.path)}';

      // ストレージ参照を作成（profile_imagesフォルダ）
      Reference ref = _storage.ref().child('profile_images').child(fileName);

      // ファイルをアップロード
      UploadTask uploadTask = ref.putFile(imageFile);

      // アップロード完了を待つ
      TaskSnapshot snapshot = await uploadTask;

      // ダウンロードURLを取得
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      developer.log('プロフィール画像アップロードエラー', error: e, name: 'StorageService');
      rethrow;
    }
  }

  // 画像を削除
  Future<void> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      developer.log('画像削除エラー', error: e, name: 'StorageService');
      rethrow;
    }
  }
}
