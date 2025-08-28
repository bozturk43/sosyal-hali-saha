import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sosyal_halisaha/data/models/match_model.dart';
import 'package:sosyal_halisaha/data/models/team_model.dart';
import 'package:sosyal_halisaha/data/models/user_model.dart';
import 'package:sosyal_halisaha/data/services/match_service.dart';
import 'package:sosyal_halisaha/data/services/user_service.dart';
import 'package:sosyal_halisaha/presentation/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';

class MatchDetailScreen extends ConsumerWidget {
  final String documentId;
  const MatchDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // documentId'ye göre maç detaylarını çeken provider'ı dinle
    final matchAsyncValue = ref.watch(matchDetailsProvider(documentId));
    // Mevcut kullanıcıyı al (kaptan olup olmadığını kontrol etmek için)
    final currentUser = ref.watch(currentUserProvider).value;

    return AppScaffold(
      appBar: AppBar(title: const Text('Maç Detayı')),
      body: matchAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Hata: $e')),
        data: (match) {
          if (match.homeTeam == null || match.awayTeam == null) {
            return const Center(
              child: Text('Maçın takım bilgileri eksik veya yüklenemedi.'),
            );
          }
          // Bu kullanıcı bu maçtaki takımlardan birinin kaptanı mı?
          final isHomeCaptain = match.homeTeam!.captain?.id == currentUser?.id;
          final isAwayCaptain = match.awayTeam!.captain?.id == currentUser?.id;
          final isCaptain = isHomeCaptain || isAwayCaptain;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Takım Bilgileri Başlığı
                _buildTeamHeader(context, match.homeTeam!, match.awayTeam!),
                const SizedBox(height: 24),

                // 2. Maç Detayları Kartı
                _buildMatchInfoCard(context, match),
                const SizedBox(height: 24),

                // 3. Kadrolar Alanı
                _buildSquadsSection(
                  context,
                  'Ev Sahibi Kadrosu',
                  match.homeTeamSquad,
                ),
                const SizedBox(height: 16),
                _buildSquadsSection(
                  context,
                  'Deplasman Kadrosu',
                  match.awayTeamSquad,
                ),
                const SizedBox(height: 40),

                // 4. Kadro Kur Butonu (Sadece belirli koşullarda görünür)
                if (match.status == 'confirmed' && isCaptain)
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text('Kadro Kur'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        textStyle: Theme.of(context).textTheme.titleMedium,
                      ),
                      onPressed: () {
                        // Yönlendirmeyi 'documentId' ile yapıyoruz.
                        context.push(
                          '/matches/${match.documentId}/set-squad',
                          extra: match,
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Arayüzü temiz tutmak için yardımcı metotlar
  Widget _buildTeamHeader(BuildContext context, Team homeTeam, Team awayTeam) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTeamInfo(context, homeTeam),
        Text('VS', style: Theme.of(context).textTheme.displaySmall),
        _buildTeamInfo(context, awayTeam),
      ],
    );
  }

  Widget _buildTeamInfo(BuildContext context, Team team) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          child: Text(
            team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
            style: Theme.of(context).textTheme.headlineLarge,
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
          ),
        ),
      ],
    );
  }

  Widget _buildMatchInfoCard(BuildContext context, Match match) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(match.location),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                DateFormat(
                  'dd MMMM yyyy, EEEE',
                  'tr_TR',
                ).format(match.startTime),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                '${DateFormat('HH:mm').format(match.startTime)} - ${DateFormat('HH:mm').format(match.endTime)}',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: Text('Durum: ${match.status.toUpperCase()}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadsSection(
    BuildContext context,
    String title,
    List<User> squad,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const Divider(),
        if (squad.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Kadro henüz belirlenmedi.'),
          )
        else
          // Kadro listesi
          ...squad
              .map(
                (player) => ListTile(
                  leading: CircleAvatar(child: Text(player.username[0])),
                  title: Text(player.fullName ?? player.username),
                  subtitle: Text(
                    player.preferredPosition ?? 'Mevki Belirtilmemiş',
                  ),
                ),
              )
              .toList(),
      ],
    );
  }
}
