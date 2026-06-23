import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../models/team.dart';

class MatchProvider extends ChangeNotifier {
  CricMatch? currentMatch;

  final _uuid = const Uuid();

  // --- SETUP ---

  void createMatch(
    String team1Name,
    String team2Name,
    int overs, {
    bool lastManStands = false,
  }) {
    final t1 = Team(id: _uuid.v4(), name: team1Name);
    final t2 = Team(id: _uuid.v4(), name: team2Name);
    currentMatch = CricMatch(
      id: _uuid.v4(),
      team1: t1,
      team2: t2,
      totalOvers: overs,
      lastManStands: lastManStands,
    );
    notifyListeners();
  }

  void addPlayerToTeam(Team team, String playerName) {
    team.addPlayer(Player(id: _uuid.v4(), name: playerName));

    // late arrival: if batting team + last man alone, new player = nonStriker
    final inn = currentMatch?.currentInnings;
    if (inn != null &&
        team == inn.battingTeam &&
        inn.nonStriker == null &&
        inn.striker != null) {
      inn.nonStriker = team.players.last;
    }

    notifyListeners();
  }

  void startInnings(Team battingTeam, Team bowlingTeam) {
    final innings = Innings(battingTeam: battingTeam, bowlingTeam: bowlingTeam);
    if (currentMatch!.innings1 == null) {
      currentMatch!.innings1 = innings;
      currentMatch!.state = MatchState.innings1;
    } else {
      currentMatch!.innings2 = innings;
      currentMatch!.state = MatchState.innings2;
    }
    notifyListeners();
  }

  void setOpeningBatsmen(Player striker, Player nonStriker) {
    final inn = currentMatch!.currentInnings!;
    inn.striker = striker;
    inn.nonStriker = nonStriker;
    notifyListeners();
  }

  void setCurrentBowler(Player bowler) {
    final inn = currentMatch!.currentInnings!;
    inn.currentBowler = bowler;
    // start new over
    inn.overs.add(Over(bowler: bowler));
    notifyListeners();
  }

  // --- SCORING ---

  void addBall(BallEvent event) {
    final inn = currentMatch!.currentInnings!;
    final over = inn.currentOver;
    if (over == null) {
      // No bowler selected yet — caller must select bowler first.
      return;
    }

    over.balls.add(event);

    // update bowler stats
    final bowler = inn.currentBowler!;
    bowler.runsConceded += event.runs;
    if (event.isWicket) bowler.wicketsTaken++;

    if (!event.isWide && !event.isNoBall) {
      bowler.ballsInCurrentOver++;
      final facingBatter = inn.striker;
      if (facingBatter == null) return;
      facingBatter.runs += event.runs;
      if (event.runs == 4) facingBatter.balls4s++;
      if (event.runs == 6) facingBatter.balls6s++;
      facingBatter.ballsFaced++;
      if (event.runs % 2 != 0) _rotateStrike();
      if (event.isWicket) {
        facingBatter.isOut = true;
        inn.striker = null; // clear striker immediately on wicket
      }
    }

    if (over.isComplete) {
      bowler.oversBowled++;
      bowler.ballsInCurrentOver = 0;
      if (inn.nonStriker != null) _rotateStrike(); // ADD null guard
    }

    notifyListeners();
  }

  void _rotateStrike() {
    final inn = currentMatch!.currentInnings!;
    if (inn.nonStriker == null) return; // last man alone, no rotate
    final temp = inn.striker;
    inn.striker = inn.nonStriker;
    inn.nonStriker = temp;
  }

  void setNextBatsman(Player player) {
    final inn = currentMatch!.currentInnings!;
    if (inn.striker == null) {
      inn.striker = player;
    } else {
      inn.nonStriker = player; // fill vacant nonStriker slot
    }
    notifyListeners();
  }

  void setLastManBatsAlone() {
    final inn = currentMatch!.currentInnings!;
    inn.striker = inn.nonStriker;
    inn.nonStriker = null;
    notifyListeners();
  }

  void retireHurt(Player player) {
    final inn = currentMatch?.currentInnings;
    if (inn == null) return;
    player.retiredHurt = true;

    final wasStriker = inn.striker?.id == player.id;
    if (inn.striker?.id == player.id) inn.striker = null;
    if (inn.nonStriker?.id == player.id) inn.nonStriker = null;

    // if striker retired + nonStriker exists → promote nonStriker to strike
    if (wasStriker && inn.nonStriker != null) {
      inn.striker = inn.nonStriker;
      inn.nonStriker = null;
    }

    notifyListeners();
  }

  void returnFromRetirement(Player player) {
    final inn = currentMatch?.currentInnings;
    if (inn == null) return;
    player.retiredHurt = false;
    if (inn.striker == null) {
      inn.striker = player; // fill vacant striker slot first
    } else {
      inn.nonStriker = player;
    }
    notifyListeners();
  }

  List<Player> get retiredHurtPlayers {
    final inn = currentMatch?.currentInnings;
    if (inn == null) return [];
    return inn.battingTeam.players.where((p) => p.retiredHurt).toList();
  }

  // --- INNINGS / MATCH END ---

  bool get isInningsOver {
    final inn = currentMatch!.currentInnings;
    if (inn == null) return false;
    final playerCount = inn.battingTeam.players.length;
    // last man stands: need ALL out; else normal (n-1)
    final maxWickets = currentMatch!.lastManStands
        ? playerCount // all must be out
        : playerCount - 1; // standard
    final oversUp =
        inn.overs.where((o) => o.isComplete).length >= currentMatch!.totalOvers;
    return inn.totalWickets >= maxWickets || oversUp;
  }

  void endInnings() {
    if (currentMatch!.state == MatchState.innings1) {
      currentMatch!.state = MatchState.innings2;
    } else {
      currentMatch!.state = MatchState.completed;
    }
    notifyListeners();
  }

  void undoLastBall() {
    final inn = currentMatch!.currentInnings!;
    if (inn.overs.isEmpty) return;

    final over = inn.currentOver!;
    if (over.balls.isEmpty) return;

    final last = over.balls.removeLast();
    final bowler = inn.currentBowler!;

    bowler.runsConceded -= last.runs;
    if (last.isWicket) bowler.wicketsTaken--;

    if (!last.isWide && !last.isNoBall) {
      bowler.ballsInCurrentOver--;

      if (last.runs % 2 != 0) _rotateStrike();

      final batter = inn.striker;
      if (batter != null) {
        batter.runs -= last.runs;
        batter.ballsFaced--;
        if (last.isWicket) batter.isOut = false;
      }
    }

    notifyListeners();
  }

  void swapStrike() {
    _rotateStrike();
    notifyListeners();
  }

  void setToss(Team tossWinner, Team battingFirst) {
    currentMatch!.tossWinner = tossWinner;
    currentMatch!.battingFirst = battingFirst;
    notifyListeners();
  }

  void abandonMatch() {
    currentMatch = null;
    notifyListeners();
  }

  void changeStriker(Player player) {
    currentMatch!.currentInnings!.striker = player;
    notifyListeners();
  }

  void changeNonStriker(Player player) {
    currentMatch!.currentInnings!.nonStriker = player;
    notifyListeners();
  }

  void changeBowler(Player player) {
    final inn = currentMatch!.currentInnings!;
    if (inn.overs.isNotEmpty && (inn.currentOver?.balls.isEmpty ?? false)) {
      inn.overs.removeLast();
    }
    inn.currentBowler = player;
    inn.overs.add(Over(bowler: player));
    notifyListeners();
  }
}
