import 'dart:math';

class DoublejackResult {
  final int round;
  final List<int> jackNumbers; // 잭 6개 (1~45)
  final List<int> midasNumbers; // 마이더스 6개 (1~45)

  const DoublejackResult({
    required this.round,
    required this.jackNumbers,
    required this.midasNumbers,
  });

  List<int> get allNumbers => [...jackNumbers, ...midasNumbers];

  factory DoublejackResult.generate(int round) {
    final random = Random();
    final pool1 = List.generate(45, (i) => i + 1)..shuffle(random);
    final pool2 = List.generate(45, (i) => i + 1)..shuffle(random);
    final jack = pool1.sublist(0, 6)..sort();
    final midas = pool2.sublist(0, 6)..sort();
    return DoublejackResult(
      round: round,
      jackNumbers: jack,
      midasNumbers: midas,
    );
  }
}
