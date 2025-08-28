import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sosyal_halisaha/data/models/city_model.dart';
import 'package:sosyal_halisaha/data/models/enums.dart';
import 'package:sosyal_halisaha/data/models/match_model.dart' as model;
import 'package:sosyal_halisaha/data/models/squad_invitation_model.dart';
import 'package:sosyal_halisaha/data/models/user_model.dart';
import 'package:sosyal_halisaha/data/services/city_service.dart';
import 'package:sosyal_halisaha/data/services/invitation_service.dart';
import 'package:sosyal_halisaha/data/services/team_service.dart';
import 'package:sosyal_halisaha/data/services/user_service.dart';
import 'package:sosyal_halisaha/presentation/widgets/app_scaffold.dart';

// Filtre durumunu tutan provider'lar, dosyanın en üstünde (top-level).
final _cityFilterProvider = StateProvider<City?>((ref) => null);
final _positionFilterProvider = StateProvider<PlayerPosition?>((ref) => null);
final _searchQueryProvider = StateProvider<String>((ref) => '');

// ANA WIDGET
class SetSquadScreen extends ConsumerStatefulWidget {
  final model.Match match;
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
    final userAsyncValue = ref.watch(currentUserProvider);
    if (!userAsyncValue.hasValue) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final user = userAsyncValue.value!;
    if (user.team == null ||
        (user.team!.id != widget.match.homeTeam?.id &&
            user.team!.id != widget.match.awayTeam?.id)) {
      return const AppScaffold(
        body: Center(child: Text("Bu maçın kadrosunu kurma yetkiniz yok.")),
      );
    }
    final captainTeam = user.team!;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Kadroya Oyuncu Ekle'),
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
          _PlayerPoolView(
            matchId: widget.match.id,
            teamDocumentId: captainTeam.documentId,
          ),
          _JokerPlayerView(matchId: widget.match.id),
        ],
      ),
    );
  }
}

// --- ORTAK KULLANILAN YARDIMCI METOT ---
// Bu metot, hem _PlayerPoolView hem de _JokerPlayerView tarafından kullanılacak.
Widget _buildTrailingWidget(
  BuildContext context,
  WidgetRef ref,
  User player,
  SquadInvitation? invitation,
  int matchId,
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
        return const Chip(label: Text('Reddetti'), backgroundColor: Colors.red);
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
        ref.invalidate(matchInvitationsProvider(matchId));
      },
    );
  }
}
// ------------------------------------

// TAKIM HAVUZU SEKMESİNİN WIDGET'I
class _PlayerPoolView extends ConsumerWidget {
  final int matchId;
  final String teamDocumentId;
  const _PlayerPoolView({required this.matchId, required this.teamDocumentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamDetailsAsync = ref.watch(teamDetailsProvider(teamDocumentId));
    final invitationsAsync = ref.watch(matchInvitationsProvider(matchId));

    return teamDetailsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Hata: $e')),
      data: (team) {
        final playerPool = team.players;
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
                    matchId,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// JOKER OYUNCU ARAMA SEKMESİNİN WIDGET'I
class _JokerPlayerView extends ConsumerStatefulWidget {
  final int matchId;
  const _JokerPlayerView({required this.matchId});

  @override
  ConsumerState<_JokerPlayerView> createState() => __JokerPlayerViewState();
}

class __JokerPlayerViewState extends ConsumerState<_JokerPlayerView> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(_searchQueryProvider.notifier).state = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCity = ref.watch(_cityFilterProvider);
    final selectedPosition = ref.watch(_positionFilterProvider);
    final searchQuery = ref.watch(_searchQueryProvider);

    final filter = JokerFilter(
      query: searchQuery,
      cityId: selectedCity?.id,
      position: selectedPosition?.value,
    );
    final jokersAsync = ref.watch(jokerPlayersProvider(filter));
    final invitationsAsync = ref.watch(
      matchInvitationsProvider(widget.matchId),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(labelText: 'İsme Göre Ara'),
              ),
              Row(
                children: [
                  Expanded(child: _buildCityFilter(ref)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPositionFilter(ref)),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: jokersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Hata: $e')),
            data: (jokers) {
              if (jokers.isEmpty)
                return const Center(
                  child: Text('Filtreyle eşleşen joker oyuncu bulunamadı.'),
                );
              return invitationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) =>
                    Center(child: Text('Davet durumları alınamadı: $e')),
                data: (invitations) => ListView.builder(
                  itemCount: jokers.length,
                  itemBuilder: (context, index) {
                    final player = jokers[index];
                    final existingInvitation = invitations
                        .where((inv) => inv.player.id == player.id)
                        .firstOrNull;
                    return ListTile(
                      leading: CircleAvatar(child: Text(player.username[0])),
                      title: Text(player.fullName ?? player.username),
                      subtitle: Text(
                        '${player.preferredCity?.name ?? ""} - ${player.preferredPosition ?? ""}',
                      ),
                      trailing: _buildTrailingWidget(
                        context,
                        ref,
                        player,
                        existingInvitation,
                        widget.matchId,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCityFilter(WidgetRef ref) {
    final citiesAsync = ref.watch(citiesProvider);
    return citiesAsync.when(
      data: (cities) => DropdownButton<City?>(
        value: ref.watch(_cityFilterProvider),
        hint: const Text('Şehir'),
        isExpanded: true,
        items: [
          const DropdownMenuItem(value: null, child: Text('Tüm Şehirler')),
          ...cities.map((c) => DropdownMenuItem(value: c, child: Text(c.name))),
        ],
        onChanged: (val) => ref.read(_cityFilterProvider.notifier).state = val,
      ),
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildPositionFilter(WidgetRef ref) {
    return DropdownButton<PlayerPosition?>(
      value: ref.watch(_positionFilterProvider),
      hint: const Text('Mevki'),
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: null, child: Text('Tüm Mevkiler')),
        ...PlayerPosition.values.map(
          (p) => DropdownMenuItem(value: p, child: Text(p.value)),
        ),
      ],
      onChanged: (val) =>
          ref.read(_positionFilterProvider.notifier).state = val,
    );
  }
}
