import 'dart:math';

class PowerballResult {
  final int round;
  final List<int> numbers;
  final int powerball;

  const PowerballResult({
    required this.round,
    required this.numbers,
    required this.powerball,
  });

  factory PowerballResult.generate(int round) {
    final random = Random();
    final nums = <int>{};
    while (nums.length < 5) {
      nums.add(random.nextInt(28) + 1);
    }
    final sorted = nums.toList()..sort();
    return PowerballResult(
      round: round,
      numbers: sorted,
      powerball: random.nextInt(10),
    );
  }

  String get display =>
      '${numbers.join(", ")}  + P $powerball';
}
