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
    required String userId,
  }) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
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
  Stream<List<Post>> getAllPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        // 一時的にorderByをコメントアウト（インデックス作成後に戻す）
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // クライアント側でソート
      final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  // 特定のカテゴリの投稿を取得
  Stream<List<Post>> getPostsByCategory(String category, String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        // 一時的にorderByをコメントアウト（インデックス作成後に戻す）
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // クライアント側でソート
      final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  // 特定のユーザーの投稿を取得
  Stream<List<Post>> getPostsByUser(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        // 一時的にorderByをコメントアウト（インデックス作成後に戻す）
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // クライアント側でソート
      final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
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

  // 投稿を更新
  Future<void> updatePost(String postId, {String? caption, String? category}) async {
    try {
      Map<String, dynamic> updates = {};
      if (caption != null) updates['caption'] = caption;
      if (category != null) updates['category'] = category;

      await _firestore.collection('posts').doc(postId).update(updates);
    } catch (e) {
      print('投稿更新エラー: $e');
      rethrow;
    }
  }
}
