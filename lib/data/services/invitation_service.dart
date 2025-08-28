// lib/data/services/invitation_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosyal_halisaha/data/models/squad_invitation_model.dart';
import 'package:sosyal_halisaha/data/services/dio_provider.dart';
import 'package:sosyal_halisaha/data/services/user_service.dart';
import 'dart:developer' as developer;

final invitationServiceProvider = Provider(
  (ref) => InvitationService(ref.watch(dioProvider)),
);

final myInvitationsProvider = FutureProvider.autoDispose<List<SquadInvitation>>((
  ref,
) async {
  // 1. Önce mevcut kullanıcının verisinin gelmesini bekle.
  final user = await ref.watch(currentUserProvider.future);
  // 3. Servisi çağırırken, az önce aldığımız kullanıcının ID'sini parametre olarak ver.
  return ref.watch(invitationServiceProvider).getMyInvitations(userId: user.id);
});

final matchInvitationsProvider = FutureProvider.autoDispose
    .family<List<SquadInvitation>, int>((ref, matchId) {
      return ref
          .watch(invitationServiceProvider)
          .getInvitationsForMatch(matchId);
    });

class InvitationService {
  final Dio _dio;
  InvitationService(this._dio);

  // Kaptanın bir oyuncuya davet göndermesi
  Future<void> createInvitation({
    required int matchId,
    required int playerId,
    required int teamId,
  }) async {
    await _dio.post(
      '/api/squad-invitations',
      data: {
        'data': {
          'match': matchId,
          'player': playerId,
          'inviting_team': teamId,
          'invite_status': 'pending',
        },
      },
    );
  }

  Future<List<SquadInvitation>> getMyInvitations({required int userId}) async {
    try {
      // Dio'nun queryParameters özelliği, karmaşık Map'leri bizim için
      // doğru URL formatına çevirir.
      final response = await _dio.get(
        '/api/squad-invitations',
        queryParameters: {
          // Filtreler:
          'filters[player][id][\$eq]': userId,
          'filters[invite_status][\$eq]':
              'pending', // Senin kullandığın alan adı
          // İç İçe Populate:
          // 'populate' anahtarı altına bir Map koyarak iç içe doldurma yapabiliriz.
          'populate': {
            // 1. seviye populate: inviting_team'i doldur
            'inviting_team': true,
            'player': true,
            // 2. seviye populate: match'i doldur
            'match': {
              // 3. seviye populate: match'in İÇİNDEKİ takımları da doldur
              'populate': ['home_team', 'away_team'],
            },
          },
        },
      );
      final List<dynamic> data = response.data['data'];
      return data.map((i) => SquadInvitation.fromJson(i)).toList();
    } catch (e) {
      // Daha detaylı hata mesajı için
      if (e is DioException) {
        print(e.response?.data);
      }
      throw Exception("Davetiyeler alınamadı: $e");
    }
  }

  // Oyuncunun davete cevap vermesi
  Future<void> respondToInvitation({
    required String invitationDocumentId,
    required String status,
  }) async {
    await _dio.put(
      '/api/squad-invitations/$invitationDocumentId',
      data: {
        'data': {'invite_status': status},
      },
    );
  }

  Future<List<SquadInvitation>> getInvitationsForMatch(int matchId) async {
    try {
      final response = await _dio.get(
        '/api/squad-invitations?filters[match][id][\$eq]=$matchId&populate=*',
      );
      final List<dynamic> data = response.data['data'];
      developer.log('HATA BURDA $data');

      return data.map((i) => SquadInvitation.fromJson(i)).toList();
    } catch (e) {
      throw Exception("Maç davetiyeleri alınamadı: $e");
    }
  }
}
