import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosyal_halisaha/core/constants/api_constants.dart';
import 'package:sosyal_halisaha/data/models/user_model.dart';
import 'package:sosyal_halisaha/data/services/dio_provider.dart';
import 'package:equatable/equatable.dart';
import 'dart:developer' as developer;

class JokerFilter extends Equatable {
  final String query;
  final int? cityId;
  final String? position;
  const JokerFilter({this.query = '', this.cityId, this.position});
  @override
  List<Object?> get props => [query, cityId, position];
}

final jokerPlayersProvider = FutureProvider.autoDispose
    .family<List<User>, JokerFilter>((ref, filter) {
      final userService = ref.watch(userServiceProvider);
      return userService.findJokerPlayers(filter: filter);
    });
final userServiceProvider = Provider(
  (ref) => UserService(ref.watch(dioProvider)),
);

final currentUserProvider = FutureProvider.autoDispose<User>((ref) {
  // autoDispose: Profil sayfasından çıkıldığında veriyi hafızadan siler,
  // tekrar girildiğinde güncel veriyi çeker.
  final userService = ref.watch(userServiceProvider);
  return userService.getMe();
});

class UserService {
  final Dio _dio;
  UserService(this._dio);

  Future<User> getMe() async {
    try {
      final response = await _dio.get(
        ApiConstants.getMe,
      ); // city gibi ilişkileri de çekebiliriz
      print(response);
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Kullanıcı bilgileri alınamadı.');
    }
  }

  Future<User> updateUser(int userId, Map<String, dynamic> data) async {
    try {
      // Strapi'ye PUT isteği atıyoruz.
      // Strapi v4, güncellenecek veriyi bir "data" objesi içinde bekler.
      final response = await _dio.put('/api/users/$userId', data: data);
      // Güncellenmiş kullanıcı bilgisini geri döndürüyoruz.
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Profil güncellenemedi.');
    }
  }

  Future<List<User>> findJokerPlayers({required JokerFilter filter}) async {
    try {
      final queryParameters = <String, dynamic>{'filters[isJoker][\$eq]': true};
      if (filter.query.isNotEmpty) {
        queryParameters['filters[username][\$containsi]'] = filter.query;
      }
      if (filter.cityId != null) {
        queryParameters['filters[city][id][\$eq]'] = filter.cityId;
      }
      if (filter.position != null) {
        queryParameters['filters[preferredPosition][\$eq]'] = filter.position;
      }

      final response = await _dio.get(
        '/api/users?populate=*',
        queryParameters: queryParameters,
      );
      final List<dynamic> data = response.data;
      developer.log('JOKER OYUNCULAR = $data');
      return data.map((userJson) => User.fromJson(userJson)).toList();
    } catch (e) {
      developer.log("HTA BLOGU SERVICE DE");
      throw Exception('Joker oyuncular bulunamadı.');
    }
  }
}
