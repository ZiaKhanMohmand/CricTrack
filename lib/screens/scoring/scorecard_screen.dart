import 'package:flutter/material.dart';
import '../../models/match.dart';
import '../../models/player.dart';

class ScorecardScreen extends StatelessWidget {
  final Innings innings;
  final String title;
  final bool showAppBar;

  const ScorecardScreen({
    super.key,
    required this.innings,
    required this.title,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // total score card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    innings.battingTeam.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    innings.scoreDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Overs: ${innings.oversDisplay}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // batting table
            _sectionTitle('BATTING'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _tableHeader(['Batter', 'R', 'B', '4s', '6s', 'SR']),
                  const Divider(height: 1),
                  ...innings.battingTeam.players
                      .where(
                        (p) => p.ballsFaced > 0 || p.isOut || p.retiredHurt,
                      )
                      .map((p) => _batsmanRow(p)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // bowling table
            _sectionTitle('BOWLING'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _tableHeader(['Bowler', 'O', 'R', 'W', 'Econ']),
                  const Divider(height: 1),
                  ...innings.bowlingTeam.players
                      .where(
                        (p) => p.oversBowled > 0 || p.ballsInCurrentOver > 0,
                      )
                      .map((p) => _bowlerRow(p)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // over by over
            _sectionTitle('OVER SUMMARY'),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: innings.overs.asMap().entries.map((e) {
                  final i = e.key;
                  final over = e.value;
                  return _overRow(i + 1, over);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1,
      ),
    ),
  );

  Widget _tableHeader(List<String> cols) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: cols.asMap().entries.map((e) {
        final isFirst = e.key == 0;
        return isFirst
            ? Expanded(
                child: Text(
                  e.value,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              )
            : SizedBox(
                width: 40,
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              );
      }).toList(),
    ),
  );

  Widget _batsmanRow(Player p) {
    final sr = p.ballsFaced > 0
        ? ((p.runs / p.ballsFaced) * 100).toStringAsFixed(1)
        : '0.0';
    final fours = p.balls4s;
    final sixes = p.balls6s;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.isOut ? p.name : '${p.name}*',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  p.isOut
                      ? 'out'
                      : p.retiredHurt
                      ? 'retired hurt'
                      : 'not out',
                  style: TextStyle(
                    fontSize: 11,
                    color: p.isOut
                        ? Colors.red
                        : p.retiredHurt
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          _cell('${p.runs}', bold: true),
          _cell('${p.ballsFaced}'),
          _cell('$fours'),
          _cell('$sixes'),
          _cell(sr),
        ],
      ),
    );
  }

  Widget _bowlerRow(Player p) {
    final econ = p.oversBowled > 0
        ? (p.runsConceded / p.oversBowled).toStringAsFixed(1)
        : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          _cell('${p.oversBowled}'),
          _cell('${p.runsConceded}'),
          _cell('${p.wicketsTaken}', bold: true),
          _cell(econ),
        ],
      ),
    );
  }

  Widget _overRow(int num, Over over) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              'Over $num',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Row(children: over.balls.map((b) => _ballChip(b)).toList()),
          ),
          Text(
            '${over.runsInOver} runs',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _cell(String val, {bool bold = false}) => SizedBox(
    width: 40,
    child: Text(
      val,
      textAlign: TextAlign.center,
      style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
    ),
  );

  Widget _ballChip(BallEvent b) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.black;
    if (b.isWicket) {
      bg = Colors.red;
      fg = Colors.white;
    } else if (b.runs == 4) {
      bg = const Color(0xFF1B5E20);
      fg = Colors.white;
    } else if (b.runs == 6) {
      bg = Colors.blue;
      fg = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.only(right: 4),
      width: 26,
      height: 26,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Text(b.display, style: TextStyle(color: fg, fontSize: 10)),
      ),
    );
  }
}
