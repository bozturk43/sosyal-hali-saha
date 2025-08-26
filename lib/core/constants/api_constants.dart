class ApiConstants {
  // Strapi sunucunun çalıştığı ana adres.
  // EĞER ANDROID EMULATOR KULLANIYORSAN, 'localhost' YERİNE '10.0.2.2' YAZMALISIN.
  // Örn: static const String baseUrl = 'http://10.0.2.2:1337';
  static const String baseUrl = 'http://10.0.2.2:1337';

  // Strapi V4, tüm API isteklerinin başında /api olmasını gerektirir.
  static const String apiPrefix = '/api';

  // Auth endpoint'leri
  static const String register = '$apiPrefix/auth/local/register';
  static const String login = '$apiPrefix/auth/local';

  // Diğer endpoint'leri daha sonra buraya ekleyeceğiz.
  // static const String teams = '$apiPrefix/teams';
}
