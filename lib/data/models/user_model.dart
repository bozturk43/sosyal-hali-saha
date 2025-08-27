import 'package:sosyal_halisaha/data/models/city_model.dart';
import 'package:sosyal_halisaha/data/models/post_model.dart';
import 'package:sosyal_halisaha/data/models/team_model.dart';

class User {
  final int id;
  final String username;
  final String email;
  final String? fullName; // Strapi'den null gelebilir, o yüzden nullable
  final String? preferredPosition;
  final City? prefferedCity;
  final List<Post> posts; // <-- YENİ ALAN: Kullanıcının gönderi listesi
  final Team? team;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.preferredPosition,
    this.prefferedCity,
    this.posts = const [], // <-- YENİ ALAN (varsayılan boş liste)
    this.team,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final List<dynamic> postsData = json['posts'] ?? [];
    final List<Post> userPosts = postsData
        .map((postJson) => Post.fromJson(postJson))
        .toList();

    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      fullName: json['fullName'],
      preferredPosition: json['preferredPosition'],
      prefferedCity: json['city'] != null ? City.fromJson(json['city']) : null,
      posts: userPosts, // <-- YENİ ALAN
      team: json['team'] != null ? Team.fromJson(json['team']) : null,
    );
  }
}
