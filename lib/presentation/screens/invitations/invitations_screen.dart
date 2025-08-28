import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sosyal_halisaha/data/models/squad_invitation_model.dart';
import 'package:sosyal_halisaha/data/services/invitation_service.dart';

class InvitationsScreen extends ConsumerWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bekleyen davetleri getiren provider'ımızı dinliyoruz.
    final invitationsAsyncValue = ref.watch(myInvitationsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Maç Davetlerim')),
      body: invitationsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Davetler yüklenirken hata oluştu: $err')),
        data: (invitations) {
          if (invitations.isEmpty) {
            return const Center(
              child: Text("Bekleyen maç davetiniz bulunmuyor."),
            );
          }
          // Gelen her davet için bir kart oluşturuyoruz.
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myInvitationsProvider.future),
            child: ListView.builder(
              itemCount: invitations.length,
              itemBuilder: (context, index) {
                final invitation = invitations[index];
                return _InvitationCard(invitation: invitation);
              },
            ),
          );
        },
      ),
    );
  }
}

// Her bir daveti temsil eden kart widget'ı
class _InvitationCard extends ConsumerStatefulWidget {
  final SquadInvitation invitation;
  const _InvitationCard({required this.invitation});

  @override
  ConsumerState<_InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends ConsumerState<_InvitationCard> {
  bool _isLoading = false;

  Future<void> _respond(String status) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(invitationServiceProvider)
          .respondToInvitation(
            invitationDocumentId: widget.invitation.documentId,
            status: status,
          );
      // Yanıt verdikten sonra listeyi yenilemek için provider'ı geçersiz kılıyoruz.
      ref.invalidate(myInvitationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: ${e.toString()}')));
      }
    }
    // Bu widget artık ağaçta olmayacağı için setState çağırmıyoruz.
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.invitation.match;
    final invitingTeam = widget.invitation.invitingTeam;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.titleMedium,
                children: [
                  TextSpan(
                    text: invitingTeam?.name ?? 'Bir takım',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' sizi maça davet ediyor:'),
                ],
              ),
            ),
            const Divider(),
            if (match != null) ...[
              Text(
                '${match.homeTeam?.name} vs ${match.awayTeam?.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${match.location} - ${DateFormat('dd MMMM, HH:mm', 'tr_TR').format(match.startTime)}',
              ),
            ],
            const SizedBox(height: 12),
            // Yükleme durumuna göre butonları veya animasyonu göster
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _respond(
                          'rejected',
                        ), // Strapi'deki enum ile aynı olmalı
                        child: const Text(
                          'Reddet',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _respond(
                          'accepted',
                        ), // Strapi'deki enum ile aynı olmalı
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Kabul Et'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
