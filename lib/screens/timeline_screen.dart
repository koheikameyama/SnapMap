import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/post.dart';
import '../models/post_category.dart';
import '../services/firestore_service.dart';
import '../services/export_service.dart';
import '../providers/auth_provider.dart';
import 'post_detail_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Post> _posts = [];
  Set<PostCategory> _selectedCategories = {};
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  // 投稿を読み込む
  void _loadPosts() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    _firestoreService.getAllPosts(userId).listen((posts) {
      setState(() {
        _posts = posts;
      });
    });
  }

  // フィルタリングされた投稿を取得
  List<Post> get _filteredPosts {
    List<Post> filtered = _posts;

    // カテゴリフィルタ
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((post) {
        final category = PostCategoryExtension.fromString(post.category);
        return _selectedCategories.contains(category);
      }).toList();
    }

    // 日付範囲フィルタ
    if (_startDate != null) {
      filtered = filtered.where((post) => post.createdAt.isAfter(_startDate!)).toList();
    }
    if (_endDate != null) {
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      filtered = filtered.where((post) => post.createdAt.isBefore(endOfDay)).toList();
    }

    // キャプション検索
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((post) {
        final caption = post.caption?.toLowerCase() ?? '';
        final locationName = post.locationName?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return caption.contains(query) || locationName.contains(query);
      }).toList();
    }

    return filtered;
  }

  // 日付範囲選択ダイアログ
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  // カテゴリフィルタダイアログ
  void _showCategoryFilter() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('カテゴリで絞り込み'),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PostCategory.values.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(category.icon, size: 18, color: category.markerColor),
                      const SizedBox(width: 4),
                      Text(category.displayName),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: category.markerColor.withOpacity(0.3),
                  onSelected: (selected) {
                    setDialogState(() {
                      if (selected) {
                        _selectedCategories.add(category);
                      } else {
                        _selectedCategories.remove(category);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    _selectedCategories.clear();
                  });
                },
                child: const Text('クリア'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {}); // メイン画面を更新
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _filteredPosts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('タイムライン'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _posts.isEmpty
                ? null
                : () {
                    ExportService.showExportDialog(context, _posts);
                  },
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _selectedCategories.isNotEmpty,
              label: Text('${_selectedCategories.length}'),
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _showCategoryFilter,
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _startDate != null || _endDate != null,
              child: const Icon(Icons.date_range),
            ),
            onPressed: _selectDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'キャプションや場所で検索',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // フィルタ情報表示
          if (_startDate != null || _endDate != null || _selectedCategories.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_startDate != null || _endDate != null)
                    Chip(
                      label: Text(
                        '${_startDate != null ? DateFormat('MM/dd').format(_startDate!) : '始まり'} - ${_endDate != null ? DateFormat('MM/dd').format(_endDate!) : '今日'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                    ),
                  if (_selectedCategories.isNotEmpty)
                    Chip(
                      label: Text(
                        '${_selectedCategories.length}カテゴリ',
                        style: const TextStyle(fontSize: 12),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedCategories.clear();
                        });
                      },
                    ),
                ],
              ),
            ),

          // 投稿リスト
          Expanded(
            child: filteredPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '思い出がありません',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      final category = PostCategoryExtension.fromString(post.category);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailScreen(post: post),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // サムネイル
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: post.imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[300],
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // 情報
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // カテゴリと日付
                                      Row(
                                        children: [
                                          Icon(category.icon, size: 16, color: category.markerColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            category.displayName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: category.markerColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            DateFormat('yyyy/MM/dd').format(post.createdAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // 場所
                                      if (post.locationName != null)
                                        Row(
                                          children: [
                                            Icon(Icons.place, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                post.locationName!,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[800],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      const SizedBox(height: 4),

                                      // キャプション
                                      if (post.caption != null && post.caption!.isNotEmpty)
                                        Text(
                                          post.caption!,
                                          style: const TextStyle(fontSize: 14),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
