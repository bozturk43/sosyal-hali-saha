import 'package:flutter/material.dart';
import 'package:sosyal_halisaha/core/constants/app_colors.dart';

class AppScaffold extends StatelessWidget {
  // Dışarıdan bir AppBar alabiliriz (isteğe bağlı).
  final PreferredSizeWidget? appBar;
  // Dışarıdan sayfanın asıl içeriğini (body) alacağız (zorunlu).
  final Widget body;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    // Standart Scaffold'ı kullanıyoruz ama önemli bir değişiklikle.
    return Scaffold(
      // 1. Scaffold'ın kendi arka plan rengini şeffaf yapıyoruz.
      backgroundColor: Colors.transparent,
      appBar: appBar,
      // 2. Scaffold'ın body'sini, gradient'i uyguladığımız bir Container ile sarmalıyoruz.
      floatingActionButton: floatingActionButton,
      body: Container(
        height: double
            .infinity, // Container'ın tüm ekran yüksekliğini kaplamasını sağla
        width: double
            .infinity, // Container'ın tüm ekran genişliğini kaplamasını sağla
        decoration: const BoxDecoration(
          // 3. Renk sabitleri dosyamızdan gradient'i burada uyguluyoruz.
          gradient: simpleChampionsLeagueGradient,
        ),
        // 4. Dışarıdan gelen asıl sayfa içeriğini (bizim formumuz vb.) bu gradient'li
        //    Container'ın içine yerleştiriyoruz.
        child: body,
      ),
    );
  }
}
