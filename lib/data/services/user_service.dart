import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosyal_halisaha/core/constants/api_constants.dart';
import 'package:sosyal_halisaha/data/models/user_model.dart';
import 'package:sosyal_halisaha/data/services/dio_provider.dart';

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
}
