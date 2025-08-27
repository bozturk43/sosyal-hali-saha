// lib/data/models/team_model.dart

import 'package:sosyal_halisaha/data/models/user_model.dart';

class Team {
  final int id;
  final String name;
  final User? captain;
  // İleride logo, kuruluş tarihi gibi alanları da buraya ekleyebiliriz.
  // final String? logoUrl; // Eğer logo URL'si Strapi'den gelecekse

  Team({
    required this.id,
    required this.name,
    this.captain,
    // this.logoUrl,
  });

  // CUSTOM ENDPOINT'TEN GELEN VERİYE GÖRE DÜZELTİLDİ
  // Artık { "id": 1, "name": "..." } formatında geliyor, "attributes" katmanı yok.
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      captain: json['captain'] != null ? User.fromJson(json['captain']) : null,
      // logoUrl: json['logo']?['url'], // Eğer logo da populate edilirse
    );
  }
}
