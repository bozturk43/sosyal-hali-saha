import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sosyal_halisaha/data/models/team_model.dart';
import 'package:sosyal_halisaha/data/services/match_service.dart';
import 'package:sosyal_halisaha/data/services/user_service.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsyncValue = ref.watch(myMatchesProvider);
    final userAsyncValue = ref.watch(currentUserProvider);
    // Kaptanın bir takımı olup olmadığını kontrol ediyoruz.
    final isCaptain = userAsyncValue.value?.team != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Maçlarım')),
      body: matchesAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
        data: (matches) {
          // Çekerek yenileme (Pull to Refresh) için RefreshIndicator kullanıyoruz.
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myMatchesProvider.future),
            child: matches.isEmpty
                // Eğer liste boşsa, bu mesajı gösteriyoruz.
                // Stack ve ListView ekleyerek, boşken bile yenileme özelliğinin çalışmasını sağlıyoruz.
                ? Stack(
                    children: [
                      ListView(),
                      const Center(
                        child: Text("Henüz bir maçınız bulunmuyor."),
                      ),
                    ],
                  )
                // Liste doluysa, maçları ListView.builder ile çizdiriyoruz.
                : ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      // Her bir kartı tıklanabilir yapmak için InkWell ile sarmalıyoruz.
                      return InkWell(
                        onTap: () {
                          // Tıklandığında, maçın documentId'si ile detay sayfasına yönlendiriyoruz.
                          context.go('/matches/${match.documentId}');
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          elevation: 4,
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
                                    _buildTeamInfo(context, match.homeTeam!),
                                    Text(
                                      'VS',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                    ),
                                    _buildTeamInfo(context, match.awayTeam!),
                                  ],
                                ),
                                const Divider(height: 24),
                                // ... Diğer maç bilgileri (yer, saat, durum vb.) ...
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
                                      DateFormat(
                                        'dd MMMM yyyy, EEEE',
                                        'tr_TR',
                                      ).format(match.startTime),
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
                                      '${DateFormat('HH:mm').format(match.startTime)} - ${DateFormat('HH:mm').format(match.endTime)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
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
                        ),
                      );
                    },
                  ),
          );
        },
      ),
      floatingActionButton: Tooltip(
        message: isCaptain
            ? 'Yeni bir maç ayarla'
            : 'Maç ayarlamak için takım kaptanı olmalısınız.',
        child: FloatingActionButton(
          onPressed: isCaptain
              ? () {
                  // Kullanıcı kaptansa, Maç Oluşturma ekranına yönlendiriyoruz.
                  context.go('/create-match');
                }
              : null, // Kaptan değilse buton pasif (disabled) olur.
          backgroundColor: isCaptain
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTeamInfo(BuildContext context, Team team) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Text(
            team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          child: Text(
            team.name,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

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
