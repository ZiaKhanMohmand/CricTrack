import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';
import '../../models/team.dart';
import '../scoring/scoring_screen.dart';

class TossScreen extends StatefulWidget {
  const TossScreen({super.key});

  @override
  State<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends State<TossScreen> {
  Team? _tossWinner;
  String? _choice; // 'bat' or 'bowl'

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MatchProvider>();
    final match = provider.currentMatch!;
    final teams = [match.team1, match.team2];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toss'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Who won the toss?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: teams.map((t) {
                final selected = _tossWinner?.id == t.id;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: selected
                            ? const Color(0xFF1B5E20)
                            : Colors.white,
                        foregroundColor: selected
                            ? Colors.white
                            : const Color(0xFF1B5E20),
                        side: const BorderSide(color: Color(0xFF1B5E20)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => setState(() {
                        _tossWinner = t;
                        _choice = null;
                      }),
                      child: Text(t.name),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_tossWinner != null) ...[
              const SizedBox(height: 32),
              Text(
                '${_tossWinner!.name} chose to...',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _choice == 'bat'
                              ? const Color(0xFF1B5E20)
                              : Colors.white,
                          foregroundColor: _choice == 'bat'
                              ? Colors.white
                              : const Color(0xFF1B5E20),
                          side: const BorderSide(color: Color(0xFF1B5E20)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => setState(() => _choice = 'bat'),
                        child: const Text('Bat'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _choice == 'bowl'
                            ? const Color(0xFF1B5E20)
                            : Colors.white,
                        foregroundColor: _choice == 'bowl'
                            ? Colors.white
                            : const Color(0xFF1B5E20),
                        side: const BorderSide(color: Color(0xFF1B5E20)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => setState(() => _choice = 'bowl'),
                      child: const Text('Bowl'),
                    ),
                  ),
                ],
              ),
            ],

            const Spacer(),

            if (_tossWinner != null && _choice != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    final battingTeam = _choice == 'bat'
                        ? _tossWinner!
                        : (match.team1.id == _tossWinner!.id
                              ? match.team2
                              : match.team1);
                    final bowlingTeam = battingTeam.id == match.team1.id
                        ? match.team2
                        : match.team1;

                    provider.setToss(_tossWinner!, battingTeam);
                    provider.startInnings(battingTeam, bowlingTeam);

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScoringScreen()),
                    );
                  },
                  child: const Text('Start Match →'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
