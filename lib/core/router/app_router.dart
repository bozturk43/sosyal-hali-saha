import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosyal_halisaha/presentation/providers/auth_provider.dart';
// Yeni ekranlarımızı ve iskeletimizi import ediyoruz
import 'package:sosyal_halisaha/presentation/screens/auth/register_screen.dart';
import 'package:sosyal_halisaha/presentation/screens/auth/login_screen.dart';
import 'package:sosyal_halisaha/presentation/screens/invitations/invitations_screen.dart';
import 'package:sosyal_halisaha/presentation/screens/main_shell.dart';
import 'package:sosyal_halisaha/data/models/match_model.dart'
    as model; // <-- TAKMA ADI EKLEDİK
import 'package:sosyal_halisaha/presentation/screens/matches/create_match_screen.dart';
import 'package:sosyal_halisaha/presentation/screens/matches/match_detail_screen.dart';
import 'package:sosyal_halisaha/presentation/screens/matches/matches_screen.dart';
import 'package:sosyal_halisaha/presentation/screens/profile/edit_profile_screen.dart';
import 'package:sosyal_halisaha/presentation/screens/profile/profile_screen.dart';
import 'package:sosyal_halisaha/presentation/screens/squad/set_squad_screen.dart';

// ----- GEÇİCİ EKRANLAR -----
// RegisterScreen'i kendi dosyasından import ettiğimiz için buradan silebiliriz.
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text("Ana Sayfa Akışı")));
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text("Login Ekranı")));
}

// ------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (BuildContext context, GoRouterState state) {
      // ... redirect mantığı aynı kalıyor, burayı değiştirmiyoruz ...
      if (authState.isLoading || authState.hasError) return null;
      final status = authState.value;
      final isLoggedIn = status == AuthStatus.authenticated;
      final isGoingToLogin = state.uri.toString() == '/login';
      final isGoingToRegister = state.uri.toString() == '/register';
      if (!isLoggedIn &&
          !isGoingToLogin &&
          !isGoingToRegister &&
          state.uri.toString() != '/')
        return '/login';
      if (isLoggedIn && (isGoingToLogin || isGoingToRegister)) return '/';
      return null;
    },

    // --- ROTA HARİTASINI YENİDEN YAPIYORUZ ---
    routes: [
      // 1. Tab Menüsü OLMAYAN, tam ekran sayfalar
      // Bu rotalar ana iskeletin dışında, kendi başlarına birer ekrandır.
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const LoginScreen(), // Artık gerçek ekranı kullanıyoruz
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/create-match',
        builder: (context, state) => const CreateMatchScreen(),
      ),

      // 2. Tab Menüsü OLAN, ana iskeletin içindeki sayfalar
      // StatefulShellRoute, alttaki tab menüsünü ve o anki ekranı yönetir.
      StatefulShellRoute.indexedStack(
        // Ana iskelet (shell) widget'ımızı burada tanımlıyoruz.
        // 'navigationShell' parametresi, o an aktif olan tab'ın ekranıdır.
        builder: (context, state, navigationShell) {
          // Artık 'child' olarak değil, 'navigationShell' parametresine atıyoruz.
          return MainShell(navigationShell: navigationShell);
        },

        // Her bir tab (dal) için rotaları ve o tab'a ait ekranları tanımlıyoruz.
        branches: [
          // --- 1. TAB (index: 0): Ana Akış ---
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomePage()),
            ],
          ),
          // --- 2. TAB (index: 1): Maçlarım ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/matches',
                builder: (context, state) => const MatchesScreen(),
                routes: [
                  GoRoute(
                    path: ':documentId',
                    builder: (context, state) {
                      // 'id' yerine 'documentId'yi okuyoruz
                      final documentId = state.pathParameters['documentId']!;
                      return MatchDetailScreen(documentId: documentId);
                    },
                    routes: [
                      // YENİ ALT ROTA
                      GoRoute(
                        path: 'set-squad', // /matches/:documentId/set-squad
                        builder: (context, state) {
                          // Maçın documentId'sini alıp ekrana iletiyoruz.
                          final match = state.extra as model.Match;
                          return SetSquadScreen(match: match);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invitations',
                builder: (context, state) => const InvitationsScreen(),
              ),
            ],
          ),

          // --- 3. TAB (index: 2): Profil ---
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit', // '/profile/edit' olarak birleşir
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// Bu yardımcı class aynı kalıyor.
class GoRouterRefreshStream extends ChangeNotifier {
  late final ProviderSubscription _subscription;
  GoRouterRefreshStream(Ref ref) {
    _subscription = ref.listen(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }
  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
