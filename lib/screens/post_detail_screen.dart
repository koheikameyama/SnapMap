import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../models/post_category.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.post.likesCount;
  }

  // いいねボタンを押す
  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
    });

    try {
      if (_isLiked) {
        await _firestoreService.likePost(widget.post.id);
      }
    } catch (e) {
      // エラーが発生した場合、状態を元に戻す
      setState(() {
        _isLiked = !_isLiked;
        _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }

  // 報告ダイアログを表示
  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('投稿を報告'),
        content: const Text('この投稿を不適切なコンテンツとして報告しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestoreService.reportPost(
                  widget.post.id,
                  '不適切なコンテンツ',
                );
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('報告を送信しました')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('報告の送信に失敗しました: $e')),
                  );
                }
              }
            },
            child: const Text('報告', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deletePost();
              } else if (value == 'report') {
                _showReportDialog();
              }
            },
            itemBuilder: (context) => [
              if (isOwnPost)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('削除'),
                    ],
                  ),
                ),
              if (!isOwnPost)
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('報告'),
                    ],
                  ),
                ),
            ],
          ),
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
                  // ユーザー情報と日時
                  FutureBuilder<UserModel?>(
                    future: _authService.getUserData(widget.post.userId),
                    builder: (context, snapshot) {
                      final displayName = snapshot.data?.displayName ?? widget.post.userName;
                      final photoUrl = snapshot.data?.photoUrl;

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: photoUrl != null
                                ? CachedNetworkImageProvider(photoUrl)
                                : null,
                            child: photoUrl == null
                                ? Text(
                                    displayName[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  DateFormat('yyyy/MM/dd HH:mm')
                                      .format(widget.post.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // いいねボタン
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.grey,
                        ),
                        onPressed: _toggleLike,
                      ),
                      Text(
                        '$_likesCount',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
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
