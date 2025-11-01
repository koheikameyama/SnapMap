import 'dart:io';
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
      print('画像アップロードエラー: $e');
      rethrow;
    }
  }

  // 画像を削除
  Future<void> deleteImage(String imageUrl) async {
    try {
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('画像削除エラー: $e');
      rethrow;
    }
  }
}
