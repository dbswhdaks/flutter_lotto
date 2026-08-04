import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/pension_winning_detail.dart';

/// 동행복권 연금복권 720+ 회차별 당첨번호 조회 서비스
///
/// 구 `gameResult.do?method=win720` URL 은 2026년부터 `/errorPage` 로
/// 리다이렉트되어 사용 불가. 아래 신규 JSON API 를 사용한다.
///
/// 신 엔드포인트 (GET, JSON):
///   `https://www.dhlottery.co.kr/pt720/selectPstPt720Info.do?srchPsltEpsd={회차}`
///
/// 응답에는 요청 회차를 포함하여 최근 6회차의 데이터가 함께 실려온다.
class PensionWinningService {
  static const _api =
      'https://www.dhlottery.co.kr/pt720/selectPstPt720Info.do';
  static const _corsProxy = 'https://corsproxy.io/?';
  static const _referer = 'https://www.dhlottery.co.kr/pt720/result';

  /// 연금복권 720+ 1회차 추첨일: 2020-05-07(목).
  /// 매주 목요일 12:20(MBC) 생방송 추첨. 안전 마진으로 15:00 이후 반영으로 간주.
  static final DateTime _firstDrawDate = DateTime(2020, 5, 7);

  /// 오늘을 기준으로 가장 최근 "추첨 완료" 회차 추정
  static int calcLatestDrawnRound() {
    final now = DateTime.now();
    var diff = now.difference(_firstDrawDate).inDays;

    final thursday = _firstDrawDate.add(Duration(days: (diff ~/ 7) * 7));
    final drawAt = DateTime(
      thursday.year,
      thursday.month,
      thursday.day,
      15,
    );
    if (now.isBefore(drawAt)) {
      diff -= 7;
    }

    if (diff < 0) return 1;
    return (diff ~/ 7) + 1;
  }

  Uri _buildUri(int round) {
    final base = '$_api?srchPsltEpsd=$round';
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

  Future<PensionWinningDetail?> fetch(int round) async {
    if (round < 1) return null;

    try {
      final response = await http
          .get(_buildUri(round), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;

      final result = data['result'];
      if (result is! List) return null;

      // 응답에는 최근 6회차 데이터가 함께 오므로, 원하는 회차만 필터
      final rows = <Map<String, dynamic>>[];
      for (final item in result) {
        if (item is Map<String, dynamic> && _toInt(item['psltEpsd']) == round) {
          rows.add(item);
        }
      }
      if (rows.isEmpty) return null;

      final detail = PensionWinningDetail.fromApiRows(rows);
      return (detail != null && detail.isValid) ? detail : null;
    } catch (_) {
      return null;
    }
  }

  /// 추정 최신 회차부터 뒤로 [maxTry] 회까지 폴백 탐색
  Future<PensionWinningDetail?> fetchLatest({int maxTry = 5}) async {
    final estimated = calcLatestDrawnRound();
    for (int r = estimated; r >= estimated - maxTry && r >= 1; r--) {
      final detail = await fetch(r);
      if (detail != null) return detail;
    }
    return null;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
