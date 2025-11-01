import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../providers/auth_provider.dart';
import 'post_detail_screen.dart';
import 'create_post_screen.dart';

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
        _updateMarkers();
      });
    });
  }

  // マーカーを更新
  void _updateMarkers() {
    _markers = _posts.map((post) {
      return Marker(
        markerId: MarkerId(post.id),
        position: LatLng(post.latitude, post.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getCategoryColor(post.category),
        ),
        onTap: () => _showPostDetail(post),
      );
    }).toSet();
  }

  // カテゴリに応じた色を返す
  double _getCategoryColor(String category) {
    switch (category) {
      case '猫':
        return BitmapDescriptor.hueOrange;
      case '風景':
        return BitmapDescriptor.hueGreen;
      case '旅行':
        return BitmapDescriptor.hueBlue;
      case '日常':
        return BitmapDescriptor.hueYellow;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  // 投稿詳細を表示
  void _showPostDetail(Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostDetailScreen(post: post),
      ),
    );
  }

  // 投稿作成画面へ移動
  void _navigateToCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreatePostScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapMap'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
            tooltip: '現在地に移動',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                authProvider.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (context) => [
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
      body: GoogleMap(
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // カテゴリフィルターボタン（将来の拡張用）
          FloatingActionButton(
            heroTag: 'filter',
            onPressed: () {
              // カテゴリフィルター機能を実装
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('カテゴリフィルター機能は開発中です')),
              );
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.filter_list, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          // 投稿作成ボタン
          FloatingActionButton(
            heroTag: 'create',
            onPressed: _navigateToCreatePost,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add_a_photo, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
