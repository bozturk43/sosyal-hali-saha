class ApiConstants {
  // Strapi sunucunun çalıştığı ana adres.
  // EĞER ANDROID EMULATOR KULLANIYORSAN, 'localhost' YERİNE '10.0.2.2' YAZMALISIN.
  // Örn: static const String baseUrl = 'http://10.0.2.2:1337';
  // static const String baseUrl = 'http://192.168.243.2:1337'; //Emulator den test ipsi
  static const String baseUrl =
      'http://192.168.1.104:1337'; //Cihazdan test ipsi

  // Strapi V4, tüm API isteklerinin başında /api olmasını gerektirir.
  static const String apiPrefix = '/api';

  // Auth endpoint'leri
  static const String register = '$apiPrefix/custom-auth/register';
  static const String login = '$apiPrefix/auth/local';

  // Diğer endpoint'leri daha sonra buraya ekleyeceğiz.
  static const String getMe =
      '$apiPrefix/users/me?populate[0]=city&populate[1]=posts&populate[2]=team';
  static const String cities = '$apiPrefix/cities';
  // static const String teams = '$apiPrefix/teams';
}
