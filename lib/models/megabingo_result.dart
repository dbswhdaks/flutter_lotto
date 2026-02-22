import 'dart:math';

class MegabingoResult {
  final int round;
  final List<int> drawnNumbers; // 추첨된 20개 번호
  final List<int> cardNumbers; // 4x4 빙고판 16개 번호

  const MegabingoResult({
    required this.round,
    required this.drawnNumbers,
    required this.cardNumbers,
  });

  factory MegabingoResult.generate(int round) {
    final random = Random();
    final pool = List.generate(40, (i) => i + 1)..shuffle(random);
    final drawn = (List<int>.from(pool)..shuffle(random)).sublist(0, 20)..sort();
    final card = (List<int>.from(pool)..shuffle(random)).sublist(0, 16);
    return MegabingoResult(round: round, drawnNumbers: drawn, cardNumbers: card);
  }

  /// 빙고판에서 매칭된 인덱스 목록
  Set<int> get matchedIndices {
    final matched = <int>{};
    for (int i = 0; i < cardNumbers.length; i++) {
      if (drawnNumbers.contains(cardNumbers[i])) matched.add(i);
    }
    return matched;
  }

  /// 완성된 빙고 라인 목록 (4개 행, 4개 열, 2개 대각선)
  List<List<int>> get completedLines {
    final matched = matchedIndices;
    final lines = <List<int>>[];

    // 행 (0-3, 4-7, 8-11, 12-15)
    for (int r = 0; r < 4; r++) {
      final line = List.generate(4, (c) => r * 4 + c);
      if (line.every(matched.contains)) lines.add(line);
    }

    // 열
    for (int c = 0; c < 4; c++) {
      final line = List.generate(4, (r) => r * 4 + c);
      if (line.every(matched.contains)) lines.add(line);
    }

    // 대각선
    final diag1 = [0, 5, 10, 15];
    if (diag1.every(matched.contains)) lines.add(diag1);

    final diag2 = [3, 6, 9, 12];
    if (diag2.every(matched.contains)) lines.add(diag2);

    return lines;
  }

  int get bingoCount => completedLines.length;
}
