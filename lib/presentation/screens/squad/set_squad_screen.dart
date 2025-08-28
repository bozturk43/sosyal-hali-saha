import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosyal_halisaha/data/models/squad_invitation_model.dart';
import 'package:sosyal_halisaha/data/models/user_model.dart';
import 'package:sosyal_halisaha/data/models/match_model.dart' as model;
import 'package:sosyal_halisaha/data/services/invitation_service.dart';
import 'package:sosyal_halisaha/data/services/team_service.dart';
import 'package:sosyal_halisaha/data/services/user_service.dart';
import 'package:sosyal_halisaha/presentation/widgets/app_scaffold.dart';

class SetSquadScreen extends ConsumerStatefulWidget {
  final model.Match match; // <-- DEĞİŞİKLİK BURADA
  const SetSquadScreen({super.key, required this.match});

  @override
  ConsumerState<SetSquadScreen> createState() => _SetSquadScreenState();
}

class _SetSquadScreenState extends ConsumerState<SetSquadScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final captainTeam = (currentUser?.team?.id == widget.match.homeTeam.id)
        ? widget.match.homeTeam
        : widget.match.awayTeam;
    if (currentUser?.team == null) {
      return const AppScaffold(
        body: Center(child: Text("Bu ekrana erişim için kaptan olmalısınız.")),
      );
    }

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Kadro Kur'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Takım Havuzu'),
            Tab(text: 'Joker Oyuncu Bul'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Sekme: Takım Havuzu
          _PlayerPoolView(
            matchId: widget.match.id,
            teamDocumentId: captainTeam.documentId,
          ),
          // 2. Sekme: Joker Oyuncular (Şimdilik boş)
          const Center(child: Text('Joker oyuncu arama ekranı burada olacak.')),
        ],
      ),
    );
  }
}

// TAKIM HAVUZU SEKMESİNİN WIDGET'I
class _PlayerPoolView extends ConsumerWidget {
  final int matchId;
  final String teamDocumentId;
  const _PlayerPoolView({required this.matchId, required this.teamDocumentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kural 1: Takım detayını 'String documentId' ile çekiyoruz.
    final teamDetailsAsync = ref.watch(teamDetailsProvider(teamDocumentId));
    // Kural 2: Maç davetlerini 'int matchId' ile filtreliyoruz.
    final invitationsAsync = ref.watch(matchInvitationsProvider(matchId));

    return teamDetailsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Hata: $e')),
      data: (team) {
        final playerPool = team.players ?? [];
        if (playerPool.isEmpty) {
          return const Center(child: Text('Takım havuzunuzda hiç oyuncu yok.'));
        }
        return invitationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Hata: $e')),
          data: (invitations) {
            return ListView.builder(
              itemCount: playerPool.length,
              itemBuilder: (context, index) {
                final player = playerPool[index];
                // Bu oyuncu için bir davet var mı diye kontrol et
                final existingInvitation = invitations
                    .where((inv) => inv.player?.id == player.id)
                    .firstOrNull;

                return ListTile(
                  leading: CircleAvatar(child: Text(player.username[0])),
                  title: Text(player.fullName ?? player.username),
                  subtitle: Text(player.preferredPosition ?? 'Mevki belirsiz'),
                  trailing: _buildTrailingWidget(
                    context,
                    ref,
                    player,
                    existingInvitation,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTrailingWidget(
    BuildContext context,
    WidgetRef ref,
    User player,
    SquadInvitation? invitation,
  ) {
    if (invitation != null) {
      switch (invitation.status) {
        case 'pending':
          return const Chip(
            label: Text('Bekleniyor'),
            backgroundColor: Colors.orange,
          );
        case 'accepted':
          return const Chip(
            label: Text('Kabul Etti'),
            backgroundColor: Colors.green,
          );
        case 'rejected':
          return const Chip(
            label: Text('Reddetti'),
            backgroundColor: Colors.red,
          );
        default:
          return const SizedBox.shrink();
      }
    } else {
      return ElevatedButton(
        child: const Text('Davet Et'),
        onPressed: () async {
          final teamId = ref.read(currentUserProvider).value!.team!.id;
          await ref
              .read(invitationServiceProvider)
              .createInvitation(
                matchId: matchId,
                playerId: player.id,
                teamId: teamId,
              );
          // Davet gönderdikten sonra listeyi yenile
          ref.invalidate(matchInvitationsProvider(matchId));
        },
      );
    }
  }
}
