import 'package:flutter/material.dart';

enum PostCategory {
  travel,  // 旅行
  gourmet, // グルメ
  people,  // 人
  nature,  // 自然
  other,   // その他
}

extension PostCategoryExtension on PostCategory {
  // 日本語名
  String get displayName {
    switch (this) {
      case PostCategory.travel:
        return '旅行';
      case PostCategory.gourmet:
        return 'グルメ';
      case PostCategory.people:
        return '人';
      case PostCategory.nature:
        return '自然';
      case PostCategory.other:
        return 'その他';
    }
  }

  // アイコン
  IconData get icon {
    switch (this) {
      case PostCategory.travel:
        return Icons.flight_takeoff;
      case PostCategory.gourmet:
        return Icons.restaurant;
      case PostCategory.people:
        return Icons.people;
      case PostCategory.nature:
        return Icons.nature;
      case PostCategory.other:
        return Icons.star;
    }
  }

  // マップマーカーの色
  Color get markerColor {
    switch (this) {
      case PostCategory.travel:
        return Colors.blue;
      case PostCategory.gourmet:
        return Colors.red;
      case PostCategory.people:
        return Colors.orange;
      case PostCategory.nature:
        return Colors.green;
      case PostCategory.other:
        return Colors.purple;
    }
  }

  // マーカー用のHue値（BitmapDescriptor.defaultMarkerWithHue用）
  double get markerHue {
    switch (this) {
      case PostCategory.travel:
        return 210.0; // Blue
      case PostCategory.gourmet:
        return 0.0;   // Red
      case PostCategory.people:
        return 30.0;  // Orange
      case PostCategory.nature:
        return 120.0; // Green
      case PostCategory.other:
        return 270.0; // Purple
    }
  }

  // 文字列からenumに変換
  static PostCategory fromString(String value) {
    switch (value) {
      case '旅行':
      case 'travel':
        return PostCategory.travel;
      case 'グルメ':
      case 'gourmet':
        return PostCategory.gourmet;
      case '人':
      case 'people':
        return PostCategory.people;
      case '自然':
      case 'nature':
        return PostCategory.nature;
      case 'その他':
      case 'other':
        return PostCategory.other;
      // 旧カテゴリからの移行対応
      case '日常':
      case 'daily':
        return PostCategory.other;
      case '風景':
      case 'landscape':
        return PostCategory.nature;
      case '動物':
      case 'animal':
        return PostCategory.nature;
      case '食事':
      case 'food':
        return PostCategory.gourmet;
      default:
        return PostCategory.other; // デフォルト
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
