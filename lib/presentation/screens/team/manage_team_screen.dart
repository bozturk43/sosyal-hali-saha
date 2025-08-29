import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosyal_halisaha/data/models/user_model.dart';
import 'package:sosyal_halisaha/data/services/team_service.dart';
import 'package:sosyal_halisaha/presentation/widgets/app_scaffold.dart';
// Joker oyuncu arama mantığını burada da kullanacağız.
import 'package:sosyal_halisaha/data/services/user_service.dart';

class ManageTeamScreen extends ConsumerWidget {
  final String teamDocumentId;
  const ManageTeamScreen({super.key, required this.teamDocumentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Takımın en güncel detaylarını (oyuncu havuzu dahil) çekiyoruz.
    final teamAsyncValue = ref.watch(teamDetailsProvider(teamDocumentId));

    return AppScaffold(
      appBar: AppBar(title: const Text('Oyuncu Havuzunu Yönet')),
      body: teamAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Hata: $e')),
        data: (team) {
          final playerPool = team.players;
          return Column(
            children: [
              Expanded(
                child: playerPool.isEmpty
                    ? const Center(
                        child: Text('Takım havuzunda hiç oyuncu yok.'),
                      )
                    : ListView.builder(
                        itemCount: playerPool.length,
                        itemBuilder: (context, index) {
                          final player = playerPool[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(player.username[0]),
                              ),
                              title: Text(player.fullName ?? player.username),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  // Oyuncuyu havuzdan çıkarma
                                  final playerIds = playerPool
                                      .map((p) => p.id)
                                      .toList();
                                  await ref
                                      .read(teamServiceProvider)
                                      .removePlayerFromPool(
                                        teamId: team.id,
                                        existingPlayerIds: playerIds,
                                        playerToRemoveId: player.id,
                                      );
                                  // Başarılı olunca listeyi yenile
                                  ref.invalidate(
                                    teamDetailsProvider(teamDocumentId),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Havuza Oyuncu Ekle',
        child: const Icon(Icons.person_add),
        onPressed: () async {
          // Oyuncu arama penceresini aç
          final playerToAdd = await showModalBottomSheet<User>(
            context: context,
            isScrollControlled: true,
            builder: (_) =>
                const _PlayerSearchSheet(), // SetSquadScreen'deki mantığın aynısı
          );

          if (playerToAdd != null) {
            // Bir oyuncu seçildiyse, havuza ekle
            final currentPlayers = teamAsyncValue.value?.players ?? [];
            final currentPlayerIds = currentPlayers.map((p) => p.id).toList();

            await ref
                .read(teamServiceProvider)
                .addPlayerToPool(
                  teamId: teamAsyncValue.value!.id,
                  existingPlayerIds: currentPlayerIds,
                  newPlayerId: playerToAdd.id,
                );
            // Listeyi yenile
            ref.invalidate(teamDetailsProvider(teamDocumentId));
          }
        },
      ),
    );
  }
}

// OYUNCU ARAMA MODAL'I
// Bu, SetSquadScreen'deki _OpponentSearchSheet'in neredeyse aynısı.
// Sadece tüm kullanıcıları arayacak şekilde düzenleyebiliriz.
class _PlayerSearchSheet extends ConsumerStatefulWidget {
  const _PlayerSearchSheet();
  @override
  ConsumerState<_PlayerSearchSheet> createState() => __PlayerSearchSheetState();
}

class __PlayerSearchSheetState extends ConsumerState<_PlayerSearchSheet> {
  // Bu widget'ın içeriği, SetSquadScreen'deki Joker Oyuncu Arama
  // sekmesinin içeriğiyle (filtreler ve liste) çok benzer olacak.
  // Farkı, tüm kullanıcıları arayacak olması.
  // (UserService'e tüm kullanıcıları arayan bir metot ekleyebiliriz)
  @override
  Widget build(BuildContext context) {
    // Şimdilik basit bir yer tutucu
    return const SizedBox(
      height: 400,
      child: Center(child: Text("Oyuncu arama arayüzü burada olacak.")),
    );
  }
}
