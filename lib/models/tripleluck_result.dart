import 'dart:math';

class TripleluckResult {
  final int round;
  final List<int> tripleNumbers; // 트리플 3개
  final List<int> luckNumbers; // 럭 3개

  const TripleluckResult({
    required this.round,
    required this.tripleNumbers,
    required this.luckNumbers,
  });

  List<int> get allNumbers => [...tripleNumbers, ...luckNumbers];

  factory TripleluckResult.generate(int round) {
    final random = Random();
    final pool = List.generate(27, (i) => i + 1)..shuffle(random);
    final triple = pool.sublist(0, 3)..sort();
    final luck = pool.sublist(3, 6)..sort();
    return TripleluckResult(
      round: round,
      tripleNumbers: triple,
      luckNumbers: luck,
    );
  }
}
