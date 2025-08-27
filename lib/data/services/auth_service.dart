import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosyal_halisaha/core/constants/api_constants.dart';
import 'package:sosyal_halisaha/data/services/dio_provider.dart';
import 'package:sosyal_halisaha/data/models/enums.dart';

// AuthService'i diğer yerlerden erişilebilir kılmak için bir provider oluşturuyoruz.
final authServiceProvider = Provider<AuthService>((ref) {
  // Dio provider'ımızı okuyarak Dio nesnesini alıyoruz.
  final dio = ref.watch(dioProvider);
  return AuthService(dio);
});

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  // --- KULLANICI KAYIT METODU ---
  // Bu metot, UI'dan aldığı bilgilerle Strapi'ye kayıt isteği atar.
  Future<String> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required int cityId, // Yeni eklendi
    required PlayerPosition position, // Yeni eklendi
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'fullName': fullName,
          // Strapi'de ilişki (relation) alanına ID'yi bu şekilde gönderiyoruz.
          'city': cityId,
          // Enum'ın Strapi'nin beklediği string değerini gönderiyoruz.
          'preferredPosition': position.value,
        },
      );

      final token = response.data['jwt'] as String;
      return token;
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['error']['message'] ?? 'Bilinmeyen bir hata oluştu.';
      throw Exception(errorMessage);
    }
  }

  // --- KULLANICI GİRİŞ METODU ---
  // Bu metot, UI'dan aldığı bilgilerle Strapi'ye giriş isteği atar.
  Future<String> login({
    required String
    identifier, // Strapi, giriş için username veya email kabul eder
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'identifier': identifier, 'password': password},
      );

      final token = response.data['jwt'] as String;
      return token;
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['error']['message'] ?? 'Bilinmeyen bir hata oluştu.';
      throw Exception(errorMessage);
    }
  }
}
