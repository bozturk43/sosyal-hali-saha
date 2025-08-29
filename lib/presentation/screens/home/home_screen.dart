// lib/presentation/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sosyal_halisaha/data/services/user_service.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mevcut kullanıcıyı ve durumunu dinliyoruz.
    final userAsyncValue = ref.watch(currentUserProvider);

    return Scaffold(
      // Arka planı şeffaf yaparak MainShell'deki gradient'in görünmesini sağlıyoruz.
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Ana Akış')),
      // Provider'ın durumunu (yükleniyor, hata, veri geldi) yönetmek için .when kullanıyoruz.
      body: userAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata: $error')),
        data: (user) {
          // Kullanıcı verisi başarıyla geldiğinde, takımının olup olmadığını kontrol ediyoruz.
          final bool hasTeam = user.team != null;

          // Ana sayfa akışını (ileride gönderiler burada olacak) ve butonu üst üste koymak için Stack kullanıyoruz.
          return Stack(
            children: [
              // ŞİMDİLİK ANA AKIŞ YER TUTUCUSU
              // İleride burası gönderilerin listelendiği bir ListView olacak.
              const Center(
                child: Text('Tüm kullanıcıların gönderileri burada görünecek.'),
              ),
            ],
          );
        },
      ),
    );
  }
}
