import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../models/post_category.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import 'edit_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // 投稿を削除
  void _deletePost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('投稿を削除'),
        content: const Text('この投稿を削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestoreService.deletePost(widget.post.id);
                if (mounted) {
                  Navigator.of(context).pop(); // ダイアログを閉じる
                  Navigator.of(context).pop(); // 詳細画面を閉じる
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('投稿を削除しました')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('削除に失敗しました: $e')),
                  );
                }
              }
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwnPost = authProvider.user?.uid == widget.post.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿詳細'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (isOwnPost) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPostScreen(post: widget.post),
                  ),
                );
                // 更新された場合は画面を再読み込み
                if (result == true && mounted) {
                  Navigator.pop(context);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePost,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 画像
            CachedNetworkImage(
              imageUrl: widget.post.imageUrl,
              height: 400,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 400,
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 400,
                color: Colors.grey[200],
                child: const Icon(Icons.error, size: 64),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日時
                  Text(
                    DateFormat('yyyy/MM/dd HH:mm').format(widget.post.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // カテゴリ
                  Builder(
                    builder: (context) {
                      final category = PostCategoryExtension.fromString(widget.post.category);
                      return Chip(
                        avatar: Icon(category.icon, size: 18, color: category.markerColor),
                        label: Text(category.displayName),
                        backgroundColor: category.markerColor.withOpacity(0.2),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // キャプション
                  if (widget.post.caption != null &&
                      widget.post.caption!.isNotEmpty) ...[
                    Text(
                      widget.post.caption!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 位置情報
                  if (widget.post.locationName != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.place,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.post.locationName!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
