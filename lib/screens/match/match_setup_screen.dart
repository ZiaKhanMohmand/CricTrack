import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';
import 'player_entry_screen.dart';

class MatchSetupScreen extends StatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  State<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends State<MatchSetupScreen> {
  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();
  final _customOversController = TextEditingController();
  bool _isCustomOvers = false;
  int _overs = 5;
  int _playersPerTeam = 6;
  bool _lastManStands = false;

  @override
  void dispose() {
    _team1Controller.dispose();
    _team2Controller.dispose();
    _customOversController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Setup'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _team1Controller,
              decoration: const InputDecoration(
                labelText: 'Team 1 Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _team2Controller,
              decoration: const InputDecoration(
                labelText: 'Team 2 Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Overs selector
            Row(
              children: [
                const Text('Overs: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _isCustomOvers ? -1 : _overs,
                  items: [
                    ...[
                      1,
                      2,
                      3,
                      4,
                      5,
                      10,
                      15,
                      20,
                    ].map((o) => DropdownMenuItem(value: o, child: Text('$o'))),
                    const DropdownMenuItem(value: -1, child: Text('Custom')),
                  ],
                  onChanged: (v) => setState(() {
                    if (v == -1) {
                      _isCustomOvers = true;
                    } else {
                      _isCustomOvers = false;
                      _overs = v!;
                    }
                  }),
                ),
                if (_isCustomOvers) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _customOversController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Overs',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Players per team selector
            Row(
              children: [
                const Text(
                  'Players per team: ',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _playersPerTeam,
                  items: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
                      .map((p) => DropdownMenuItem(value: p, child: Text('$p')))
                      .toList(),
                  onChanged: (v) => setState(() => _playersPerTeam = v!),
                ),
              ],
            ),

            Row(
              children: [
                const Text('Last Man Stands: ', style: TextStyle(fontSize: 16)),
                Switch(
                  value: _lastManStands,
                  activeThumbColor: const Color(0xFF1B5E20),
                  onChanged: (v) => setState(() => _lastManStands = v),
                ),
                Text(
                  _lastManStands ? 'ON (village rules)' : 'OFF',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  if (_team1Controller.text.isEmpty ||
                      _team2Controller.text.isEmpty) {
                    return;
                  }

                  final int? finalOvers = _isCustomOvers
                      ? int.tryParse(_customOversController.text)
                      : _overs;

                  if (finalOvers == null || finalOvers <= 0) return;

                  context.read<MatchProvider>().createMatch(
                    _team1Controller.text,
                    _team2Controller.text,
                    finalOvers,
                    lastManStands: _lastManStands,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PlayerEntryScreen(playersPerTeam: _playersPerTeam),
                    ),
                  );
                },

                child: const Text('Next → Add Players'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
