// lib/data/services/team_service.dart

import 'package:dio/dio.dart';
import 'dart:convert'; // jsonEncode için
import 'dart:io'; // File için
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosyal_halisaha/data/models/team_model.dart';
import 'package:sosyal_halisaha/data/services/dio_provider.dart';
import 'package:sosyal_halisaha/data/services/user_service.dart';

// TeamService'in bir örneğini oluşturan ve uygulama genelinde erişilebilir kılan provider.
final teamServiceProvider = Provider(
  (ref) => TeamService(ref.watch(dioProvider)),
);
// Takım arama ve listeleme için kullanılan provider.
// '.family' sayesinde dışarıdan bir 'query' (arama metni) parametresi alabilir.
final allTeamsProvider = FutureProvider.autoDispose.family<List<Team>, String>((
  ref,
  query,
) {
  final teamService = ref.watch(teamServiceProvider);
  // Mevcut kullanıcının kaptanı olduğu takımı listeden çıkarmak için ID'sini alıyoruz.
  final currentUser = ref.watch(currentUserProvider).value;
  return teamService.getTeams(
    query: query,
    currentTeamId: currentUser?.team?.id,
  );
});
final teamDetailsProvider = FutureProvider.autoDispose.family<Team, String>((
  ref,
  documentId,
) {
  return ref.watch(teamServiceProvider).getTeamDetails(documentId);
});

class TeamService {
  final Dio _dio;
  TeamService(this._dio);

  Future<Team> createTeam({
    required String name,
    required int captainId,
    File? logoFile,
  }) async {
    try {
      int? logoId;

      // --- ADIM 1: Eğer bir logo dosyası seçilmişse, önce onu yükle ---
      if (logoFile != null) {
        final formData = FormData.fromMap({
          // Strapi'nin /api/upload endpoint'i dosyaları 'files' anahtarı altında bekler.
          'files': await MultipartFile.fromFile(
            logoFile.path,
            filename: logoFile.path.split('/').last,
          ),
        });

        // Sadece dosyayı yüklemek için /api/upload'a istek atıyoruz.
        final uploadResponse = await _dio.post('/api/upload', data: formData);

        // Strapi yüklenen dosyaların bilgilerini bir dizi içinde döner.
        if (uploadResponse.statusCode == 200 &&
            uploadResponse.data.isNotEmpty) {
          // Yüklenen dosyanın ID'sini alıyoruz.
          logoId = uploadResponse.data[0]['id'] as int;
        } else {
          throw Exception('Logo yüklenemedi.');
        }
      }
      // ----------------------------------------------------------------

      // --- ADIM 2: Takım bilgilerini ve (varsa) logo ID'sini gönder ---
      final teamData = {
        'name': name,
        'captain': captainId,
        // logoId null değilse, yani bir logo yüklendiyse, onu da veriye ekle.
        if (logoId != null) 'logo': logoId,
      };

      // Artık dosya göndermediğimiz için saf JSON isteği atıyoruz.
      final response = await _dio.post('/api/teams', data: {'data': teamData});

      return Team.fromJson(response.data['data']);
      // ----------------------------------------------------------------
    } catch (e) {
      if (e is DioException) {
        print("Dio Hatası Detayı: ${e.response?.data}");
      }
      throw Exception("Takım oluşturulamadı: $e");
    }
  }

  Future<List<Team>> getTeams({String query = '', int? currentTeamId}) async {
    try {
      final queryParameters = <String, dynamic>{
        // Her zaman takımın kaptan bilgisini de çekelim, lazım olabilir.
        'populate[0]': 'captain',
      };

      // Eğer bir arama metni varsa, isme göre büyük/küçük harf duyarsız filtrele
      if (query.isNotEmpty) {
        queryParameters['filters[name][\$containsi]'] = query;
      }

      // Eğer bir takım ID'si verilmişse, o takımı sonuçlardan çıkar ($ne: not equal)
      if (currentTeamId != null) {
        queryParameters['filters[id][\$ne]'] = currentTeamId;
      }

      final response = await _dio.get(
        '/api/teams',
        queryParameters: queryParameters,
      );
      final List<dynamic> data = response.data['data'];
      return data.map((t) => Team.fromJson(t)).toList();
    } catch (e) {
      throw Exception("Takımlar getirilemedi: $e");
    }
  }

  Future<Team> getTeamDetails(String documentId) async {
    try {
      final response = await _dio.get(
        '/api/teams/$documentId?populate[0]=players&populate[1]=captain',
      );
      return Team.fromJson(response.data['data']);
    } catch (e) {
      throw Exception("Takım detayları getirilemedi: $e");
    }
  }

  Future<Team> addPlayerToPool({
    required int teamId,
    required List<int> existingPlayerIds,
    required int newPlayerId,
  }) async {
    try {
      // Mevcut oyuncu ID'lerine yenisini ekleyip tekrarları önlemek için Set kullanıyoruz.
      final updatedPlayerIds = {...existingPlayerIds, newPlayerId}.toList();

      final response = await _dio.put(
        '/api/teams/$teamId',
        data: {
          'data': {'players': updatedPlayerIds},
        },
      );
      return Team.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Oyuncu havuza eklenemedi.');
    }
  }

  Future<Team> removePlayerFromPool({
    required int teamId,
    required List<int> existingPlayerIds,
    required int playerToRemoveId,
  }) async {
    try {
      // Mevcut oyuncu listesinden çıkarılacak oyuncunun ID'sini siliyoruz.
      final updatedPlayerIds = existingPlayerIds
          .where((id) => id != playerToRemoveId)
          .toList();

      final response = await _dio.put(
        '/api/teams/$teamId',
        data: {
          'data': {'players': updatedPlayerIds},
        },
      );
      return Team.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Oyuncu havuzdan çıkarılamadı.');
    }
  }
}
