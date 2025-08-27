import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sosyal_halisaha/core/constants/app_colors.dart';

// Artık bu widget'ın Riverpod'a (ConsumerWidget) ihtiyacı yok,
// çünkü tüm kararları ve yönlendirmeleri GoRouter'dan alacak.
class MainShell extends StatelessWidget {
  // Artık child yerine, GoRouter'ın bize verdiği özel 'navigationShell' nesnesini alıyoruz.
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient'li Container'ımız ana iskeleti oluşturuyor.
      body: Container(
        decoration: const BoxDecoration(
          gradient: simpleChampionsLeagueGradient,
        ),
        // Aktif ekran (HomePage veya ProfilePage) burada gösterilecek.
        child: navigationShell,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Akış'),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_soccer),
            label: 'Maçlarım',
          ), // <-- YENİ TAB
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        // Hangi tab'ın aktif olduğunu doğrudan navigationShell'den öğreniyoruz.
        currentIndex: navigationShell.currentIndex,
        // Bir tab'a tıklandığında...
        onTap: (int index) {
          // ... GoRouter'a "Sadece tab'ı değiştir" komutunu veriyoruz.
          navigationShell.goBranch(
            index,
            // Eğer zaten o tab'daysak, tab'ın en başına dönmesini sağlar.
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
