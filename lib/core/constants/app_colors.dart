// lib/core/constants/app_colors.dart
// (Bu dosyayı henüz oluşturmadıysak, lib/core/constants/ klasörüne ekleyelim)

import 'package:flutter/material.dart';

class AppColors {
  // Şampiyonlar Ligi Mavi Tonları
  static const Color championsLeagueBlueDark = Color(
    0xFF001A5E,
  ); // Koyu lacivert
  static const Color championsLeagueBlueLight = Color(
    0xFF1E3A8A,
  ); // Biraz daha açık mavi

  // Diğer olası renkler
  static const Color primaryWhite = Colors.white;
  static const Color primaryBlack = Colors.black;
}

// Uygulama genelinde kullanılacak gradient
const LinearGradient championsLeagueGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    AppColors.championsLeagueBlueDark,
    AppColors.championsLeagueBlueLight,
    AppColors.primaryWhite, // Beyaza doğru geçiş
  ],
  stops: [0.0, 0.6, 1.0], // Geçiş noktaları
);

// Başka bir gradient çeşidi (Eğer sadece mavi ve beyaz yeterliyse)
const LinearGradient simpleChampionsLeagueGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.championsLeagueBlueDark, AppColors.primaryWhite],
  stops: [0.0, 1.0],
);
