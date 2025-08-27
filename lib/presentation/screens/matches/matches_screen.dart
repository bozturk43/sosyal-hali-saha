// lib/presentation/screens/matches/matches_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sosyal_halisaha/data/models/team_model.dart';
import 'package:intl/intl.dart'; // Tarih formatlamak için
import 'package:sosyal_halisaha/data/services/match_service.dart';
import 'package:sosyal_halisaha/data/services/user_service.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsyncValue = ref.watch(myMatchesProvider);
    final userAsyncValue = ref.watch(currentUserProvider);
    final isCaptain = userAsyncValue.value?.team != null;
    print(userAsyncValue);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Maçlarım')),
      body: matchesAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
        data: (matches) {
          return (RefreshIndicator(
            onRefresh: () async {
              // myMatchesProvider'ı yenilemeye ve API'den veriyi tekrar çekmeye zorluyoruz.
              // '.future' eklemek, bu işlemin tamamlanmasını beklememizi sağlar.
              await ref.refresh(myMatchesProvider.future);
            },
            child: matches.isEmpty
                ? const Center(child: Text("Henüz bir maçınız bulunmuyor."))
                : ListView.builder(
                    // ListView.builder'ın geri kalanı aynı.
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      final currentUser =
                          userAsyncValue.value; // Giriş yapmış kullanıcıyı al
                      bool canRespond =
                          currentUser != null &&
                          match.status == 'pending' &&
                          match.awayTeam.captain?.id == currentUser.id;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 4, // Biraz daha gölge ekleyelim
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildTeamInfo(context, match.homeTeam),
                                  Text(
                                    'VS',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  _buildTeamInfo(context, match.awayTeam),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      match.location,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${DateFormat('dd MMMM yyyy, EEEE').format(match.startTime)}', // Örnek: "27 Ağustos 2025, Çarşamba"
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${DateFormat('HH:mm').format(match.startTime)} - ${DateFormat('HH:mm').format(match.endTime)}', // Örnek: "21:00 - 22:00"
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (canRespond)
                                _buildResponseButtons(context, ref, match.id)
                              else
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Chip(
                                    label: Text(
                                      _getMatchStatusText(match.status),
                                    ),
                                    backgroundColor: _getMatchStatusColor(
                                      match.status,
                                    ),
                                    labelStyle: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ));
        },
      ),
      floatingActionButton: Tooltip(
        message: isCaptain
            ? 'Yeni bir maç ayarla'
            : 'Maç ayarlamak için takım kaptanı olmalısınız.',
        child: FloatingActionButton(
          onPressed: isCaptain
              ? () {
                  // Maç ayarlama ekranına yönlendir.
                  context.push('/create-match');
                }
              : null,
          backgroundColor: isCaptain
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Takım bilgilerini ve avatarını gösteren yardımcı widget
  Widget _buildTeamInfo(BuildContext context, Team team) {
    // Takım logosu için bir URL'niz varsa burada Image.network kullanabilirsiniz.
    // Şimdilik sadece baş harf avatarı gösterelim.
    return Column(
      children: [
        // TEAM AVATAR
        CircleAvatar(
          radius: 30,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.secondary, // Farklı bir renk verelim
          child: Text(
            team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          team.name,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Onay/Reddet butonlarını oluşturan yeni yardımcı metot
  Widget _buildResponseButtons(
    BuildContext context,
    WidgetRef ref,
    int matchId,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () async {
            await ref
                .read(matchServiceProvider)
                .updateMatchStatus(matchId: matchId, newStatus: 'cancelled');
            ref.invalidate(myMatchesProvider); // Listeyi yenile
          },
          child: const Text('Reddet', style: TextStyle(color: Colors.red)),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            await ref
                .read(matchServiceProvider)
                .updateMatchStatus(matchId: matchId, newStatus: 'confirmed');
            ref.invalidate(myMatchesProvider); // Listeyi yenile
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Onayla'),
        ),
      ],
    );
  }

  // Maç durumuna göre metin döndüren yardımcı fonksiyon
  String _getMatchStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Onay Bekliyor';
      case 'confirmed':
        return 'Onaylandı';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return 'Bilinmiyor';
    }
  }

  // Maç durumuna göre renk döndüren yardımcı fonksiyon
  Color _getMatchStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade700;
      case 'confirmed':
        return Colors.green.shade700;
      case 'completed':
        return Colors.blue.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }
}
