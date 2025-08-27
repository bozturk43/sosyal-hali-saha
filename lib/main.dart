import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosyal_halisaha/core/constants/app_colors.dart';
import 'package:sosyal_halisaha/core/router/app_router.dart'; // Kendi router dosyamızı import ediyoruz
import 'package:intl/date_symbol_data_local.dart'; // <-- YENİ IMPORT
import 'package:flutter_localizations/flutter_localizations.dart'; // <-- YENİ IMPORT

Future<void> main() async {
  // main fonksiyonu async olduğunda, Flutter'ın başlatıldığından
  // emin olmak için bu satır gereklidir.
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe dil ve tarih formatlama verilerini yüklüyoruz.
  await initializeDateFormatting('tr_TR', null);

  runApp(const ProviderScope(child: MyApp()));
}

// MyApp widget'ımızı, provider'ları dinleyebilmesi (watch) için
// StatelessWidget yerine ConsumerWidget'a dönüştürüyoruz.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // routerProvider'ı dinleyerek GoRouter nesnemizi alıyoruz.
    // ref.watch sayesinde, router'ımız auth durumu gibi değişikliklere tepki verebilir.
    final router = ref.watch(routerProvider);

    // Standart MaterialApp yerine, GoRouter'ı kullanabilmek için
    // MaterialApp.router'ı kullanıyoruz.
    return MaterialApp.router(
      title: 'Sosyal Halısaha',
      debugShowCheckedModeBanner:
          false, // Sağ üstteki "debug" etiketini kaldırır
      // Yönlendirme yapılandırmasını tamamen GoRouter'a devrediyoruz.
      // Artık hangi sayfanın gösterileceğine bu router karar verecek.
      routerConfig: router,
      // --- LOKALİZASYON AYARLARI ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR')],

      // Uygulama geneli tema ayarlarını buraya ekleyebiliriz.
      theme: ThemeData(
        // ColorScheme'e hem renk tohumunu hem de karanlık modda olmasını söylüyoruz.
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.championsLeagueBlueDark,
          brightness: Brightness.dark, // <-- AYARI BURAYA TAŞIDIK
          primary: AppColors.championsLeagueBlueLight,
          onPrimary: AppColors.primaryWhite,
        ),
        useMaterial3: true,
        fontFamily: 'Cinzel',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors
              .transparent, // Arka plan gradientinin görünmesi için şeffaf
          elevation: 0, // Gölgeyi kaldırır
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryWhite,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.championsLeagueBlueLight,
            foregroundColor: AppColors.primaryWhite,
            textStyle: const TextStyle(
              fontFamily: 'Cinzel',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Yuvarlak kenarlar
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(
              color: AppColors.championsLeagueBlueLight,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(
              color: AppColors.primaryWhite,
              width: 2,
            ),
          ),
          labelStyle: TextStyle(color: AppColors.primaryWhite.withOpacity(0.8)),
          hintStyle: TextStyle(color: AppColors.primaryWhite.withOpacity(0.6)),
          fillColor: AppColors.championsLeagueBlueLight.withOpacity(0.1),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.championsLeagueBlueDark.withAlpha(
            200,
          ), // Hafif şeffaf arka plan
          selectedItemColor: AppColors.primaryWhite,
          unselectedItemColor: AppColors.primaryWhite.withOpacity(0.6),
          type: BottomNavigationBarType.fixed,
        ),
        // Bu satıra artık gerek yok, çünkü brightness ColorScheme'den otomatik olarak alınıyor.
        // brightness: Brightness.dark,
      ),
    );
  }
}
