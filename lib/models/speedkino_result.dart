import 'dart:math';

class SpeedkinoResult {
  final int round;
  final List<int> numbers;

  const SpeedkinoResult({
    required this.round,
    required this.numbers,
  });

  factory SpeedkinoResult.generate(int round) {
    final random = Random();
    final nums = <int>{};
    while (nums.length < 10) {
      nums.add(random.nextInt(70) + 1);
    }
    return SpeedkinoResult(
      round: round,
      numbers: nums.toList()..sort(),
    );
  }
}
