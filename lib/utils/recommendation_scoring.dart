import 'dart:math';

class RecommendationScoring {
  const RecommendationScoring._();

  static T bestCandidate<T>({
    required Random rng,
    required T Function() picker,
    required double Function(T candidate) score,
    int attempts = 80,
  }) {
    T best = picker();
    double bestScore = score(best);

    for (int i = 1; i < attempts; i++) {
      final candidate = picker();
      final candidateScore = score(candidate);
      if (candidateScore > bestScore ||
          (candidateScore == bestScore && rng.nextBool())) {
        best = candidate;
        bestScore = candidateScore;
      }
    }

    return best;
  }

  static double scoreNumbers(
    List<int> numbers, {
    required Map<int, int> frequency,
    required int minNumber,
    required int maxNumber,
    required int targetCount,
    double? targetSum,
    double? targetOddRatio,
    Set<int> preferredNumbers = const {},
    Set<int> secondaryPreferredNumbers = const {},
  }) {
    if (numbers.length != targetCount ||
        numbers.toSet().length != numbers.length) {
      return double.negativeInfinity;
    }

    final sorted = List<int>.from(numbers)..sort();
    final sum = sorted.reduce((a, b) => a + b);
    final oddCount = sorted.where((n) => n.isOdd).length;
    final expectedSum = targetSum ?? targetCount * (minNumber + maxNumber) / 2;
    final expectedOddCount = ((targetOddRatio ?? 0.5) * targetCount).clamp(
      1,
      targetCount - 1,
    );
    final maxFrequency = frequency.values.isEmpty
        ? 1
        : frequency.values.reduce(max);
    final frequencyScore =
        sorted
            .map(
              (n) =>
                  (frequency[n] ?? 0) / (maxFrequency == 0 ? 1 : maxFrequency),
            )
            .reduce((a, b) => a + b) /
        targetCount;

    final rangePenalty = _rangePenalty(sorted, minNumber, maxNumber);
    final endDigitPenalty = _endDigitPenalty(sorted);
    final consecutivePairs = _consecutivePairs(sorted);
    final preferredHits = sorted.where(preferredNumbers.contains).length;
    final secondaryHits = sorted
        .where(secondaryPreferredNumbers.contains)
        .length;

    return 100 -
        (sum - expectedSum).abs() * 0.25 -
        (oddCount - expectedOddCount).abs() * 4 -
        rangePenalty -
        max(0, consecutivePairs - 1) * 5 -
        endDigitPenalty +
        frequencyScore * 12 +
        preferredHits * 2.5 +
        secondaryHits * 1.2;
  }

  static double scoreDigitSequence(
    List<int> digits, {
    required List<Map<int, int>> digitFrequency,
    int targetOddCount = 3,
  }) {
    final digitCounts = <int, int>{};
    for (final digit in digits) {
      digitCounts[digit] = (digitCounts[digit] ?? 0) + 1;
    }

    double frequencyScore = 0;
    for (int i = 0; i < digits.length; i++) {
      final freq = digitFrequency[i];
      final maxFrequency = freq.values.isEmpty ? 1 : freq.values.reduce(max);
      frequencyScore +=
          (freq[digits[i]] ?? 0) / (maxFrequency == 0 ? 1 : maxFrequency);
    }

    final oddCount = digits.where((d) => d.isOdd).length;
    final highCount = digits.where((d) => d >= 5).length;
    final repeatPenalty = digitCounts.values
        .where((count) => count > 2)
        .fold<double>(0, (sum, count) => sum + (count - 2) * 6);
    int sameAdjacent = 0;
    for (int i = 1; i < digits.length; i++) {
      if (digits[i] == digits[i - 1]) sameAdjacent++;
    }

    return 100 -
        (oddCount - targetOddCount).abs() * 5 -
        (highCount - 3).abs() * 4 -
        repeatPenalty -
        sameAdjacent * 5 +
        frequencyScore / digits.length * 12;
  }

  static double _rangePenalty(List<int> numbers, int minNumber, int maxNumber) {
    final rangeCount = min(5, numbers.length);
    final width = ((maxNumber - minNumber + 1) / rangeCount).ceil();
    final counts = List<int>.filled(rangeCount, 0);

    for (final number in numbers) {
      final index = ((number - minNumber) ~/ width).clamp(0, rangeCount - 1);
      counts[index]++;
    }

    final expected = numbers.length / rangeCount;
    return counts.fold<double>(
      0,
      (sum, count) => sum + (count - expected).abs() * 1.8,
    );
  }

  static double _endDigitPenalty(List<int> numbers) {
    final counts = <int, int>{};
    for (final number in numbers) {
      counts[number % 10] = (counts[number % 10] ?? 0) + 1;
    }

    return counts.values
        .where((count) => count > 2)
        .fold<double>(0, (sum, count) => sum + (count - 2) * 4);
  }

  static int _consecutivePairs(List<int> numbers) {
    int count = 0;
    for (int i = 1; i < numbers.length; i++) {
      if (numbers[i] - numbers[i - 1] == 1) count++;
    }
    return count;
  }
}
