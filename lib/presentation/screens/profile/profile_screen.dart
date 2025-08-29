import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sosyal_halisaha/data/models/team_model.dart';
import 'package:sosyal_halisaha/data/models/user_model.dart';
import 'package:sosyal_halisaha/data/models/user_model.dart';
import 'package:sosyal_halisaha/data/services/user_service.dart';
import 'package:sosyal_halisaha/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        // AppBar başlığını kullanıcının kullanıcı adıyla dinamik hale getirelim
        title: Text(userAsyncValue.value?.username ?? 'Profil'),
        actions: [
          // Düzenleme ve Çıkış butonları burada kalabilir.
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Profili Düzenle',
            onPressed: () => context.go('/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: userAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
        data: (user) {
          return Column(
            children: [
              // --- YENİ PROFİL BAŞLIĞI ---
              _buildProfileHeader(context, user),
              const Divider(thickness: 1),

              // --- GÖNDERİ LİSTESİ ---
              Expanded(
                child: user.posts.isEmpty
                    ? const Center(
                        child: Text('Henüz hiç gönderi paylaşmadın.'),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                            ),
                        itemCount: user.posts.length,
                        itemBuilder: (context, index) {
                          final post = user.posts[index];
                          // İleride burası gönderinin resmi/videosu olacak.
                          return Container(
                            color: Colors.grey.shade800,
                            child: Center(child: Text('Gönderi ${post.id}')),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- YENİ YARDIMCI WIDGET: Profil Başlığı ---
  Widget _buildProfileHeader(BuildContext context, User user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Sol Taraf: Avatar ve Bilgiler
          Column(
            children: [
              CircleAvatar(
                radius: 40,
                child: Text(
                  user.fullName?[0] ?? user.username[0],
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.fullName ?? user.username,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                user.preferredCity?.name ?? "Şehir belirtilmemiş",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                user.preferredPosition ?? "Mevki belirtilmemiş",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Sağ Taraf: İstatistikler ve Dinamik Buton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // İstatistikler (Şimdilik yer tutucu)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn('Maç', '0'),
                    _buildStatColumn('Takım', user.team != null ? '1' : '0'),
                    _buildStatColumn('Gönderi', user.posts.length.toString()),
                  ],
                ),
                const SizedBox(height: 16),

                // --- DİNAMİK BUTON ---
                // Kullanıcının takım durumuna göre butonu belirliyoruz.
                user.team == null
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, // Mavi arka plan
                          foregroundColor: Colors.white, // Beyaz ikon ve yazı
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => context.push('/create-team'),
                        icon: const Icon(Icons.add),
                        label: const Text('Takım Oluştur'),
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // Beyaz arka plan
                          foregroundColor: Colors.black, // Siyah ikon ve yazı
                          side: const BorderSide(
                            color: Colors.grey,
                          ), // Gri kenarlık
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => context.push(
                          '/team/${user.team!.documentId}/manage',
                        ),
                        icon: const Icon(Icons.settings),
                        label: const Text('Takımı Yönet'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // İstatistikler için küçük bir yardımcı widget
  Widget _buildStatColumn(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count,
          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
