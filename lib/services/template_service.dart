import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/team_template.dart';

class TemplateService {
  static const _key = 'team_templates';

  Future<List<TeamTemplate>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) => TeamTemplate.fromJson(jsonDecode(s))).toList();
  }

  Future<void> save(String name, List<String> playerNames) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final template = TeamTemplate(
      id: const Uuid().v4(),
      name: name,
      playerNames: playerNames,
    );
    raw.add(jsonEncode(template.toJson()));
    await prefs.setStringList(_key, raw);
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) => (jsonDecode(s) as Map<String, dynamic>)['id'] == id);
    await prefs.setStringList(_key, raw);
  }
}
