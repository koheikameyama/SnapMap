import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/post_category.dart';
import '../services/firestore_service.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _captionController = TextEditingController();
  PostCategory? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.post.caption ?? '';
    _selectedCategory = PostCategoryExtension.fromString(widget.post.category);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // 投稿を更新
  Future<void> _updatePost() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カテゴリを選択してください')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.updatePost(
        widget.post.id,
        caption: _captionController.text.trim(),
        category: _selectedCategory!.value,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // 更新成功を通知
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('思い出を更新しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('思い出を編集'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _updatePost,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // キャプション入力
            TextField(
              controller: _captionController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'キャプション',
                hintText: 'この写真について説明してください',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // カテゴリ選択
            const Text(
              'カテゴリ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PostCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        category.icon,
                        size: 18,
                        color: isSelected ? Colors.white : category.markerColor,
                      ),
                      const SizedBox(width: 4),
                      Text(category.displayName),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: category.markerColor,
                  backgroundColor: category.markerColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 注意事項
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '写真と位置情報は変更できません',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
