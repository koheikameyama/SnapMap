import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/place_search_result.dart';

class LocationService {
  // Google Places API Key（.envから取得）
  String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

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
        return null;
      }

      // 権限をチェック
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // 現在位置を取得
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
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

  // 周辺の場所を取得（Nearby Search）
  Future<List<PlaceSearchResult>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 2000, // 2km圏内
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=$radius&language=ja&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results
              .take(10) // 最大10件に制限
              .map((result) => PlaceSearchResult.fromJson(result))
              .toList();
        } else {
          // エラーの場合は静かに空のリストを返す
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // 場所を検索（Google Places API Text Search）
  Future<List<PlaceSearchResult>> searchPlaces(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      // 現在地があれば位置バイアスを追加
      String location = '';
      if (latitude != null && longitude != null) {
        location = '&location=$latitude,$longitude&radius=5000';
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query$location&language=ja&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results
              .map((result) => PlaceSearchResult.fromJson(result))
              .toList();
        } else {
          // エラーの場合は静かに空のリストを返す
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
