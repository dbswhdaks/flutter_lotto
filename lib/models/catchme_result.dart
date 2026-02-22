import 'dart:math';

class CatchmeResult {
  final int round;
  final int myNumber; // 내가 선택한 번호
  final int drawnNumber; // 추첨된 번호

  const CatchmeResult({
    required this.round,
    required this.myNumber,
    required this.drawnNumber,
  });

  bool get isMatch => myNumber == drawnNumber;

  factory CatchmeResult.generate(int round, int myNumber) {
    final random = Random();
    return CatchmeResult(
      round: round,
      myNumber: myNumber,
      drawnNumber: random.nextInt(45) + 1,
    );
  }
}
