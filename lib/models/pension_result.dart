import 'dart:math';

class PensionResult {
  final int round;
  final int group;
  final List<int> digits;

  const PensionResult({
    required this.round,
    required this.group,
    required this.digits,
  });

  factory PensionResult.generate(int round) {
    final random = Random();
    final group = random.nextInt(5) + 1;
    final digits = List.generate(6, (_) => random.nextInt(10));
    return PensionResult(round: round, group: group, digits: digits);
  }

  String get formattedNumber => digits.join();

  String get fullDisplay => '$group조 $formattedNumber';
}
