import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sosyal_halisaha/data/services/user_service.dart';
import 'package:sosyal_halisaha/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Artık SADECE tek bir provider dinliyoruz.
    final userAsyncValue = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(userAsyncValue.value?.username ?? 'Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.go('/profile/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap', // Kullanıcıya ipucu
            onPressed: () {
              // authNotifier'daki logout metodunu çağırıyoruz.
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: userAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
        data: (user) {
          // Hem kullanıcı bilgisi hem de gönderi listesi artık 'user' objesinin içinde!
          return Column(
            children: [
              // Üst Profil Bilgisi Alanı
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      child: Text(user.fullName?[0] ?? user.username[0]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName ?? '',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            user.preferredCity?.name ?? 'Şehir Belirtilmemiş',
                          ),
                          Text(user.preferredPosition ?? 'Mevki Belirtilmemiş'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Gönderi Listesi Alanı
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
}
