import 'package:flutter/material.dart';
import '../../models/match_summary.dart';
import '../../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<MatchSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = HistoryService().getAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match History'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await HistoryService().clearAll();
              final future = HistoryService().getAll();
              setState(() {
                _future = future;
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<MatchSummary>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final matches = snap.data ?? [];
          if (matches.isEmpty) {
            return const Center(
              child: Text(
                'No matches yet',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (ctx, i) {
              final m = matches[i];
              final isWin1 = m.winnerName == m.team1Name;
              final isWin2 = m.winnerName == m.team2Name;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.team1Name,
                              style: TextStyle(
                                fontWeight: isWin1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isWin1
                                    ? const Color(0xFF1B5E20)
                                    : Colors.black,
                              ),
                            ),
                            Text(
                              m.team2Name,
                              style: TextStyle(
                                fontWeight: isWin2
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isWin2
                                    ? const Color(0xFF1B5E20)
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              m.team1Score,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              m.team2Score,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          m.winnerName != null
                              ? '🏆 ${m.winnerName} won'
                              : '🤝 Tied',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${m.playedAt.day}/${m.playedAt.month}/${m.playedAt.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
