import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_summary.dart';

class HistoryService {
  static const _key = 'match_history';

  Future<List<MatchSummary>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => MatchSummary.fromJson(jsonDecode(s)))
        .toList()
        .reversed
        .toList();
  }

  Future<void> save(MatchSummary summary) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(summary.toJson()));
    await prefs.setStringList(_key, raw);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
