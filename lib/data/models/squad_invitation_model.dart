// lib/data/models/squad_invitation_model.dart
import 'package:sosyal_halisaha/data/models/match_model.dart';
import 'package:sosyal_halisaha/data/models/team_model.dart';
import 'package:sosyal_halisaha/data/models/user_model.dart';

class SquadInvitation {
  final int id;
  final String documentId;
  final String status;
  final Match match;
  final User player;
  final Team invitingTeam;

  SquadInvitation({
    required this.id,
    required this.documentId,
    required this.status,
    required this.match,
    required this.player,
    required this.invitingTeam,
  });

  factory SquadInvitation.fromJson(Map<String, dynamic> json) {
    return SquadInvitation(
      id: json['id'],
      documentId: json['documentId'],
      status: json['invite_status'], // Alan adını güncelle
      match: Match.fromJson(json['match']),
      player: User.fromJson(json['player']),
      invitingTeam: Team.fromJson(json['inviting_team']),
    );
  }
}
