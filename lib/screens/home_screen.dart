import 'package:flutter/material.dart';
import '../models/post.dart';
import 'map_screen.dart';
import 'timeline_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<MapScreenState> _mapScreenKey = GlobalKey<MapScreenState>();

  // 投稿位置を地図で表示
  void _showPostOnMap(Post post) {
    setState(() {
      _currentIndex = 0; // マップタブに切り替え
    });
    // フレーム描画後にマップを移動
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapScreenKey.currentState?.moveToPost(post);
    });
  }

  List<Widget> get _screens => [
    MapScreen(key: _mapScreenKey),
    TimelineScreen(onShowPostOnMap: _showPostOnMap),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: '地図',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'タイムライン',
          ),
        ],
      ),
    );
  }
}
