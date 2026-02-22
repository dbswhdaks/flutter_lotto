import 'dart:math';

class TreasureResult {
  final int round;
  final List<int> numbers; // 일반 번호 6개 (1~35)
  final int treasureNumber; // 보물번호 1개 (1~10)

  const TreasureResult({
    required this.round,
    required this.numbers,
    required this.treasureNumber,
  });

  factory TreasureResult.generate(int round) {
    final random = Random();
    final pool = List.generate(35, (i) => i + 1)..shuffle(random);
    final nums = pool.sublist(0, 6)..sort();
    final treasure = random.nextInt(10) + 1;
    return TreasureResult(
      round: round,
      numbers: nums,
      treasureNumber: treasure,
    );
  }
}
