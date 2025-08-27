// lib/data/models/match_model.dart
import 'package:sosyal_halisaha/data/models/team_model.dart'; // Team modelini import ediyoruz

class Match {
  final int id;
  final String location;
  final DateTime startTime;
  final DateTime endTime; // Yeni alan
  final String status; // match_status'tan gelecek
  final Team homeTeam;
  final Team awayTeam;

  Match({
    required this.id,
    required this.location,
    required this.startTime,
    required this.endTime, // Yeni alan
    required this.status, // Yeni alan
    required this.homeTeam,
    required this.awayTeam,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    // API'den gelen JSON doğrudan Match objesi gibi geliyor (attributes içinde değil)
    // Bu yüzden direkt alanlara erişebiliriz.
    return Match(
      id: json['id'],
      location: json['location'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']), // Yeni alan
      status: json['match_status'], // match_status olarak geliyor
      homeTeam: Team.fromJson(json['home_team']), // home_team olarak geliyor
      awayTeam: Team.fromJson(json['away_team']), // away_team olarak geliyor
    );
  }
}
