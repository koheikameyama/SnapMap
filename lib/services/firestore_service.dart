import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 投稿を作成
  Future<String> createPost(Post post) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('posts')
          .add(post.toFirestore());
      return docRef.id;
    } catch (e) {
      print('投稿作成エラー: $e');
      rethrow;
    }
  }

  // 指定範囲内の投稿を取得（地図表示用）
  Stream<List<Post>> getPostsInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) {
    return _firestore
        .collection('posts')
        .where('latitude', isGreaterThanOrEqualTo: minLat)
        .where('latitude', isLessThanOrEqualTo: maxLat)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .where((post) => post.longitude >= minLng && post.longitude <= maxLng)
          .toList();
    });
  }

  // すべての投稿を取得
  Stream<List<Post>> getAllPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  // 特定のカテゴリの投稿を取得
  Stream<List<Post>> getPostsByCategory(String category) {
    return _firestore
        .collection('posts')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  // 特定のユーザーの投稿を取得
  Stream<List<Post>> getPostsByUser(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    });
  }

  // 投稿にいいねを追加
  Future<void> likePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likesCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('いいねエラー: $e');
      rethrow;
    }
  }

  // 投稿を削除
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      print('投稿削除エラー: $e');
      rethrow;
    }
  }

  // 投稿を報告
  Future<void> reportPost(String postId, String reason) async {
    try {
      await _firestore.collection('reports').add({
        'postId': postId,
        'reason': reason,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      print('報告エラー: $e');
      rethrow;
    }
  }
}
