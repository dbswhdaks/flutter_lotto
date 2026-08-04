class WinningNumberDetail {
  final int round;
  final String? date;
  final List<int> numbers;
  final int bonus;

  // 1등
  final int firstWinAmount; // 1인당
  final int firstWinnerCount;
  final int firstTotalAmount;

  // 2등
  final int secondWinAmount;
  final int secondWinnerCount;

  // 3등
  final int thirdWinAmount;
  final int thirdWinnerCount;

  // 4등
  final int fourthWinAmount;
  final int fourthWinnerCount;

  // 5등
  final int fifthWinAmount;
  final int fifthWinnerCount;

  final int totalSellAmount;

  const WinningNumberDetail({
    required this.round,
    required this.date,
    required this.numbers,
    required this.bonus,
    required this.firstWinAmount,
    required this.firstWinnerCount,
    required this.firstTotalAmount,
    required this.secondWinAmount,
    required this.secondWinnerCount,
    required this.thirdWinAmount,
    required this.thirdWinnerCount,
    required this.fourthWinAmount,
    required this.fourthWinnerCount,
    required this.fifthWinAmount,
    required this.fifthWinnerCount,
    required this.totalSellAmount,
  });

  /// 새 내부 API (`selectPstLt645Info.do`) 응답에서 파싱
  factory WinningNumberDetail.fromInternalApi(Map<String, dynamic> item) {
    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    String? formatDate(dynamic v) {
      if (v is String && v.length == 8) {
        return '${v.substring(0, 4)}-${v.substring(4, 6)}-${v.substring(6, 8)}';
      }
      return v?.toString();
    }

    return WinningNumberDetail(
      round: toInt(item['ltEpsd']),
      date: formatDate(item['ltRflYmd']),
      numbers: [
        toInt(item['tm1WnNo']),
        toInt(item['tm2WnNo']),
        toInt(item['tm3WnNo']),
        toInt(item['tm4WnNo']),
        toInt(item['tm5WnNo']),
        toInt(item['tm6WnNo']),
      ]..sort(),
      bonus: toInt(item['bnsWnNo']),
      firstWinAmount: toInt(item['rnk1WnAmt']),
      firstWinnerCount: toInt(item['rnk1WnNope']),
      firstTotalAmount: toInt(item['rnk1SumWnAmt']),
      secondWinAmount: toInt(item['rnk2WnAmt']),
      secondWinnerCount: toInt(item['rnk2WnNope']),
      thirdWinAmount: toInt(item['rnk3WnAmt']),
      thirdWinnerCount: toInt(item['rnk3WnNope']),
      fourthWinAmount: toInt(item['rnk4WnAmt']),
      fourthWinnerCount: toInt(item['rnk4WnNope']),
      fifthWinAmount: toInt(item['rnk5WnAmt']),
      fifthWinnerCount: toInt(item['rnk5WnNope']),
      totalSellAmount: toInt(item['rlvtEpsdSumNtslAmt']),
    );
  }
}

/// QR 코드에서 파싱된 사용자가 구매한 로또 게임 1건
class LottoQrGame {
  final String label; // A / B / C / D / E
  final List<int> numbers;

  const LottoQrGame({required this.label, required this.numbers});
}

/// QR 코드에서 파싱된 결과
class LottoQrResult {
  final int round;
  final List<LottoQrGame> games;

  const LottoQrResult({required this.round, required this.games});
}
