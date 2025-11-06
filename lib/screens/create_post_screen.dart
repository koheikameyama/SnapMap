import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:exif/exif.dart';
import '../models/post.dart';
import '../models/post_category.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/ad_service.dart';
import '../providers/auth_provider.dart';
import '../models/place_search_result.dart';
import 'profile_edit_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final File? initialImage;

  const CreatePostScreen({super.key, this.initialImage});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();
  final AdService _adService = AdService();

  final _captionController = TextEditingController();
  final _locationSearchController = TextEditingController();
  final _locationSearchFocusNode = FocusNode();
  List<File> _selectedImages = []; // 複数画像対応
  static const int _maxImages = 5; // 最大5枚
  PostCategory _selectedCategory = PostCategory.other;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  String? _locationName;
  List<PlaceSearchResult> _searchResults = [];
  bool _hasLoadedNearbyPlaces = false;

  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _selectedImages = [widget.initialImage!];
    }
    _loadInterstitialAd();
    _initializeLocation();
    _setupLocationSearchFocus();
  }

  // 初期位置情報を取得
  Future<void> _initializeLocation() async {
    // 写真が選択されている場合、最初の写真のEXIFから位置情報を取得
    if (_selectedImages.isNotEmpty) {
      final exifLocation =
          await _extractLocationFromImage(_selectedImages.first);
      if (exifLocation != null && mounted) {
        setState(() {
          _latitude = exifLocation['latitude'];
          _longitude = exifLocation['longitude'];
        });
        return;
      }
    }

    // EXIFに位置情報がない場合、または写真がない場合は現在地を取得
    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    }
  }

  // 画像のEXIFデータから位置情報を抽出
  Future<Map<String, double>?> _extractLocationFromImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isEmpty) {
        return null;
      }

      // GPS情報を取得
      final gpsLatitude = data['GPS GPSLatitude'];
      final gpsLatitudeRef = data['GPS GPSLatitudeRef'];
      final gpsLongitude = data['GPS GPSLongitude'];
      final gpsLongitudeRef = data['GPS GPSLongitudeRef'];

      if (gpsLatitude == null || gpsLongitude == null) {
        return null;
      }

      // 緯度を計算
      final latValues = gpsLatitude.values.toList();
      double latitude = _convertGPSCoordinate(
        latValues[0].toDouble(),
        latValues[1].toDouble(),
        latValues[2].toDouble(),
      );
      if (gpsLatitudeRef?.printable == 'S') {
        latitude = -latitude;
      }

      // 経度を計算
      final lonValues = gpsLongitude.values.toList();
      double longitude = _convertGPSCoordinate(
        lonValues[0].toDouble(),
        lonValues[1].toDouble(),
        lonValues[2].toDouble(),
      );
      if (gpsLongitudeRef?.printable == 'W') {
        longitude = -longitude;
      }

      return {
        'latitude': latitude,
        'longitude': longitude,
      };
    } catch (e) {
      // EXIFデータの読み取りに失敗した場合はnullを返す
      return null;
    }
  }

  // GPS座標を度分秒から10進数に変換
  double _convertGPSCoordinate(double degrees, double minutes, double seconds) {
    return degrees + (minutes / 60.0) + (seconds / 3600.0);
  }

  // 2点間の距離を計算（Haversine formula）メートル単位
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // メートル
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // 度をラジアンに変換
  double _toRadians(double degrees) => degrees * pi / 180;

  // 位置情報の整合性をチェック
  Future<bool> _checkLocationConsistency() async {
    if (_selectedImages.length <= 1) return true;

    List<Map<String, double>> locations = [];

    // 全ての画像から位置情報を取得
    for (var image in _selectedImages) {
      final loc = await _extractLocationFromImage(image);
      if (loc != null) {
        locations.add(loc);
      }
    }

    // 位置情報が1つ以下なら問題なし
    if (locations.length <= 1) return true;

    // 最初の位置を基準に距離を計算
    final baseLocation = locations.first;
    const double threshold = 200.0; // 200m

    for (var i = 1; i < locations.length; i++) {
      final distance = _calculateDistance(
        baseLocation['latitude']!,
        baseLocation['longitude']!,
        locations[i]['latitude']!,
        locations[i]['longitude']!,
      );

      if (distance > threshold) {
        // 閾値を超えた写真がある
        if (!mounted) return false;

        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('異なる場所の写真が含まれています'),
            content: Text(
              '${(distance / 1000).toStringAsFixed(1)}km離れた場所で撮影された写真が含まれています。\n'
              '\n最初の写真の場所を使用しますか？\n'
              'または、場所を手動で選択してください。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('写真を選び直す'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('このまま続ける'),
              ),
            ],
          ),
        );

        return result ?? false;
      }
    }

    return true;
  }

  // 検索窓のフォーカスリスナーを設定
  void _setupLocationSearchFocus() {
    _locationSearchFocusNode.addListener(() async {
      // フォーカスが当たった時のみ処理
      if (_locationSearchFocusNode.hasFocus &&
          !_hasLoadedNearbyPlaces &&
          _latitude != null &&
          _longitude != null) {
        _hasLoadedNearbyPlaces = true;
        await _loadNearbyPlaces();
      }
    });
  }

  // 周辺の場所を取得
  Future<void> _loadNearbyPlaces() async {
    if (_latitude == null || _longitude == null) return;

    final results = await _locationService.getNearbyPlaces(
      latitude: _latitude!,
      longitude: _longitude!,
    );

    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  // インタースティシャル広告をロード
  Future<void> _loadInterstitialAd() async {
    _interstitialAd = await _adService.loadInterstitialAd();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationSearchController.dispose();
    _locationSearchFocusNode.dispose();
    super.dispose();
  }

  // 位置情報を取得
  Future<void> _getLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    }
  }

  // カメラから写真を撮影
  Future<void> _pickImageFromCamera() async {
    if (_selectedImages.length >= _maxImages) {
      _showMaxImagesMessage();
      return;
    }

    // オリジナル画像を取得（EXIFを保持するため）
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      requestFullMetadata: true, // iOSでEXIF取得を試みる
      // maxWidth/maxHeightを削除してEXIFを保持
    );

    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
        _hasLoadedNearbyPlaces = false;
        _searchResults = [];
      });

      // 位置情報の整合性をチェック（複数枚の場合のみ）
      if (_selectedImages.length > 1) {
        final isConsistent = await _checkLocationConsistency();
        if (!isConsistent) {
          // ユーザーが「選び直す」を選択した場合、追加した画像を削除
          setState(() {
            _selectedImages.removeLast();
          });
          return;
        }
      }

      // 最初の写真のEXIFから位置情報を取得
      if (_selectedImages.length == 1) {
        await _initializeLocation();
      }
    }
  }

  // ギャラリーから複数の写真を選択
  Future<void> _pickImagesFromGallery() async {
    if (_selectedImages.length >= _maxImages) {
      _showMaxImagesMessage();
      return;
    }

    // まず、オリジナル画像を取得（EXIFを保持するため）
    final List<XFile> images = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      // maxWidth/maxHeightを削除してEXIFを保持
    );

    if (images.isNotEmpty) {
      // 最大枚数を超えないように制限
      final remainingSlots = _maxImages - _selectedImages.length;
      final imagesToAdd = images.take(remainingSlots).toList();

      setState(() {
        _selectedImages.addAll(imagesToAdd.map((xFile) => File(xFile.path)));
        _hasLoadedNearbyPlaces = false;
        _searchResults = [];
      });

      // 位置情報の整合性をチェック
      final isConsistent = await _checkLocationConsistency();
      if (!isConsistent) {
        // ユーザーが「選び直す」を選択した場合
        setState(() {
          // 今回追加した画像のみを削除
          _selectedImages.removeRange(
            _selectedImages.length - imagesToAdd.length,
            _selectedImages.length,
          );
        });
        return;
      }

      // 最初の写真のEXIFから位置情報を取得
      if (_selectedImages.length == imagesToAdd.length) {
        await _initializeLocation();
      }

      // 最大枚数に達した場合は通知
      if (images.length > remainingSlots) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('最大5枚まで選択できます')),
          );
        }
      }
    }
  }

  // 画像を削除
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // 最大枚数メッセージを表示
  void _showMaxImagesMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('最大5枚まで選択できます')),
    );
  }

  // 場所を検索
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      // 空の場合は周辺候補を再表示
      if (_latitude != null && _longitude != null) {
        await _loadNearbyPlaces();
      } else {
        setState(() {
          _searchResults = [];
        });
      }
      return;
    }

    final results = await _locationService.searchPlaces(
      query,
      latitude: _latitude,
      longitude: _longitude,
    );

    setState(() {
      _searchResults = results;
    });
  }

  // 場所を選択
  void _selectPlace(PlaceSearchResult place) {
    setState(() {
      _latitude = place.latitude;
      _longitude = place.longitude;
      _locationName = place.name;
      _locationSearchController.text = place.name;
      _searchResults = [];
    });
    // フォーカスを外す
    _locationSearchFocusNode.unfocus();
  }

  // 現在地を使用
  Future<void> _useCurrentLocation() async {
    setState(() {
      _locationName = null;
      _locationSearchController.clear();
      _searchResults = [];
      _hasLoadedNearbyPlaces = false;
    });
    await _getLocation();
    // 現在地を再取得したら、周辺候補もリセット
    if (_locationSearchFocusNode.hasFocus &&
        _latitude != null &&
        _longitude != null) {
      await _loadNearbyPlaces();
      _hasLoadedNearbyPlaces = true;
    }
  }

  // 画像選択ダイアログを表示
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('写真を選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ギャラリーから選択（複数可）'),
              subtitle: Text(
                  '最大$_maxImages枚まで（残り${_maxImages - _selectedImages.length}枚）'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImagesFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  // 投稿ボタン押下時の処理
  Future<void> _createPost() async {
    await _submitPost();
  }

  // 実際の投稿処理
  Future<void> _submitPost() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真を選択してください')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('位置情報を取得できませんでした')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインしてください')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 複数画像をアップロード
      List<String> imageUrls = await _storageService.uploadImages(
        _selectedImages,
        authProvider.user!.uid,
      );

      // 投稿を作成
      Post post = Post(
        id: '',
        userId: authProvider.user!.uid,
        userName: authProvider.userModel?.displayName ?? 'Unknown',
        imageUrls: imageUrls,
        caption: _captionController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        locationName: _locationName,
        category: _selectedCategory.toFirestoreString(),
        tags: [], // 将来的にタグ機能を追加
        createdAt: DateTime.now(),
      );

      await _firestoreService.createPost(post);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('思い出を保存しました')),
        );
        Navigator.of(context).pop();

        // 画面を閉じた後に広告を表示（非同期）
        if (_interstitialAd != null) {
          _adService.showInterstitialAd(_interstitialAd);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return GestureDetector(
      onTap: () {
        // キーボードを閉じる
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('思い出を残す',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 画像プレビュー（複数画像対応）
              _selectedImages.isEmpty
                  ? GestureDetector(
                      onTap: _showImagePickerDialog,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'タップして写真を選択（最大5枚）',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 画像グリッド
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _selectedImages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _selectedImages.length) {
                              // 追加ボタン
                              if (_selectedImages.length < _maxImages) {
                                return GestureDetector(
                                  onTap: _showImagePickerDialog,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border:
                                          Border.all(color: Colors.grey[400]!),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add, color: Colors.grey),
                                        Text(
                                          '追加',
                                          style: TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            }

                            // 画像表示
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImages[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // 削除ボタン
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                // 順番表示
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
              const SizedBox(height: 24),

              // ユーザー情報
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: authProvider.userModel?.photoUrl != null
                        ? CachedNetworkImageProvider(
                            authProvider.userModel!.photoUrl!)
                        : null,
                    child: authProvider.userModel?.photoUrl == null
                        ? Text(
                            (authProvider.userModel?.displayName ?? 'U')[0]
                                .toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    authProvider.userModel?.displayName ?? 'ユーザー',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ProfileEditScreen(),
                        ),
                      );
                    },
                    tooltip: 'プロフィールを編集',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // キャプション
              TextField(
                controller: _captionController,
                decoration: const InputDecoration(
                  labelText: 'キャプション（任意）',
                  border: OutlineInputBorder(),
                  hintText: 'この写真について説明しましょう',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // カテゴリ選択
              Row(
                children: [
                  const Text(
                    'カテゴリ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PostCategory.values.map((category) {
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(category.icon, size: 18),
                        const SizedBox(width: 4),
                        Text(category.displayName),
                      ],
                    ),
                    selected: _selectedCategory == category,
                    selectedColor: category.markerColor.withOpacity(0.3),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 位置情報・場所検索
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '場所',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '*',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[600]),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location, size: 18),
                    label: const Text('現在地を取得'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _locationSearchController,
                focusNode: _locationSearchFocusNode,
                decoration: InputDecoration(
                  labelText: '場所を検索',
                  border: const OutlineInputBorder(),
                  hintText: 'お店の名前や場所を検索（現在地も使用可）',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _locationSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _useCurrentLocation,
                        )
                      : null,
                ),
                onChanged: _searchLocation,
              ),

              // 検索結果リスト
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
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

              // 選択された場所を表示
              if (_latitude != null && _longitude != null)
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationName ??
                                '現在地（${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}）',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() {
                              _latitude = null;
                              _longitude = null;
                              _locationName = null;
                              _locationSearchController.clear();
                            });
                          },
                          tooltip: '削除',
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // 表示期限の説明
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'あなただけの思い出として地図に保存されます',
                        style: TextStyle(color: Colors.blue[900], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 投稿ボタン
              FilledButton(
                onPressed: (_isLoading ||
                        _selectedImages.isEmpty ||
                        _latitude == null ||
                        _longitude == null)
                    ? null
                    : _createPost,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '保存する',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
