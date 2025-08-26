import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Bu satır, build_runner'ın bu dosya için kod üreteceğini belirtir.
part 'auth_provider.g.dart';

// Bu enum, 3 farklı kimlik doğrulama durumunu yönetmemizi sağlar:
// 1. unknown: Uygulama ilk açıldığında, token'ın var olup olmadığını henüz bilmiyoruz.
// 2. authenticated: Token var, kullanıcı giriş yapmış.
// 3. unauthenticated: Token yok, kullanıcı misafir.
enum AuthStatus { unknown, authenticated, unauthenticated }

// @Riverpod anotasyonu, build_runner'a bu class için bir provider üretmesini söyler.
// keepAlive: true ise, provider'ın durumunun uygulama boyunca korunmasını,
// yani kullanıcı farklı sayfalara gitse bile login durumunun kaybolmamasını sağlar.
@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  // Güvenli depolama için bir nesne oluşturuyoruz.
  final _secureStorage = const FlutterSecureStorage();

  // 'build' metodu, provider ilk çağrıldığında bir kere çalışır ve başlangıç durumunu belirler.
  // Bu işlem asenkron olacağı için Future döner.
  @override
  Future<AuthStatus> build() async {
    // Cihazın hafızasında 'jwt' anahtarıyla kaydedilmiş bir token var mı diye kontrol et.
    final token = await _secureStorage.read(key: 'jwt');

    // Eğer token varsa, kullanıcı giriş yapmış demektir.
    if (token != null) {
      return AuthStatus.authenticated;
    }

    // Eğer token yoksa, kullanıcı misafir demektir.
    return AuthStatus.unauthenticated;
  }

  // Bu metot, login işlemi başarılı olduğunda çağrılacak.
  Future<void> login(String token) async {
    // UI'ın haberdar olması için durumu "yükleniyor" olarak güncelliyoruz.
    state = const AsyncValue.loading();
    try {
      // Gelen token'ı güvenli depolamaya yaz.
      await _secureStorage.write(key: 'jwt', value: token);
      // Durumu "authenticated" olarak güncelle.
      state = AsyncValue.data(AuthStatus.authenticated);
    } catch (e) {
      // Hata olursa durumu "error" olarak güncelle.
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Bu metot, logout işlemi yapıldığında çağrılacak.
  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      // Token'ı güvenli depolamadan sil.
      await _secureStorage.delete(key: 'jwt');
      // Durumu "unauthenticated" olarak güncelle.
      state = AsyncValue.data(AuthStatus.unauthenticated);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
