import 'player.dart';

class Team {
  String id;
  String name;
  List<Player> players;

  Team({required this.id, required this.name}) : players = [];

  void addPlayer(Player player) {
    players.add(player);
  }

  Player? get nextBatsman {
    return players.firstWhere(
      (p) => !p.isOut && p.ballsFaced == 0,
      orElse: () => players.firstWhere((p) => !p.isOut),
    );
  }

  int get totalWickets => players.where((p) => p.isOut).length;
}
