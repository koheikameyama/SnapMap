import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../models/post_category.dart';
import '../models/place_search_result.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../providers/auth_provider.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';
import 'profile_edit_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(35.6812, 139.7671); // 東京駅がデフォルト
  Set<Marker> _markers = {};
  List<Post> _posts = [];
  Set<PostCategory> _selectedCategories = {}; // 選択中のカテゴリ（空の場合は全て表示）

  final _searchController = TextEditingController();
  List<PlaceSearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadPosts();
  }

  // 現在位置を取得
  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentPosition),
      );
    }
  }

  // 投稿を読み込む
  void _loadPosts() {
    _firestoreService.getAllPosts().listen((posts) {
      setState(() {
        _posts = posts;
      });
      _updateFilteredPosts();
    });
  }

  // フィルタリングされた投稿を更新
  void _updateFilteredPosts() {
    List<Post> filteredPosts = _posts;

    // カテゴリフィルタを適用
    if (_selectedCategories.isNotEmpty) {
      filteredPosts = _posts.where((post) {
        final category = PostCategoryExtension.fromString(post.category);
        return _selectedCategories.contains(category);
      }).toList();
    }

    // マーカーを更新
    setState(() {
      _markers = filteredPosts.map((post) {
        return Marker(
          markerId: MarkerId(post.id),
          position: LatLng(post.latitude, post.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getCategoryColor(post.category),
          ),
          onTap: () => _showPostDetail(post),
        );
      }).toSet();
    });
  }

  // カテゴリに応じた色を返す
  double _getCategoryColor(String category) {
    final postCategory = PostCategoryExtension.fromString(category);
    return postCategory.markerHue;
  }

  // 投稿詳細を表示
  void _showPostDetail(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: post),
      ),
    );
  }

  // 投稿作成画面へ移動（写真選択後）
  Future<void> _navigateToCreatePost() async {
    final ImagePicker imagePicker = ImagePicker();

    // 写真選択ダイアログを表示
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('写真を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    // 写真を選択
    final XFile? image = await imagePicker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null && mounted) {
      // CreatePostScreenに遷移
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreatePostScreen(
            initialImage: File(image.path),
          ),
        ),
      );
    }
  }

  // 場所を検索
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final results = await _locationService.searchPlaces(
      query,
      latitude: _currentPosition.latitude,
      longitude: _currentPosition.longitude,
    );

    setState(() {
      _searchResults = results;
    });
  }

  // 場所を選択して地図を移動
  void _selectPlace(PlaceSearchResult place) {
    setState(() {
      _searchResults = [];
      _searchController.clear();
      _isSearching = false;
    });

    // 選択した場所に地図を移動
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(place.latitude, place.longitude),
        15,
      ),
    );
  }

  // カテゴリフィルタダイアログを表示
  void _showCategoryFilter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('カテゴリフィルタ機能は開発中です'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapMap', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: '現在地に移動',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileEditScreen(),
                  ),
                );
              } else if (value == 'logout') {
                authProvider.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('プロフィール編集'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('ログアウト'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // 地図
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 検索バー
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 検索入力
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '場所を検索',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchResults = [];
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onChanged: (value) {
                        setState(() {});
                        _searchLocation(value);
                      },
                    ),
                  ),

                  // 検索結果リスト
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final place = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.place),
                            title: Text(place.name),
                            subtitle: Text(
                              place.formattedAddress,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectPlace(place),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // カテゴリフィルターボタン（開発中）
          FloatingActionButton(
            heroTag: 'filter',
            onPressed: _showCategoryFilter,
            backgroundColor: Colors.white,
            child: const Icon(
              Icons.filter_list_rounded,
              color: Color(0xFF64B5F6),
            ),
          ),
          const SizedBox(height: 16),
          // 投稿作成ボタン
          FloatingActionButton(
            heroTag: 'create',
            onPressed: _navigateToCreatePost,
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
