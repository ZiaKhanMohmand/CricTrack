import 'player.dart';
import 'team.dart';

enum MatchState { setup, toss, innings1, innings2, completed }

class BallEvent {
  Map<String, dynamic> toJson() => {
    'runs': runs,
    'batRuns': batRuns,
    'isWicket': isWicket,
    'isWide': isWide,
    'isNoBall': isNoBall,
  };

  factory BallEvent.fromJson(Map<String, dynamic> j) => BallEvent(
    runs: j['runs'],
    batRuns:
        j['batRuns'] ??
        (j['isWide'] == true || j['isNoBall'] == true ? 0 : j['runs']),
    isWicket: j['isWicket'],
    isWide: j['isWide'],
    isNoBall: j['isNoBall'],
  );

  final int runs; // total team runs charged this ball (incl. penalty)
  final int
  batRuns; // runs personally credited to batsman (0 on wide; bat-hit runs on no-ball)
  final bool isWicket;
  final bool isWide;
  final bool isNoBall;

  BallEvent({
    this.runs = 0,
    int? batRuns,
    this.isWicket = false,
    this.isWide = false,
    this.isNoBall = false,
  }) : batRuns = batRuns ?? runs;

  String get display {
    if (isNoBall && batRuns > 0) return 'NB+$batRuns';
    if (isWicket) return 'W';
    if (isWide) return 'WD';
    if (isNoBall) return 'NB';
    return runs.toString();
  }
}

class Over {
  Map<String, dynamic> toJson() => {
    'bowler': bowler.toJson(),
    'balls': balls.map((b) => b.toJson()).toList(),
  };

  factory Over.fromJson(Map<String, dynamic> j) => Over(
    bowler: Player.fromJson(j['bowler']),
  )..balls = (j['balls'] as List).map((b) => BallEvent.fromJson(b)).toList();
  final Player bowler;
  List<BallEvent> balls;

  Over({required this.bowler}) : balls = [];

  // WD and NB don't count as legal ball
  int get legalBalls => balls.where((b) => !b.isWide && !b.isNoBall).length;
  bool get isComplete => legalBalls >= 6;

  int get runsInOver => balls.fold(0, (sum, b) => sum + b.runs);
}

class Innings {
  Map<String, dynamic> toJson() => {
    'battingTeam': battingTeam.toJson(),
    'bowlingTeam': bowlingTeam.toJson(),
    'overs': overs.map((o) => o.toJson()).toList(),
  };

  factory Innings.fromJson(Map<String, dynamic> j) => Innings(
    battingTeam: Team.fromJson(j['battingTeam']),
    bowlingTeam: Team.fromJson(j['bowlingTeam']),
  )..overs = (j['overs'] as List).map((o) => Over.fromJson(o)).toList();
  final Team battingTeam;
  final Team bowlingTeam;
  List<Over> overs;
  Player? striker;
  Player? nonStriker;
  Player? currentBowler;

  Innings({required this.battingTeam, required this.bowlingTeam}) : overs = [];

  int get totalRuns => overs.fold(0, (sum, o) => sum + o.runsInOver);
  int get totalWickets => battingTeam.totalWickets;
  int get totalOvers => overs.length;

  Over? get currentOver => overs.isNotEmpty ? overs.last : null;

  String get scoreDisplay => '$totalRuns/$totalWickets';
  String get oversDisplay {
    final completed = overs.where((o) => o.isComplete).length;
    final currentBalls = currentOver?.isComplete == false
        ? currentOver!.legalBalls
        : 0;
    return '$completed.$currentBalls';
  }
}

class CricMatch {
  final String id;
  final Team team1;
  final Team team2;
  final int totalOvers;
  final bool lastManStands;
  MatchState state;
  Innings? innings1;
  Innings? innings2;
  Team? tossWinner;
  Team? battingFirst;

  CricMatch({
    required this.id,
    required this.team1,
    required this.team2,
    required this.totalOvers,
    this.lastManStands = false,
  }) : state = MatchState.setup;

  Innings? get currentInnings {
    if (state == MatchState.innings1) return innings1;
    if (state == MatchState.innings2) return innings2;
    return null;
  }

  Team? get winner {
    if (state != MatchState.completed) return null;
    final s1 = innings1?.totalRuns ?? 0;
    final s2 = innings2?.totalRuns ?? 0;
    if (s1 > s2) return innings1?.battingTeam;
    if (s2 > s1) return innings2?.battingTeam;
    return null; // tie
  }
}
