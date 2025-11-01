import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../models/post_marker.dart';
import '../models/post_category.dart';
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
  ClusterManager? _clusterManager;
  LatLng _currentPosition = const LatLng(35.6812, 139.7671); // 東京駅がデフォルト
  Set<Marker> _markers = {};
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _initClusterManager();
    _getCurrentLocation();
    _loadPosts();
  }

  // ClusterManagerを初期化
  void _initClusterManager() {
    _clusterManager = ClusterManager<PostMarker>(
      [],
      _updateMarkers,
      markerBuilder: _markerBuilder,
    );
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
      // ClusterManagerにアイテムを設定
      _clusterManager?.setItems(
        posts.map((post) => PostMarker(post)).toList(),
      );
      _clusterManager?.updateMap();
    });
  }

  // マーカーを更新（ClusterManagerから呼ばれる）
  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      _markers = markers;
    });
  }

  // マーカーを生成（ClusterManagerから呼ばれる）
  Future<Marker> _markerBuilder(Cluster<PostMarker> cluster) async {
    if (cluster.isMultiple) {
      // クラスタマーカー（複数の投稿）
      return Marker(
        markerId: MarkerId(cluster.getId()),
        position: cluster.location,
        icon: await _getClusterIcon(cluster.count),
        onTap: () {
          // クラスタをタップしたらズームイン
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(cluster.location, 15),
          );
        },
      );
    } else {
      // 個別マーカー（1つの投稿）
      final post = cluster.items.first.post;
      return Marker(
        markerId: MarkerId(post.id),
        position: LatLng(post.latitude, post.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getCategoryColor(post.category),
        ),
        onTap: () => _showPostDetail(post),
      );
    }
  }

  // クラスタマーカーのアイコンを生成
  Future<BitmapDescriptor> _getClusterIcon(int count) async {
    final size = 120.0;
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // 円の背景を描画
    final paint = Paint()..color = Colors.blue;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // 白い枠を描画
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 4, borderPaint);

    // テキストを描画
    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 50.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    // 画像に変換
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
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
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 14,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          _clusterManager?.setMapId(controller.mapId);
        },
        onCameraMove: (position) {
          _clusterManager?.onCameraMove(position);
        },
        onCameraIdle: () {
          _clusterManager?.updateMap();
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
