// lib/data/services/team_service.dart

import 'package:dio/dio.dart';
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

class TeamService {
  final Dio _dio;
  TeamService(this._dio);

  /// Yeni bir takım oluşturur.
  Future<Team> createTeam({
    required String name,
    required int captainId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/teams',
        // Strapi v4, veri gönderirken 'data' objesi içinde sarmalanmasını bekler.
        data: {
          'data': {'name': name, 'captain': captainId},
        },
      );
      return Team.fromJson(response.data['data']);
    } catch (e) {
      throw Exception("Takım oluşturulamadı: $e");
    }
  }

  /// Sistemdeki takımları listeler ve arama yapar.
  /// [query] parametresi takım adında arama yapmak için kullanılır.
  /// [currentTeamId] parametresi, kullanıcının kendi takımını listeden hariç tutmak için kullanılır.
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
}
