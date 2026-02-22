import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pension_draw.dart';

class PensionDataService {
  static const _api = 'https://www.dhlottery.co.kr/common.do';
  static const _corsProxy = 'https://corsproxy.io/?';
  static const _cacheKey = 'pension_draws_cache';
  static const _lastRoundKey = 'pension_last_round';

  final List<PensionDraw> _draws = [];
  bool _loaded = false;

  List<PensionDraw> get draws => List.unmodifiable(_draws);
  bool get isLoaded => _loaded;

  Future<void> loadData({int fetchCount = 300}) async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final list = jsonDecode(cached) as List;
        _draws.addAll(
          list.map((e) => PensionDraw.fromJson(e as Map<String, dynamic>)),
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
    final base = '$_api?method=get720Number&drwNo=$round';
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
      final newDraws = <PensionDraw>[];

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
    // 연금복권 720+: 2020-05-07 1회, 매주 목요일
    final now = DateTime.now();
    final base = DateTime(2020, 5, 7);
    final estimated = (now.difference(base).inDays / 7).floor();

    for (int r = estimated + 2; r >= estimated - 5; r--) {
      if (r < 1) continue;
      final draw = await _fetchDraw(r);
      if (draw != null) return r;
    }
    return null;
  }

  Future<PensionDraw?> _fetchDraw(int round) async {
    try {
      final uri = Uri.parse(_buildUrl(round));
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['returnValue'] == 'success') {
          return PensionDraw.fromJson(json);
        }
      }
    } catch (_) {}
    return null;
  }

  /// 네트워크 실패 시 300회분 fallback 데이터 생성.
  /// 고정 시드를 사용하여 매번 동일한 데이터를 생성한다.
  static List<PensionDraw> get _fallbackDraws {
    final rng = Random(720300);
    return List.generate(300, (i) {
      final round = 300 - i;
      return PensionDraw(
        round: round,
        group: rng.nextInt(5) + 1,
        digits: List.generate(6, (_) => rng.nextInt(10)),
      );
    });
  }
}
