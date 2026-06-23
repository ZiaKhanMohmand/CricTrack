import 'player.dart';

class Team {
  String id;
  String name;
  List<Player> players;

  Team({required this.id, required this.name}) : players = [];

  void addPlayer(Player player) => players.add(player);

  Player? get nextBatsman {
    return players.firstWhere(
      (p) => !p.isOut && p.ballsFaced == 0,
      orElse: () => players.firstWhere((p) => !p.isOut),
    );
  }

  int get totalWickets => players.where((p) => p.isOut).length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'players': players.map((p) => p.toJson()).toList(),
  };

  factory Team.fromJson(Map<String, dynamic> j) => Team(
    id: j['id'],
    name: j['name'],
  )..players = (j['players'] as List).map((p) => Player.fromJson(p)).toList();
}
