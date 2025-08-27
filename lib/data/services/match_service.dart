// lib/data/services/match_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosyal_halisaha/data/models/match_model.dart';
import 'package:sosyal_halisaha/data/services/dio_provider.dart';
import 'package:sosyal_halisaha/data/services/user_service.dart'; // currentUserProvider'ı kullanmak için

final matchServiceProvider = Provider(
  (ref) => MatchService(ref.watch(dioProvider)),
);

// Kullanıcının dahil olduğu maçları getiren provider
final myMatchesProvider = FutureProvider.autoDispose<List<Match>>((ref) async {
  // Önce mevcut kullanıcının ID'sini almamız gerekiyor
  final user = await ref.watch(currentUserProvider.future);
  // Sonra bu ID ile maçları çekiyoruz
  return ref.watch(matchServiceProvider).getMyMatches();
});

class MatchService {
  final Dio _dio;
  MatchService(this._dio);
  // Metodun imzası değişti, artık userId'ye ihtiyacı yok çünkü Strapi bunu token'dan biliyor.
  Future<List<Match>> getMyMatches() async {
    try {
      // Artık karmaşık queryParameters'a ihtiyacımız yok!
      // Sadece kendi oluşturduğumuz temiz endpoint'i çağırıyoruz.
      final response = await _dio.get('/api/custom-match/my-matches');

      // Gelen cevapta 'data' katmanı zaten var, bir daha belirtmeye gerek yok.
      final List<dynamic> data = response.data['data'];
      return data.map((m) => Match.fromJson(m)).toList();
    } catch (e) {
      throw Exception("Maçlar alınamadı: $e");
    }
  }

  Future<Match> updateMatchStatus({
    required int matchId,
    required String newStatus, // "confirmed" veya "cancelled"
  }) async {
    try {
      final response = await _dio.put(
        '/api/custom-match/$matchId/status',
        data: {'status': newStatus},
      );
      return Match.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Maç durumu güncellenemedi. +');
    }
  }

  Future<void> createMatchOffer({
    required String location,
    required DateTime startTime,
    required DateTime endTime,
    required int homeTeamId,
    required int awayTeamId,
  }) async {
    try {
      await _dio.post(
        '/api/matches',
        data: {
          'data': {
            'location': location,
            'startTime': startTime.toIso8601String(),
            'endTime': endTime.toIso8601String(),
            'home_team': homeTeamId,
            'away_team': awayTeamId,
            'match_status': 'pending', // Teklif olarak oluştur
          },
        },
      );
    } catch (e) {
      throw Exception("Maç teklifi oluşturulamadı: $e");
    }
  }
}
