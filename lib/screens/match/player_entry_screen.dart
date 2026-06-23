import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';
import 'toss_screen.dart';

class PlayerEntryScreen extends StatefulWidget {
  final int playersPerTeam;
  const PlayerEntryScreen({super.key, required this.playersPerTeam});

  @override
  State<PlayerEntryScreen> createState() => _PlayerEntryScreenState();
}

class _PlayerEntryScreenState extends State<PlayerEntryScreen> {
  final List<TextEditingController> _team1Controllers = [];
  final List<TextEditingController> _team2Controllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.playersPerTeam; i++) {
      _team1Controllers.add(TextEditingController());
      _team2Controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final c in _team1Controllers) {
      c.dispose();
    }
    for (final c in _team2Controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MatchProvider>();
    final match = provider.currentMatch!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Players'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              match.team1.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(
              widget.playersPerTeam,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _team1Controllers[i],
                  decoration: InputDecoration(
                    labelText: 'Player ${i + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              match.team2.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(
              widget.playersPerTeam,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _team2Controllers[i],
                  decoration: InputDecoration(
                    labelText: 'Player ${i + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  for (final c in _team1Controllers) {
                    if (c.text.isNotEmpty) {
                      provider.addPlayerToTeam(match.team1, c.text);
                    }
                  }
                  for (final c in _team2Controllers) {
                    if (c.text.isNotEmpty) {
                      provider.addPlayerToTeam(match.team2, c.text);
                    }
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TossScreen()),
                  );
                },
                child: const Text('To Toss →'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
