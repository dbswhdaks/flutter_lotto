import 'dart:math';

class LottoResult {
  final int round;
  final List<int> mainNumbers;
  final int bonusNumber;

  const LottoResult({
    required this.round,
    required this.mainNumbers,
    required this.bonusNumber,
  });

  factory LottoResult.generate(int round) {
    final random = Random();
    final numbers = <int>{};
    while (numbers.length < 7) {
      numbers.add(random.nextInt(45) + 1);
    }
    final list = numbers.toList();
    final main = list.sublist(0, 6)..sort();
    return LottoResult(round: round, mainNumbers: main, bonusNumber: list[6]);
  }
}
