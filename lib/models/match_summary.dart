import 'match.dart';

class MatchSummary {
  final String id;
  final String team1Name;
  final String team2Name;
  final String team1Score;
  final String team2Score;
  final String? winnerName;
  final DateTime playedAt;
  final Innings? innings1;
  final Innings? innings2;

  MatchSummary({
    required this.id,
    required this.team1Name,
    required this.team2Name,
    required this.team1Score,
    required this.team2Score,
    required this.winnerName,
    required this.playedAt,
    this.innings1,
    this.innings2,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'team1Name': team1Name,
    'team2Name': team2Name,
    'team1Score': team1Score,
    'team2Score': team2Score,
    'winnerName': winnerName,
    'playedAt': playedAt.toIso8601String(),
    'innings1': innings1?.toJson(),
    'innings2': innings2?.toJson(),
  };

  factory MatchSummary.fromJson(Map<String, dynamic> json) => MatchSummary(
    id: json['id'],
    team1Name: json['team1Name'],
    team2Name: json['team2Name'],
    team1Score: json['team1Score'],
    team2Score: json['team2Score'],
    winnerName: json['winnerName'],
    playedAt: DateTime.parse(json['playedAt']),
    innings1: json['innings1'] != null
        ? Innings.fromJson(json['innings1'])
        : null,
    innings2: json['innings2'] != null
        ? Innings.fromJson(json['innings2'])
        : null,
  );
}
