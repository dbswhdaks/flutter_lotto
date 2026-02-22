import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/doublejack_draw.dart';

class DoublejackDataService {
  static const _api = 'https://www.dhlottery.co.kr/common.do';
  static const _corsProxy = 'https://corsproxy.io/?';
  static const _cacheKey = 'doublejack_draws_cache';
  static const _lastRoundKey = 'doublejack_last_round';

  final List<DoublejackDraw> _draws = [];
  bool _loaded = false;

  List<DoublejackDraw> get draws => List.unmodifiable(_draws);
  bool get isLoaded => _loaded;

  Future<void> loadData({int fetchCount = 300}) async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final list = jsonDecode(cached) as List;
        _draws.addAll(
          list.map((e) => DoublejackDraw.fromJson(e as Map<String, dynamic>)),
        );
      } catch (_) {}
    }

    await _fetchLatestDraws(fetchCount, prefs);

    if (_draws.isEmpty) {
      _draws.addAll(_fallbackDraws);
    }

    _loaded = true;
  }

  String _buildUrl(int round) {
    final base = '$_api?method=getDoubleJackNumber&drwNo=$round';
    return kIsWeb ? '$_corsProxy${Uri.encodeComponent(base)}' : base;
  }

  Future<void> _fetchLatestDraws(int count, SharedPreferences prefs) async {
    try {
      final latestRound = await _getLatestRound();
      if (latestRound == null) return;

      final cachedLast = prefs.getInt(_lastRoundKey) ?? 0;
      if (cachedLast >= latestRound && _draws.isNotEmpty) return;

      final startRound = (latestRound - count + 1).clamp(1, latestRound);
      final existingRounds = _draws.map((d) => d.round).toSet();
      final newDraws = <DoublejackDraw>[];

      for (int r = startRound; r <= latestRound; r++) {
        if (existingRounds.contains(r)) continue;
        final draw = await _fetchDraw(r);
        if (draw != null) newDraws.add(draw);
        if (newDraws.length % 5 == 0) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      if (newDraws.isNotEmpty) {
        _draws.addAll(newDraws);
        _draws.sort((a, b) => b.round.compareTo(a.round));
        await _saveCache(prefs, latestRound);
      }
    } catch (_) {}
  }

  Future<void> _saveCache(SharedPreferences prefs, int latestRound) async {
    final jsonList = _draws.map((d) => d.toJson()).toList();
    await prefs.setString(_cacheKey, jsonEncode(jsonList));
    await prefs.setInt(_lastRoundKey, latestRound);
  }

  Future<int?> _getLatestRound() async {
    for (int tryCount = 0; tryCount < 5; tryCount++) {
      try {
        final testRound = 500 - tryCount * 50;
        final draw = await _fetchDraw(testRound);
        if (draw != null) return testRound;
      } catch (_) {}
    }
    return null;
  }

  Future<DoublejackDraw?> _fetchDraw(int round) async {
    try {
      final uri = Uri.parse(_buildUrl(round));
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['returnValue'] == 'success') {
          return DoublejackDraw.fromJson(json);
        }
      }
    } catch (_) {}
    return null;
  }

  static List<DoublejackDraw> get _fallbackDraws {
    final rng = Random(451245);
    return List.generate(300, (i) {
      final round = 300 - i;
      final pool1 = List.generate(45, (j) => j + 1)..shuffle(rng);
      final pool2 = List.generate(45, (j) => j + 1)..shuffle(rng);
      return DoublejackDraw(
        round: round,
        jackNumbers: pool1.sublist(0, 6)..sort(),
        midasNumbers: pool2.sublist(0, 6)..sort(),
      );
    });
  }
}
