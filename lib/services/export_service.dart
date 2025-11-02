import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../models/post.dart';

class ExportService {
  // 投稿データをJSONファイルにエクスポート
  Future<String> exportPostsToJson(List<Post> posts) async {
    try {
      // 投稿データをマップに変換
      final List<Map<String, dynamic>> postsData = posts.map((post) {
        return {
          'id': post.id,
          'userId': post.userId,
          'userName': post.userName,
          'imageUrl': post.imageUrl,
          'caption': post.caption,
          'latitude': post.latitude,
          'longitude': post.longitude,
          'locationName': post.locationName,
          'category': post.category,
          'tags': post.tags,
          'createdAt': post.createdAt.toIso8601String(),
        };
      }).toList();

      // JSONエンコード
      final jsonString = const JsonEncoder.withIndent('  ').convert({
        'exportedAt': DateTime.now().toIso8601String(),
        'postCount': posts.length,
        'posts': postsData,
      });

      // 一時ディレクトリに保存
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/mapdiary_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('JSONエクスポートに失敗しました: $e');
    }
  }

  // 写真をダウンロードして保存
  Future<List<String>> downloadImages(List<Post> posts, {Function(int, int)? onProgress}) async {
    try {
      final directory = await getTemporaryDirectory();
      final imageDir = Directory('${directory.path}/mapdiary_images_${DateTime.now().millisecondsSinceEpoch}');
      await imageDir.create();

      final List<String> downloadedFiles = [];

      for (int i = 0; i < posts.length; i++) {
        final post = posts[i];

        try {
          // 画像をダウンロード
          final response = await http.get(Uri.parse(post.imageUrl));

          if (response.statusCode == 200) {
            // ファイル名を生成（投稿ID + 日付）
            final fileName = '${post.id}_${post.createdAt.millisecondsSinceEpoch}.jpg';
            final file = File('${imageDir.path}/$fileName');
            await file.writeAsBytes(response.bodyBytes);
            downloadedFiles.add(file.path);
          }
        } catch (e) {
          print('画像のダウンロードに失敗: ${post.id} - $e');
        }

        // 進捗通知
        if (onProgress != null) {
          onProgress(i + 1, posts.length);
        }
      }

      return downloadedFiles;
    } catch (e) {
      throw Exception('画像のダウンロードに失敗しました: $e');
    }
  }

  // JSONファイルを共有
  Future<void> shareJsonFile(String filePath) async {
    try {
      final xFile = XFile(filePath);
      await Share.shareXFiles(
        [xFile],
        subject: 'MapDiary バックアップデータ',
      );
    } catch (e) {
      throw Exception('ファイルの共有に失敗しました: $e');
    }
  }

  // 複数ファイルを共有
  Future<void> shareMultipleFiles(List<String> filePaths) async {
    try {
      final xFiles = filePaths.map((path) => XFile(path)).toList();
      await Share.shareXFiles(
        xFiles,
        subject: 'MapDiary バックアップ',
      );
    } catch (e) {
      throw Exception('ファイルの共有に失敗しました: $e');
    }
  }

  // エクスポートダイアログを表示
  static Future<void> showExportDialog(BuildContext context, List<Post> posts) async {
    final exportService = ExportService();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バックアップ・エクスポート'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${posts.length}件の投稿をエクスポートします。'),
            const SizedBox(height: 16),
            const Text(
              'エクスポート内容:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• 投稿データ (JSON形式)'),
            const Text('• 位置情報・カテゴリ'),
            const Text('• キャプション'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _performExport(context, posts, exportService, includeImages: false);
            },
            icon: const Icon(Icons.description),
            label: const Text('データのみ'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _performExport(context, posts, exportService, includeImages: true);
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('写真も含む'),
          ),
        ],
      ),
    );
  }

  // エクスポート実行
  static Future<void> _performExport(
    BuildContext context,
    List<Post> posts,
    ExportService exportService, {
    required bool includeImages,
  }) async {
    // ローディングダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('エクスポート中...'),
          ],
        ),
      ),
    );

    try {
      // JSONエクスポート
      final jsonPath = await exportService.exportPostsToJson(posts);
      final List<String> filesToShare = [jsonPath];

      // 写真のダウンロード
      if (includeImages) {
        final imagePaths = await exportService.downloadImages(posts);
        filesToShare.addAll(imagePaths);
      }

      // ローディングを閉じる
      if (context.mounted) {
        Navigator.pop(context);
      }

      // ファイルを共有
      await exportService.shareMultipleFiles(filesToShare);

      // 成功メッセージ
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              includeImages
                  ? 'データと写真をエクスポートしました'
                  : 'データをエクスポートしました',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // ローディングを閉じる
      if (context.mounted) {
        Navigator.pop(context);
      }

      // エラーメッセージ
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エクスポートに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
