import 'package:cric_track/screens/scoring/scorecard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';
import '../../models/match.dart';
import '../../models/player.dart';
import '../../models/match_summary.dart';
import '../../services/history_service.dart';

class ScoringScreen extends StatefulWidget {
  const ScoringScreen({super.key});

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen> {
  bool _inningsEndHandled = false;
  bool _battingAlone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupOpeners());
  }

  void _setupOpeners() async {
    final provider = context.read<MatchProvider>();
    final inn = provider.currentMatch!.currentInnings;
    if (inn == null) return;

    final striker = await _showPlayerPicker(
      'Select Striker (Opening Batsman)',
      inn.battingTeam.players,
    );
    if (striker == null) return;

    final nonStriker = await _showPlayerPicker(
      'Select Non-Striker',
      inn.battingTeam.players.where((p) => p != striker).toList(),
    );
    if (nonStriker == null) return;

    provider.setOpeningBatsmen(striker, nonStriker);
    await _askNextBowler();
  }

  Future<void> _askNextBowler() async {
    final provider = context.read<MatchProvider>();
    final inn = provider.currentMatch!.currentInnings;
    if (inn == null) return;

    Player? bowler;
    while (bowler == null) {
      bowler = await _showPlayerPicker(
        'Select Bowler',
        inn.bowlingTeam.players,
      );
      if (bowler == null && mounted) {
        // Dismissed without picking — bowler is mandatory, ask again.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must select a bowler to continue')),
        );
      }
    }
    provider.setCurrentBowler(bowler);
  }

  Future<void> _askNextBatsman() async {
    final provider = context.read<MatchProvider>();
    final match = provider.currentMatch!;
    final inn = match.currentInnings!;

    final retired = provider.retiredHurtPlayers;
    final remaining = inn.battingTeam.players
        .where(
          (p) =>
              !p.isOut &&
              !p.retiredHurt &&
              p != inn.striker &&
              p != inn.nonStriker,
        )
        .toList();

    if (retired.isEmpty && remaining.isEmpty) {
      if (match.lastManStands && inn.nonStriker != null) {
        provider.setLastManBatsAlone();
        return;
      }
      _checkInningsEnd();
      return;
    }

    final next = await showModalBottomSheet<Player>(
      context: context,
      backgroundColor: const Color(0xFF1e293b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          if (retired.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'RETIRED HURT',
                  style: TextStyle(
                    color: Colors.orange[300],
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            ...retired.map(
              (p) => ListTile(
                leading: Icon(
                  Icons.medical_services_outlined,
                  color: Colors.orange[300],
                ),
                title: Text(
                  '${p.name}  ${p.runs}(${p.ballsFaced})',
                  style: TextStyle(color: Colors.orange[300]),
                ),
                onTap: () => Navigator.pop(context, p),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
          ],
          if (remaining.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'YET TO BAT',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            ...remaining.map(
              (p) => ListTile(
                leading: const Icon(Icons.person, color: Colors.white70),
                title: Text(
                  p.name,
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () => Navigator.pop(context, p),
              ),
            ),
          ],
          if (inn.striker != null) ...[
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.white30),
              title: const Text(
                'Bat alone',
                style: TextStyle(color: Colors.white30),
              ),
              onTap: () => Navigator.pop(context, null),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );

    if (next != null) {
      if (next.retiredHurt) {
        provider.returnFromRetirement(next);
      } else {
        provider.setNextBatsman(next);
      }
      _battingAlone = false;
    }

    final updatedInn = provider.currentMatch!.currentInnings!;

    if (next == null && updatedInn.striker != null) {
      _battingAlone = true;
      return;
    }

    if (updatedInn.nonStriker == null && !provider.isInningsOver) {
      final moreRetired = provider.retiredHurtPlayers;
      final moreRemaining = updatedInn.battingTeam.players
          .where(
            (p) =>
                !p.isOut &&
                !p.retiredHurt &&
                p != updatedInn.striker &&
                p != updatedInn.nonStriker,
          )
          .toList();
      if (moreRetired.isNotEmpty || moreRemaining.isNotEmpty) {
        await _askNextBatsman();
      }
    }
  }

  void _onRetireHurt() {
    final provider = context.read<MatchProvider>();
    final inn = provider.currentMatch?.currentInnings;
    if (inn == null) return;

    final active = <Player>[
      if (inn.striker != null) inn.striker!,
      if (inn.nonStriker != null) inn.nonStriker!,
    ];

    if (active.isEmpty) return;

    if (active.length == 1 && provider.retiredHurtPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No replacement available to retire hurt'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e293b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'WHO IS RETIRING?',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          ...active.map(
            (p) => ListTile(
              leading: const Icon(
                Icons.medical_services_outlined,
                color: Colors.orange,
              ),
              title: Text(
                '${p.name}  ${p.runs}(${p.ballsFaced})'
                '${inn.striker?.id == p.id ? "  ★" : ""}',
                style: const TextStyle(color: Colors.orange),
              ),
              onTap: () {
                Navigator.pop(context);
                provider.retireHurt(p);
                _askNextBatsman();
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.close, color: Colors.white30),
            title: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white30),
            ),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<Player?> _showPlayerPicker(String title, List<Player> players) {
    final nameController = TextEditingController();
    return showDialog<Player>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text(title)),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(ctx, null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...players.map(
                  (p) => ListTile(
                    title: Text(p.name),
                    onTap: () => Navigator.pop(ctx, p),
                  ),
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'New player name...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        final provider = context.read<MatchProvider>();
                        final inn = provider.currentMatch!.currentInnings!;
                        final isBowler = title.contains('Bowler');
                        final team = isBowler
                            ? inn.bowlingTeam
                            : inn.battingTeam;
                        provider.addPlayerToTeam(team, name);
                        Navigator.pop(ctx, team.players.last);
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onBallTapped(BallEvent event) async {
    final provider = context.read<MatchProvider>();
    final match = provider.currentMatch!;
    final inn = match.currentInnings!;

    if (inn.striker == null) {
      await _askNextBatsman();
      return;
    }

    final overWasComplete = inn.currentOver?.isComplete ?? false;

    provider.addBall(event);

    if (match.state == MatchState.innings2) {
      final target = match.innings1!.totalRuns + 1;
      if (inn.totalRuns >= target) {
        _showMatchResultDialog();
        return;
      }
    }

    if (event.isWicket) await _askNextBatsman();

    if (!event.isWicket && !_battingAlone) {
      final currentInn = provider.currentMatch!.currentInnings!;
      if (currentInn.nonStriker == null && !provider.isInningsOver) {
        final retired = provider.retiredHurtPlayers;
        final remaining = currentInn.battingTeam.players
            .where((p) => !p.isOut && !p.retiredHurt && p != currentInn.striker)
            .toList();
        if (retired.isNotEmpty || remaining.isNotEmpty) {
          await _askNextBatsman();
        }
      }
    }

    final overNowComplete = inn.currentOver?.isComplete ?? false;
    if (!overWasComplete && overNowComplete) {
      if (provider.isInningsOver) {
        _checkInningsEnd();
        return;
      }
      await _askNextBowler();
    }

    _checkInningsEnd();
  }

  void _checkInningsEnd() {
    if (_inningsEndHandled) return;
    final provider = context.read<MatchProvider>();
    if (provider.isInningsOver) {
      _inningsEndHandled = true;
      if (provider.currentMatch!.state == MatchState.innings1) {
        _showInningsEndDialog();
      } else {
        _showMatchResultDialog();
      }
    }
  }

  void _showInningsEndDialog() {
    final provider = context.read<MatchProvider>();
    final inn = provider.currentMatch!.innings1!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Innings Over!'),
        content: Text(
          '${inn.battingTeam.name} scored ${inn.scoreDisplay}\n\nTarget: ${inn.totalRuns + 1}',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final inn1 = provider.currentMatch!.innings1!;
              provider.endInnings();
              provider.startInnings(inn1.bowlingTeam, inn1.battingTeam);
              _inningsEndHandled = false;
              _battingAlone = false;
              _setupOpeners();
            },
            child: const Text(
              'Start 2nd Innings',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showMatchResultDialog() {
    final provider = context.read<MatchProvider>();
    provider.endInnings();
    final match = provider.currentMatch!;
    final winner = match.winner;

    HistoryService().save(
      MatchSummary(
        id: match.id,
        team1Name: match.innings1!.battingTeam.name,
        team2Name: match.innings2!.battingTeam.name,
        team1Score: match.innings1!.scoreDisplay,
        team2Score: match.innings2!.scoreDisplay,
        winnerName: winner?.name,
        playedAt: DateTime.now(),
        innings1: match.innings1,
        innings2: match.innings2,
      ),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Match Over!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${match.innings1!.battingTeam.name}: ${match.innings1!.scoreDisplay}',
            ),
            Text(
              '${match.innings2!.battingTeam.name}: ${match.innings2!.scoreDisplay}',
            ),
            const SizedBox(height: 12),
            Text(
              winner != null ? '🏆 ${winner.name} wins!' : '🤝 Match Tied!',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
            ),
            onPressed: () => Navigator.popUntil(ctx, (r) => r.isFirst),
            child: const Text(
              'Back to Home',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirm = await _confirmAbandon();
        if (confirm && context.mounted) {
          context.read<MatchProvider>().abandonMatch();
          Navigator.popUntil(context, (r) => r.isFirst);
        }
      },
      child: Consumer<MatchProvider>(
        builder: (context, provider, _) {
          final match = provider.currentMatch;
          if (match == null) return const Scaffold(body: SizedBox());
          final inn = match.currentInnings;

          if (inn == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final over = inn.currentOver;
          final recentBalls = over?.balls ?? [];

          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              title: Text('${match.team1.name} vs ${match.team2.name}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: () async {
                    final confirm = await _confirmAbandon();
                    if (confirm && context.mounted) {
                      context.read<MatchProvider>().abandonMatch();
                      Navigator.popUntil(context, (r) => r.isFirst);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () async {
                    final provider = context.read<MatchProvider>();
                    final inn = provider.currentMatch!.currentInnings!;
                    final nameController = TextEditingController();
                    await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Add Late Player'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                hintText: 'Player name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              if (name.isEmpty) return;
                              provider.addPlayerToTeam(inn.battingTeam, name);
                              Navigator.pop(ctx);
                            },
                            child: Text('Add to ${inn.battingTeam.name}'),
                          ),
                          TextButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              if (name.isEmpty) return;
                              provider.addPlayerToTeam(inn.bowlingTeam, name);
                              Navigator.pop(ctx);
                            },
                            child: Text('Add to ${inn.bowlingTeam.name}'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.list_alt),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScorecardScreen(
                        innings: inn,
                        title: '${inn.battingTeam.name} Scorecard',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inn.battingTeam.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        inn.scoreDisplay,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'OVERS: ${inn.oversDisplay} • CRR: ${_calcCRR(inn)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (match.state == MatchState.innings2) ...[
                        const SizedBox(height: 6),
                        Builder(
                          builder: (_) {
                            final target = match.innings1!.totalRuns + 1;
                            final needed = target - inn.totalRuns;
                            final completedOvers = inn.overs
                                .where((o) => o.isComplete)
                                .length;
                            final ballsDone =
                                completedOvers * 6 +
                                (inn.currentOver?.legalBalls ?? 0);
                            final ballsLeft = match.totalOvers * 6 - ballsDone;
                            final rrr = ballsLeft > 0
                                ? (needed / (ballsLeft / 6)).toStringAsFixed(2)
                                : '∞';
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: needed <= 0
                                    ? Colors.green.shade100
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: needed <= 0
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Target: $target',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Need $needed off $ballsLeft balls',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    'RRR: $rrr',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: needed <= 0
                                          ? Colors.green
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'RECENT  ',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          ...recentBalls.map((b) => _ballChip(b)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BATTING',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            if (inn.striker != null)
                              GestureDetector(
                                onLongPress: () async {
                                  final all = inn.battingTeam.players
                                      .where(
                                        (p) =>
                                            !p.isOut &&
                                            !p.retiredHurt &&
                                            p != inn.nonStriker,
                                      )
                                      .toList();
                                  final picked = await _showPlayerPicker(
                                    'Change Striker',
                                    all,
                                  );
                                  if (picked != null && context.mounted) {
                                    context.read<MatchProvider>().changeStriker(
                                      picked,
                                    );
                                  }
                                },
                                child: Text(
                                  '● ${inn.striker!.name}  ${inn.striker!.runs}(${inn.striker!.ballsFaced})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (inn.nonStriker != null)
                              GestureDetector(
                                onLongPress: () async {
                                  final all = inn.battingTeam.players
                                      .where(
                                        (p) =>
                                            !p.isOut &&
                                            !p.retiredHurt &&
                                            p != inn.striker,
                                      )
                                      .toList();
                                  final picked = await _showPlayerPicker(
                                    'Change Non-Striker',
                                    all,
                                  );
                                  if (picked != null && context.mounted) {
                                    context
                                        .read<MatchProvider>()
                                        .changeNonStriker(picked);
                                  }
                                },
                                child: Text(
                                  '  ${inn.nonStriker!.name}  ${inn.nonStriker!.runs}(${inn.nonStriker!.ballsFaced})',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            if (inn.nonStriker == null && _battingAlone)
                              GestureDetector(
                                onTap: () async {
                                  final provider = context
                                      .read<MatchProvider>();
                                  final currentInn =
                                      provider.currentMatch!.currentInnings!;
                                  final retired = provider.retiredHurtPlayers;
                                  final remaining = currentInn
                                      .battingTeam
                                      .players
                                      .where(
                                        (p) =>
                                            !p.isOut &&
                                            !p.retiredHurt &&
                                            p != currentInn.striker,
                                      )
                                      .toList();
                                  if (retired.isEmpty && remaining.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('No players available'),
                                      ),
                                    );
                                    return;
                                  }
                                  _battingAlone = false;
                                  await _askNextBatsman();
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_add,
                                      size: 14,
                                      color: Colors.green.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+ Add Partner',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BOWLING',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            if (inn.currentBowler != null)
                              GestureDetector(
                                onLongPress: () async {
                                  if (!(inn.currentOver?.balls.isEmpty ??
                                      true)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Cannot change bowler after balls bowled',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final picked = await _showPlayerPicker(
                                    'Change Bowler',
                                    inn.bowlingTeam.players,
                                  );
                                  if (picked != null && context.mounted) {
                                    context.read<MatchProvider>().changeBowler(
                                      picked,
                                    );
                                  }
                                },
                                child: Text(
                                  inn.currentBowler!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (inn.currentBowler != null)
                              Text(
                                '${inn.currentBowler!.wicketsTaken}/${inn.currentBowler!.runsConceded}  (${inn.currentBowler!.oversBowled}.${inn.currentBowler!.ballsInCurrentOver})',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (inn.currentOver?.balls.isEmpty ?? true)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Text(
                      'Long-press batsman or bowler to change',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _extraBtn(
                            'WICKET',
                            Colors.red.shade100,
                            Colors.red,
                            () => _onBallTapped(BallEvent(isWicket: true)),
                          ),
                          const SizedBox(width: 8),
                          _extraBtn(
                            'RET. HURT',
                            Colors.orange.shade100,
                            Colors.orange.shade800,
                            _onRetireHurt,
                          ),
                          const SizedBox(width: 8),
                          _extraBtn(
                            'WIDE',
                            Colors.grey.shade200,
                            Colors.black,
                            () =>
                                _onBallTapped(BallEvent(isWide: true, runs: 1)),
                          ),
                          const SizedBox(width: 8),
                          _extraBtn(
                            'NO BALL',
                            Colors.grey.shade200,
                            Colors.black,
                            () => _onBallTapped(
                              BallEvent(isNoBall: true, runs: 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [0, 1, 2]
                            .map(
                              (r) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: _runBtn(r),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      Row(
                        children: [3, 4, 6]
                            .map(
                              (r) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: _runBtn(r),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              context.read<MatchProvider>().undoLastBall(),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.undo, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Undo',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              context.read<MatchProvider>().swapStrike(),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.swap_horiz,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Swap Strike',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _ballChip(BallEvent b) {
    Color bg = Colors.grey.shade300;
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
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Text(b.display, style: TextStyle(color: fg, fontSize: 11)),
      ),
    );
  }

  Widget _runBtn(int runs) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.black;
    if (runs == 1 || runs == 2) bg = const Color(0xFFB9F6CA);
    if (runs == 3) bg = const Color(0xFF69F0AE);
    if (runs == 4) {
      bg = const Color(0xFF1B5E20);
      fg = Colors.white;
    }
    if (runs == 6) {
      bg = Colors.blue;
      fg = Colors.white;
    }
    return GestureDetector(
      onTap: () => _onBallTapped(BallEvent(runs: runs)),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '$runs',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _extraBtn(String label, Color bg, Color fg, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: fg, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  String _calcCRR(Innings inn) {
    final overs =
        inn.overs.where((o) => o.isComplete).length +
        (inn.currentOver?.legalBalls ?? 0) / 6;
    if (overs == 0) return '0.00';
    return (inn.totalRuns / overs).toStringAsFixed(2);
  }

  Future<bool> _confirmAbandon() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandon Match?'),
        content: const Text(
          'Are you sure you want to exit? The match will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }
}
