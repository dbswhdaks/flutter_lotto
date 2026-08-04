import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/winning_number_detail.dart';

class WinningNumberService {
  /// 동행복권 내부 API - `common.do?method=getLottoNumber` 는 2026년부터
  /// error.html 로 리다이렉트되어 사용 불가. 아래 신 API 를 사용한다.
  static const _lottoApi =
      'https://www.dhlottery.co.kr/lt645/selectPstLt645Info.do';
  static const _corsProxy = 'https://corsproxy.io/?';
  static const _referer = 'https://www.dhlottery.co.kr/';

  static final DateTime _firstDrawDate = DateTime(2002, 12, 7);

  /// 날짜 기반으로 가장 최근 추첨 완료된 회차 계산
  /// 1회: 2002-12-07(토), 매주 토요일 20:35 추첨
  static int calcLatestDrawnRound() {
    final now = DateTime.now();
    var diff = now.difference(_firstDrawDate).inDays;

    final saturday = _firstDrawDate.add(Duration(days: (diff ~/ 7) * 7));
    final drawAt = DateTime(
      saturday.year,
      saturday.month,
      saturday.day,
      20,
      35,
    );
    if (now.isBefore(drawAt)) {
      diff -= 7;
    }

    if (diff < 0) return 1;
    return (diff ~/ 7) + 1;
  }

  Uri _buildUri(int round) {
    final base = '$_lottoApi?srchLtEpsd=$round';
    if (kIsWeb) {
      return Uri.parse('$_corsProxy${Uri.encodeComponent(base)}');
    }
    return Uri.parse(base);
  }

  static const Map<String, String> _headers = {
    'X-Requested-With': 'XMLHttpRequest',
    'Referer': _referer,
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
  };

  Future<WinningNumberDetail?> fetch(int round) async {
    if (round < 1) return null;

    try {
      final uri = _buildUri(round);
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;

      final list = data['list'];
      if (list is! List || list.isEmpty) return null;

      final item = list.first;
      if (item is! Map<String, dynamic>) return null;

      final detail = WinningNumberDetail.fromInternalApi(item);
      if (detail.round <= 0) return null;

      return detail;
    } catch (_) {
      return null;
    }
  }

  /// 추정 회차부터 뒤로 최대 [maxTry] 회차까지 탐색하여
  /// 실제로 API 응답이 오는 가장 최근 회차를 반환
  Future<WinningNumberDetail?> fetchLatest({int maxTry = 5}) async {
    final estimated = calcLatestDrawnRound();
    for (int r = estimated; r >= estimated - maxTry && r >= 1; r--) {
      final detail = await fetch(r);
      if (detail != null) return detail;
    }
    return null;
  }

  /// 동행복권 로또 QR 데이터 파서
  ///
  /// QR 값은 아래와 같은 URL 형태 (혹은 그 `v` 파라미터 문자열)로 전달됩니다.
  /// `http://m.dhlottery.co.kr/qr.do?method=winQr&v=1234q010203040506q...`
  ///
  /// `v` 는 [4자리 회차] + (게임구분자 + 6개의 2자리 번호) 반복 형태입니다.
  static LottoQrResult? parseQr(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    String payload = trimmed;
    try {
      final uri = Uri.parse(trimmed);
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) {
        payload = v;
      }
    } catch (_) {}

    if (payload.length < 4 + 12) return null;

    final roundStr = payload.substring(0, 4);
    final round = int.tryParse(roundStr);
    if (round == null) return null;

    final body = payload.substring(4);

    final games = <LottoQrGame>[];
    const labels = ['A', 'B', 'C', 'D', 'E'];
    int i = 0;
    while (i < body.length) {
      final ch = body[i];
      if (RegExp(r'[0-9]').hasMatch(ch)) {
        if (body.length - i < 12) break;
        final numsStr = body.substring(i, i + 12);
        final nums = _parseNumbers(numsStr);
        if (nums == null) break;
        games.add(
          LottoQrGame(
            label: games.length < labels.length ? labels[games.length] : '?',
            numbers: nums,
          ),
        );
        i += 12;
      } else {
        if (body.length - i - 1 < 12) break;
        final numsStr = body.substring(i + 1, i + 1 + 12);
        final nums = _parseNumbers(numsStr);
        if (nums == null) break;
        games.add(
          LottoQrGame(
            label: games.length < labels.length ? labels[games.length] : '?',
            numbers: nums,
          ),
        );
        i += 1 + 12;
      }
    }

    if (games.isEmpty) return null;

    return LottoQrResult(round: round, games: games);
  }

  static List<int>? _parseNumbers(String numsStr) {
    if (numsStr.length != 12) return null;
    final nums = <int>[];
    for (int j = 0; j < 6; j++) {
      final n = int.tryParse(numsStr.substring(j * 2, j * 2 + 2));
      if (n == null || n < 1 || n > 45) return null;
      nums.add(n);
    }
    nums.sort();
    return nums;
  }

  /// 사용자 번호와 당첨번호를 비교해 등수를 반환 (1~5등, 0 = 미당첨)
  static int calcRank({
    required List<int> userNumbers,
    required List<int> winningNumbers,
    required int bonus,
  }) {
    final winSet = winningNumbers.toSet();
    final matched = userNumbers.where(winSet.contains).length;
    final hasBonus = userNumbers.contains(bonus);

    if (matched == 6) return 1;
    if (matched == 5 && hasBonus) return 2;
    if (matched == 5) return 3;
    if (matched == 4) return 4;
    if (matched == 3) return 5;
    return 0;
  }
}
