import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'post.dart';

class PostMarker with ClusterItem {
  final Post post;

  PostMarker(this.post);

  @override
  LatLng get location => LatLng(post.latitude, post.longitude);

  @override
  String get geohash => ''; // クラスタリングアルゴリズムが内部で計算
}
