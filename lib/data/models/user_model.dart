import 'package:sosyal_halisaha/data/models/city_model.dart';
import 'package:sosyal_halisaha/data/models/post_model.dart';
import 'package:sosyal_halisaha/data/models/team_model.dart';

class User {
  final int id;
  final String documentId; // <-- EKLENDİ (Proje standardımız)
  final String username;
  final String email;
  final String? fullName; // Strapi'den null gelebilir, o yüzden nullable
  final String? preferredPosition;
  final City? preferredCity; // <-- YAZIM HATASI DÜZELTİLDİ
  final List<Post> posts; // <-- YENİ ALAN: Kullanıcının gönderi listesi
  final Team? team;
  final bool isJoker;

  User({
    required this.id,
    required this.documentId, // <-- EKLENDİ
    required this.username,
    required this.email,
    this.fullName,
    this.preferredPosition,
    this.preferredCity,
    this.posts = const [], // <-- YENİ ALAN (varsayılan boş liste)
    this.team,
    this.isJoker = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final List<dynamic> postsData = json['posts'] ?? [];
    final List<Post> userPosts = postsData
        .map((postJson) => Post.fromJson(postJson))
        .toList();

    return User(
      id: json['id'],
      documentId: json['documentId'] ?? '', // <-- EKLENDİ
      username: json['username'],
      email: json['email'],
      fullName: json['fullName'],
      preferredPosition: json['preferredPosition'],
      preferredCity: json['city'] != null ? City.fromJson(json['city']) : null,
      posts: userPosts, // <-- YENİ ALAN
      team: json['team'] != null ? Team.fromJson(json['team']) : null,
      isJoker: json['isJoker'] ?? false,
    );
  }
}
