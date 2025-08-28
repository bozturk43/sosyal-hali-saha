// lib/data/models/match_model.dart
import 'package:sosyal_halisaha/data/models/team_model.dart';
import 'package:sosyal_halisaha/data/models/user_model.dart'; // Team modelini import ediyoruz

class Match {
  final int id;
  final String location;
  final String documentId;
  final DateTime startTime;
  final DateTime endTime; // Yeni alan
  final String status; // match_status'tan gelecek
  final Team? homeTeam;
  final Team? awayTeam;
  final List<User> homeTeamSquad;
  final List<User> awayTeamSquad;

  Match({
    required this.id,
    required this.documentId,
    required this.location,
    required this.startTime,
    required this.endTime, // Yeni alan
    required this.status, // Yeni alan
    this.homeTeam,
    this.awayTeam,
    this.homeTeamSquad = const [],
    this.awayTeamSquad = const [],
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    // API'den gelen JSON doğrudan Match objesi gibi geliyor (attributes içinde değil)
    // Bu yüzden direkt alanlara erişebiliriz.
    final List<dynamic> homeSquadData = json['homeTeamSquad'] ?? [];
    final List<User> homeSquad = homeSquadData
        .map((userJson) => User.fromJson(userJson))
        .toList();
    final List<dynamic> awaySquadData = json['awayTeamSquad'] ?? [];
    final List<User> awaySquad = awaySquadData
        .map((userJson) => User.fromJson(userJson))
        .toList();

    return Match(
      id: json['id'],
      documentId: json['documentId'],
      location: json['location'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']), // Yeni alan
      status: json['match_status'], // match_status olarak geliyor
      homeTeam: json['home_team'] != null
          ? Team.fromJson(json['home_team'])
          : null,
      awayTeam: json['away_team'] != null
          ? Team.fromJson(json['away_team'])
          : null,
      homeTeamSquad: homeSquad,
      awayTeamSquad: awaySquad,
    );
  }
}
