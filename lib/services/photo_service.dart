import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoService {
  // 最近の写真を取得（指定日数以内）
  Future<List<File>> getRecentPhotos({int days = 7}) async {
    try {
      // 権限をリクエスト
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth) {
        return [];
      }

      // 最終チェック日時を取得
      final prefs = await SharedPreferences.getInstance();
      final lastCheckTime = prefs.getInt('last_photo_check') ?? 0;
      final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckTime);

      // 指定日数前の日時を計算
      final sinceDate = DateTime.now().subtract(Duration(days: days));

      // アルバムを取得（カメラロール）
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true, // カメラロールのみ
      );

      if (albums.isEmpty) {
        return [];
      }

      // 最新の写真を取得（最大10枚）
      final recentAssets = await albums.first.getAssetListRange(
        start: 0,
        end: 10,
      );

      // 最終チェック以降の写真のみをフィルタリング
      List<File> recentPhotos = [];
      for (var asset in recentAssets) {
        // 最終チェック以降 かつ 指定日数以内の写真
        if (asset.createDateTime.isAfter(lastCheck) &&
            asset.createDateTime.isAfter(sinceDate)) {
          final file = await asset.file;
          if (file != null) {
            recentPhotos.add(file);
          }
        }
      }

      // 最終チェック日時を更新
      await prefs.setInt(
        'last_photo_check',
        DateTime.now().millisecondsSinceEpoch,
      );

      return recentPhotos;
    } catch (e) {
      return [];
    }
  }

  // 最終チェック日時をリセット（初回起動時など）
  Future<void> resetLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_photo_check');
  }

  // 写真権限をチェック
  Future<bool> checkPhotoPermission() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    return ps.isAuth;
  }
}
