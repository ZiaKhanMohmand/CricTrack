import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/match_provider.dart';
import '../../models/team_template.dart';
import '../../services/template_service.dart';
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
  final _templateService = TemplateService();
  List<TeamTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.playersPerTeam; i++) {
      _team1Controllers.add(TextEditingController());
      _team2Controllers.add(TextEditingController());
    }
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await _templateService.getAll();
    setState(() => _templates = templates);
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

  // Fill given controllers from a template. Pads/truncates to playersPerTeam.
  void _applyTemplate(
    TeamTemplate template,
    List<TextEditingController> controllers,
  ) {
    for (int i = 0; i < controllers.length; i++) {
      controllers[i].text = i < template.playerNames.length
          ? template.playerNames[i]
          : '';
    }
  }

  Future<void> _pickTemplate(List<TextEditingController> controllers) async {
    if (_templates.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No saved templates yet')));
      return;
    }
    final picked = await showModalBottomSheet<TeamTemplate>(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: _templates.map((t) {
          return ListTile(
            title: Text(t.name),
            subtitle: Text(t.playerNames.join(', ')),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await _templateService.delete(t.id);
                Navigator.pop(ctx);
                _loadTemplates();
              },
            ),
            onTap: () => Navigator.pop(ctx, t),
          );
        }).toList(),
      ),
    );
    if (picked != null) _applyTemplate(picked, controllers);
  }

  Future<void> _saveAsTemplate(
    String defaultName,
    List<TextEditingController> controllers,
  ) async {
    final names = controllers
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter player names first')));
      return;
    }
    final nameController = TextEditingController(text: defaultName);
    final confirmedName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Template'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Template name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmedName != null && confirmedName.isNotEmpty) {
      await _templateService.save(confirmedName, names);
      await _loadTemplates();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved "$confirmedName"')));
      }
    }
  }

  Widget _templateButtons(
    String teamName,
    List<TextEditingController> controllers,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Load Template'),
            onPressed: () => _pickTemplate(controllers),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Template'),
            onPressed: () => _saveAsTemplate(teamName, controllers),
          ),
        ),
      ],
    );
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
            _templateButtons(match.team1.name, _team1Controllers),
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
            _templateButtons(match.team2.name, _team2Controllers),
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
