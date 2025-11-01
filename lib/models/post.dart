import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String imageUrl;
  final String? caption;
  final double latitude;
  final double longitude;
  final String category;
  final List<String> tags;
  final DateTime createdAt;
  final int likesCount;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.imageUrl,
    this.caption,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.tags,
    required this.createdAt,
    this.likesCount = 0,
  });

  // Firestoreドキュメントから変換
  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'],
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      category: data['category'] ?? 'その他',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: data['likesCount'] ?? 0,
    );
  }

  // Firestoreに保存する形式に変換
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'imageUrl': imageUrl,
      'caption': caption,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
    };
  }
}
