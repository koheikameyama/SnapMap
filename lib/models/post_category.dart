import 'package:flutter/material.dart';

enum PostCategory {
  daily,     // 日常
  landscape, // 風景
  animal,    // 動物
  food,      // 食事
}

extension PostCategoryExtension on PostCategory {
  // 日本語名
  String get displayName {
    switch (this) {
      case PostCategory.daily:
        return '日常';
      case PostCategory.landscape:
        return '風景';
      case PostCategory.animal:
        return '動物';
      case PostCategory.food:
        return '食事';
    }
  }

  // アイコン
  IconData get icon {
    switch (this) {
      case PostCategory.daily:
        return Icons.calendar_today;
      case PostCategory.landscape:
        return Icons.landscape;
      case PostCategory.animal:
        return Icons.pets;
      case PostCategory.food:
        return Icons.restaurant;
    }
  }

  // マップマーカーの色
  Color get markerColor {
    switch (this) {
      case PostCategory.daily:
        return Colors.blue;
      case PostCategory.landscape:
        return Colors.green;
      case PostCategory.animal:
        return Colors.orange;
      case PostCategory.food:
        return Colors.red;
    }
  }

  // マーカー用のHue値（BitmapDescriptor.defaultMarkerWithHue用）
  double get markerHue {
    switch (this) {
      case PostCategory.daily:
        return 210.0; // Blue
      case PostCategory.landscape:
        return 120.0; // Green
      case PostCategory.animal:
        return 30.0;  // Orange
      case PostCategory.food:
        return 0.0;   // Red
    }
  }

  // 文字列からenumに変換
  static PostCategory fromString(String value) {
    switch (value) {
      case '日常':
      case 'daily':
        return PostCategory.daily;
      case '風景':
      case 'landscape':
        return PostCategory.landscape;
      case '動物':
      case 'animal':
        return PostCategory.animal;
      case '食事':
      case 'food':
        return PostCategory.food;
      default:
        return PostCategory.daily; // デフォルト
    }
  }

  // enumを文字列に変換（Firestore保存用）
  String toFirestoreString() {
    return displayName;
  }

  // value プロパティ（保存用の文字列）
  String get value {
    return displayName;
  }
}
