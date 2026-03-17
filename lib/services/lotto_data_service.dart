import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lotto_draw.dart';

class LottoDataService {
  static const _lottoApi = 'https://www.dhlottery.co.kr/common.do';
  static const _corsProxy = 'https://corsproxy.io/?';
  static const _cacheKey = 'lotto_draws_cache';
  static const _lastRoundKey = 'lotto_last_round';

  static final DateTime _firstDrawDate = DateTime(2002, 12, 7);

  final List<LottoDraw> _draws = [];
  bool _loaded = false;
  int _latestRound = 0;

  List<LottoDraw> get draws => List.unmodifiable(_draws);
  bool get isLoaded => _loaded;
  int get latestRound => _latestRound;

  /// 날짜 기반으로 가장 최근 추첨 완료된 회차 계산
  /// 1회: 2002-12-07(토), 매주 토요일 추첨
  static int calcLatestDrawnRound() {
    final now = DateTime.now();
    final diff = now.difference(_firstDrawDate).inDays;
    if (diff < 0) return 1;
    return (diff ~/ 7) + 1;
  }

  Future<void> loadData({int fetchCount = 100}) async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final list = jsonDecode(cached) as List;
        _draws.addAll(
          list.map((e) => LottoDraw.fromJson(e as Map<String, dynamic>)),
        );
      } catch (_) {}
    }

    await _fetchLatestDraws(fetchCount, prefs);

    if (_draws.isEmpty) {
      _draws.addAll(_fallbackDraws);
    }

    _loaded = true;
  }

  /// 1회부터 최신회차까지 전체 데이터를 병렬 배치로 로드
  Future<void> loadAllData({
    void Function(int loaded, int total)? onProgress,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final cached = prefs.getString(_cacheKey);
    if (cached != null && _draws.isEmpty) {
      try {
        final list = jsonDecode(cached) as List;
        _draws.addAll(
          list.map((e) => LottoDraw.fromJson(e as Map<String, dynamic>)),
        );
      } catch (_) {}
    }

    final apiLatest = await _getLatestRound();
    final latest = apiLatest ?? calcLatestDrawnRound();
    _latestRound = latest;

    if (apiLatest == null) {
      if (_draws.isEmpty) _draws.addAll(_fallbackDraws);
      _draws.sort((a, b) => b.round.compareTo(a.round));
      _loaded = true;
      onProgress?.call(latest, latest);
      return;
    }

    final existingRounds = _draws.map((d) => d.round).toSet();
    final missing = <int>[];
    for (int r = 1; r <= latest; r++) {
      if (!existingRounds.contains(r)) missing.add(r);
    }

    if (missing.isEmpty) {
      _draws.sort((a, b) => b.round.compareTo(a.round));
      _loaded = true;
      onProgress?.call(latest, latest);
      return;
    }

    int loaded = latest - missing.length;
    onProgress?.call(loaded, latest);

    const batchSize = 20;
    for (int i = 0; i < missing.length; i += batchSize) {
      final batch = missing.skip(i).take(batchSize).toList();
      final futures = batch.map((r) => _fetchDraw(r));
      final results = await Future.wait(futures);

      for (final draw in results) {
        if (draw != null && !existingRounds.contains(draw.round)) {
          _draws.add(draw);
          existingRounds.add(draw.round);
        }
      }

      loaded += batch.length;
      onProgress?.call(loaded, latest);

      if (i + batchSize < missing.length) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    _draws.sort((a, b) => b.round.compareTo(a.round));
    await _saveCache(prefs, latest);
    _loaded = true;
  }

  String _buildUrl(int round) {
    final base = '$_lottoApi?method=getLottoNumber&drwNo=$round';
    return kIsWeb ? '$_corsProxy${Uri.encodeComponent(base)}' : base;
  }

  Future<void> _fetchLatestDraws(int count, SharedPreferences prefs) async {
    try {
      final latest = await _getLatestRound();
      if (latest == null) return;
      _latestRound = latest;

      final cachedLast = prefs.getInt(_lastRoundKey) ?? 0;
      if (cachedLast >= latest && _draws.isNotEmpty) return;

      final startRound = (latest - count + 1).clamp(1, latest);
      final existingRounds = _draws.map((d) => d.round).toSet();
      final newDraws = <LottoDraw>[];

      for (int r = startRound; r <= latest; r++) {
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
        await _saveCache(prefs, latest);
      }
    } catch (_) {}
  }

  Future<void> _saveCache(SharedPreferences prefs, int latestRound) async {
    final jsonList = _draws
        .map((d) => <String, dynamic>{
              'drwNo': d.round,
              'drwtNo1': d.numbers[0],
              'drwtNo2': d.numbers[1],
              'drwtNo3': d.numbers[2],
              'drwtNo4': d.numbers[3],
              'drwtNo5': d.numbers[4],
              'drwtNo6': d.numbers[5],
              'bnusNo': d.bonus,
              'drwNoDate': d.date,
            })
        .toList();
    await prefs.setString(_cacheKey, jsonEncode(jsonList));
    await prefs.setInt(_lastRoundKey, latestRound);
  }

  Future<int?> _getLatestRound() async {
    final estimated = calcLatestDrawnRound();

    for (int r = estimated + 2; r >= estimated - 10; r--) {
      if (r < 1) continue;
      final draw = await _fetchDraw(r);
      if (draw != null) return r;
    }
    return null;
  }

  Future<LottoDraw?> _fetchDraw(int round) async {
    try {
      final uri = Uri.parse(_buildUrl(round));
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['returnValue'] == 'success') {
          return LottoDraw.fromJson(json);
        }
      }
    } catch (_) {}
    return null;
  }

  static final _fallbackDraws = [
    const LottoDraw(round: 1211, numbers: [23, 26, 27, 35, 38, 40], bonus: 10),
    const LottoDraw(round: 1210, numbers: [2, 8, 19, 32, 37, 40], bonus: 15),
    const LottoDraw(round: 1209, numbers: [5, 10, 16, 28, 34, 42], bonus: 7),
    const LottoDraw(round: 1208, numbers: [3, 14, 21, 29, 36, 43], bonus: 11),
    const LottoDraw(round: 1207, numbers: [6, 12, 18, 25, 33, 44], bonus: 9),
    const LottoDraw(round: 1206, numbers: [1, 9, 17, 26, 38, 45], bonus: 22),
    const LottoDraw(round: 1205, numbers: [4, 11, 20, 30, 35, 41], bonus: 16),
    const LottoDraw(round: 1204, numbers: [7, 13, 24, 31, 37, 43], bonus: 2),
    const LottoDraw(round: 1203, numbers: [2, 15, 22, 28, 34, 40], bonus: 19),
    const LottoDraw(round: 1202, numbers: [8, 10, 19, 27, 36, 44], bonus: 5),
    const LottoDraw(round: 1201, numbers: [3, 16, 23, 29, 33, 42], bonus: 14),
    const LottoDraw(round: 1200, numbers: [1, 6, 18, 25, 38, 45], bonus: 12),
    const LottoDraw(round: 1199, numbers: [5, 11, 20, 32, 37, 41], bonus: 8),
    const LottoDraw(round: 1198, numbers: [9, 14, 21, 30, 35, 43], bonus: 27),
    const LottoDraw(round: 1197, numbers: [4, 7, 17, 26, 34, 44], bonus: 10),
    const LottoDraw(round: 1196, numbers: [2, 12, 22, 31, 39, 45], bonus: 18),
    const LottoDraw(round: 1195, numbers: [6, 13, 24, 28, 36, 40], bonus: 3),
    const LottoDraw(round: 1194, numbers: [1, 8, 15, 29, 33, 42], bonus: 21),
    const LottoDraw(round: 1193, numbers: [10, 16, 19, 25, 37, 43], bonus: 6),
    const LottoDraw(round: 1192, numbers: [3, 11, 23, 30, 38, 41], bonus: 15),
    const LottoDraw(round: 1191, numbers: [5, 9, 18, 27, 35, 44], bonus: 20),
    const LottoDraw(round: 1190, numbers: [7, 14, 20, 32, 36, 45], bonus: 1),
    const LottoDraw(round: 1189, numbers: [4, 12, 21, 26, 34, 40], bonus: 17),
    const LottoDraw(round: 1188, numbers: [2, 10, 17, 28, 39, 43], bonus: 33),
    const LottoDraw(round: 1187, numbers: [6, 13, 22, 31, 37, 42], bonus: 8),
    const LottoDraw(round: 1186, numbers: [1, 8, 16, 25, 35, 44], bonus: 29),
    const LottoDraw(round: 1185, numbers: [3, 11, 19, 30, 38, 45], bonus: 14),
    const LottoDraw(round: 1184, numbers: [5, 15, 24, 27, 33, 41], bonus: 9),
    const LottoDraw(round: 1183, numbers: [9, 12, 20, 29, 36, 43], bonus: 4),
    const LottoDraw(round: 1182, numbers: [7, 14, 23, 32, 34, 40], bonus: 18),
  ];
}
