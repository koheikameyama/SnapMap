import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // 位置情報の権限を確認してリクエスト
  Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      // 権限が拒否された場合
      return false;
    } else if (status.isPermanentlyDenied) {
      // 権限が完全に拒否された場合、設定画面を開く
      await openAppSettings();
      return false;
    }

    return false;
  }

  // 現在位置を取得
  Future<Position?> getCurrentLocation() async {
    try {
      // 位置情報サービスが有効かチェック
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('位置情報サービスが無効です');
        return null;
      }

      // 権限をチェック
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('位置情報の権限が拒否されました');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('位置情報の権限が完全に拒否されました');
        return null;
      }

      // 現在位置を取得
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('位置情報取得エラー: $e');
      return null;
    }
  }

  // 位置情報の変更を監視
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10メートル移動したら更新
      ),
    );
  }

  // 2点間の距離を計算（メートル単位）
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
