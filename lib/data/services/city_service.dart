import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosyal_halisaha/core/constants/api_constants.dart';
import 'package:sosyal_halisaha/data/models/city_model.dart';
import 'package:sosyal_halisaha/data/services/dio_provider.dart';
import 'dart:developer' as developer;

// CityService'i uygulama genelinde erişilebilir kılmak için provider.
final cityServiceProvider = Provider<CityService>((ref) {
  return CityService(ref.watch(dioProvider));
});

// Kayıt ekranında şehir listesini çekmek için kullanacağımız FutureProvider.
// Bu provider, şehirleri API'den çeker ve UI'da kolayca göstermemizi sağlar.
final citiesProvider = FutureProvider<List<City>>((ref) {
  final cityService = ref.watch(cityServiceProvider);
  return cityService.getCities();
});

class CityService {
  final Dio _dio;
  CityService(this._dio);

  // Strapi'den tüm şehirleri çeken metot.
  Future<List<City>> getCities() async {
    try {
      final response = await _dio.get(ApiConstants.cities);
      developer.log('RAW CITIES RESPONSE: ${response.data}');

      // Gelen cevaptaki 'data' listesini alıp her bir elemanı City modeline dönüştürüyoruz.
      final List<dynamic> data = response.data['data'];
      return data.map((cityJson) => City.fromJson(cityJson)).toList();
    } on DioException catch (e) {
      throw Exception('Şehirler yüklenemedi: ${e.message}');
    }
  }
}
