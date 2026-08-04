/// 연금복권 720+ 회차별 당첨 정보
class PensionRankInfo {
  final int amount;
  final int winnerCount;

  const PensionRankInfo({required this.amount, required this.winnerCount});
}

class PensionWinningDetail {
  /// 회차
  final int round;

  /// 추첨일 (예: "2026-07-30")
  final String? date;

  /// 1등 조 번호 (1 ~ 5)
  final int group;

  /// 1등 당첨번호 6자리 (좌 → 우, 각 자리 0 ~ 9)
  final List<int> numbers;

  /// 보너스 당첨번호 6자리 (좌 → 우)
  final List<int> bonusNumbers;

  /// 1~7등 + 보너스 상세 (당첨금·당첨자수)
  final PensionRankInfo first;
  final PensionRankInfo second;
  final PensionRankInfo third;
  final PensionRankInfo fourth;
  final PensionRankInfo fifth;
  final PensionRankInfo sixth;
  final PensionRankInfo seventh;
  final PensionRankInfo bonus;

  const PensionWinningDetail({
    required this.round,
    required this.date,
    required this.group,
    required this.numbers,
    required this.bonusNumbers,
    required this.first,
    required this.second,
    required this.third,
    required this.fourth,
    required this.fifth,
    required this.sixth,
    required this.seventh,
    required this.bonus,
  });

  bool get isValid {
    if (group < 1 || group > 5) return false;
    if (numbers.length != 6 || bonusNumbers.length != 6) return false;
    if (numbers.any((n) => n < 0 || n > 9)) return false;
    if (bonusNumbers.any((n) => n < 0 || n > 9)) return false;
    return true;
  }

  /// 신규 JSON API `/pt720/selectPstPt720Info.do` 응답의 `data.result`
  /// (특정 회차의 8개 레코드 리스트)에서 파싱한다.
  ///
  /// [rows] 는 동일 `psltEpsd` 값을 갖는 레코드 8개.
  ///   - wnSqNo=1  → 1등 (wnBndNo=조, wnRnkVl=6자리)
  ///   - wnSqNo=2  → 2등
  ///   - wnSqNo=3~7→ 3~7등
  ///   - wnSqNo=21 → 보너스 (wnRnkVl=6자리)
  static PensionWinningDetail? fromApiRows(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return null;

    Map<String, dynamic>? bySq(int sqNo) {
      for (final r in rows) {
        if (_toInt(r['wnSqNo']) == sqNo) return r;
      }
      return null;
    }

    final r1 = bySq(1);
    final r21 = bySq(21);
    if (r1 == null || r21 == null) return null;

    final round = _toInt(r1['psltEpsd']);
    if (round <= 0) return null;

    final group = int.tryParse('${r1['wnBndNo'] ?? ''}') ?? 0;
    final numbers = _digitsFromString('${r1['wnRnkVl'] ?? ''}', 6);
    final bonusNumbers = _digitsFromString('${r21['wnRnkVl'] ?? ''}', 6);
    if (numbers == null || bonusNumbers == null) return null;

    PensionRankInfo info(int sq) {
      final r = bySq(sq);
      return PensionRankInfo(
        amount: _toInt(r?['wnAmt']),
        winnerCount: _toInt(r?['wnTotalCnt']),
      );
    }

    return PensionWinningDetail(
      round: round,
      date: _formatYmd('${r1['psltRflYmd'] ?? ''}'),
      group: group,
      numbers: numbers,
      bonusNumbers: bonusNumbers,
      first: info(1),
      second: info(2),
      third: info(3),
      fourth: info(4),
      fifth: info(5),
      sixth: info(6),
      seventh: info(7),
      bonus: info(21),
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// "502733" → [5,0,2,7,3,3]. 길이 부족 시 앞을 0 으로 패딩.
  static List<int>? _digitsFromString(String s, int length) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) return null;
    final padded = trimmed.padLeft(length, '0');
    if (padded.length < length) return null;
    final source = padded.substring(padded.length - length);
    final out = <int>[];
    for (int i = 0; i < length; i++) {
      final n = int.tryParse(source[i]);
      if (n == null) return null;
      out.add(n);
    }
    return out;
  }

  /// "20260730" → "2026-07-30"
  static String? _formatYmd(String ymd) {
    if (ymd.length != 8) return null;
    return '${ymd.substring(0, 4)}-${ymd.substring(4, 6)}-${ymd.substring(6, 8)}';
  }
}
