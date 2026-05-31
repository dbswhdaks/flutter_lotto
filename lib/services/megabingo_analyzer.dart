import 'dart:math';
import '../models/megabingo_draw.dart';
import '../utils/recommendation_scoring.dart';

class MegabingoAnalysisResult {
  final Map<int, int> frequency;
  final List<int> hotNumbers;
  final List<int> coldNumbers;
  final List<int> overdueNumbers;
  final Map<String, double> rangeDistribution;
  final double avgOddRatio;
  final double avgSum;
  final List<MegabingoRecommendation> recommendations;
  final int totalDraws;

  const MegabingoAnalysisResult({
    required this.frequency,
    required this.hotNumbers,
    required this.coldNumbers,
    required this.overdueNumbers,
    required this.rangeDistribution,
    required this.avgOddRatio,
    required this.avgSum,
    required this.recommendations,
    required this.totalDraws,
  });
}

class MegabingoRecommendation {
  final String strategy;
  final String icon;
  final List<int> numbers; // 추천 20개 번호

  const MegabingoRecommendation({
    required this.strategy,
    required this.icon,
    required this.numbers,
  });
}

class MegabingoAnalyzer {
  final List<MegabingoDraw> draws;

  MegabingoAnalyzer(this.draws);

  MegabingoAnalysisResult analyze() {
    final freq = _calcFrequency();
    final hot = _getHotNumbers(recentCount: 30);
    final cold = _getColdNumbers(recentCount: 30);
    final overdue = _getOverdueNumbers();
    final range = _getRangeDistribution();
    final oddRatio = _getAvgOddRatio();
    final avgSum = _getAvgSum();
    final recs = _generateRecommendations(
      freq,
      hot,
      cold,
      overdue,
      avgSum,
      oddRatio,
    );

    return MegabingoAnalysisResult(
      frequency: freq,
      hotNumbers: hot,
      coldNumbers: cold,
      overdueNumbers: overdue,
      rangeDistribution: range,
      avgOddRatio: oddRatio,
      avgSum: avgSum,
      recommendations: recs,
      totalDraws: draws.length,
    );
  }

  Map<int, int> _calcFrequency() {
    final freq = {for (int i = 1; i <= 40; i++) i: 0};
    for (final d in draws) {
      for (final n in d.numbers) {
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    return freq;
  }

  List<int> _getHotNumbers({int recentCount = 30}) {
    final recent = draws.take(recentCount).toList();
    final freq = <int, int>{};
    for (final d in recent) {
      for (final n in d.numbers) {
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(15).map((e) => e.key).toList()..sort();
  }

  List<int> _getColdNumbers({int recentCount = 30}) {
    final recent = draws.take(recentCount).toList();
    final appeared = <int>{};
    for (final d in recent) {
      appeared.addAll(d.numbers);
    }
    final cold = <int>[];
    for (int i = 1; i <= 40; i++) {
      if (!appeared.contains(i)) cold.add(i);
    }
    return cold..sort();
  }

  List<int> _getOverdueNumbers() {
    final lastSeen = <int, int>{};
    for (int i = 1; i <= 40; i++) {
      lastSeen[i] = -1;
    }
    for (int i = 0; i < draws.length; i++) {
      for (final n in draws[i].numbers) {
        if (lastSeen[n] == -1) lastSeen[n] = i;
      }
    }
    final entries = lastSeen.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(8).map((e) => e.key).toList()..sort();
  }

  Map<String, double> _getRangeDistribution() {
    if (draws.isEmpty) return {};
    final ranges = {'1-10': 0, '11-20': 0, '21-30': 0, '31-40': 0};
    int total = 0;
    for (final d in draws) {
      for (final n in d.numbers) {
        total++;
        final key = '${((n - 1) ~/ 10) * 10 + 1}-${((n - 1) ~/ 10) * 10 + 10}';
        ranges[key] = (ranges[key] ?? 0) + 1;
      }
    }
    return ranges.map((k, v) => MapEntry(k, total > 0 ? v / total * 100 : 0));
  }

  double _getAvgOddRatio() {
    if (draws.isEmpty) return 0;
    double total = 0;
    for (final d in draws) {
      total += d.numbers.where((n) => n % 2 == 1).length / 20;
    }
    return total / draws.length;
  }

  double _getAvgSum() {
    if (draws.isEmpty) return 0;
    double total = 0;
    for (final d in draws) {
      total += d.numbers.reduce((a, b) => a + b);
    }
    return total / draws.length;
  }

  List<MegabingoRecommendation> _generateRecommendations(
    Map<int, int> freq,
    List<int> hot,
    List<int> cold,
    List<int> overdue,
    double avgSum,
    double avgOddRatio,
  ) {
    final rng = Random();
    MegabingoRecommendation improve(MegabingoRecommendation Function() picker) {
      return RecommendationScoring.bestCandidate(
        rng: rng,
        picker: picker,
        score: (rec) => RecommendationScoring.scoreNumbers(
          rec.numbers,
          frequency: freq,
          minNumber: 1,
          maxNumber: 40,
          targetCount: 20,
          targetSum: avgSum,
          targetOddRatio: avgOddRatio,
          preferredNumbers: hot.toSet(),
          secondaryPreferredNumbers: overdue.toSet(),
        ),
        attempts: 60,
      );
    }

    return [
      improve(() => _hotStrategy(hot, freq, rng)),
      improve(() => _coldStrategy(cold, freq, rng)),
      improve(() => _mixedStrategy(hot, overdue, freq, rng)),
      improve(() => _rangeBalancedStrategy(rng)),
      improve(() => _weightedRandomStrategy(freq, rng)),
    ];
  }

  MegabingoRecommendation _hotStrategy(
    List<int> hot,
    Map<int, int> freq,
    Random rng,
  ) {
    final pool = <int>{...hot};
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      if (pool.length >= 25) break;
      pool.add(e.key);
    }
    final list = pool.toList()..shuffle(rng);
    return MegabingoRecommendation(
      strategy: '핫번호 중심',
      icon: '🔥',
      numbers: list.take(20).toList()..sort(),
    );
  }

  MegabingoRecommendation _coldStrategy(
    List<int> cold,
    Map<int, int> freq,
    Random rng,
  ) {
    final picked = <int>{};
    final coldList = List<int>.from(cold)..shuffle(rng);
    for (final n in coldList.take(6)) {
      picked.add(n);
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      if (picked.length >= 20) break;
      if (!picked.contains(e.key)) picked.add(e.key);
    }
    return MegabingoRecommendation(
      strategy: '콜드번호 포함',
      icon: '❄️',
      numbers: picked.toList()..sort(),
    );
  }

  MegabingoRecommendation _mixedStrategy(
    List<int> hot,
    List<int> overdue,
    Map<int, int> freq,
    Random rng,
  ) {
    final picked = <int>{};
    final hotS = List<int>.from(hot)..shuffle(rng);
    final overdueS = List<int>.from(overdue)..shuffle(rng);
    for (final n in hotS.take(10)) {
      picked.add(n);
    }
    for (final n in overdueS) {
      if (picked.length >= 20) break;
      if (!picked.contains(n)) picked.add(n);
    }
    while (picked.length < 20) {
      final n = rng.nextInt(40) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    return MegabingoRecommendation(
      strategy: '핫 + 장기미출현 혼합',
      icon: '🔄',
      numbers: picked.toList()..sort(),
    );
  }

  MegabingoRecommendation _rangeBalancedStrategy(Random rng) {
    final ranges = [
      List.generate(10, (i) => i + 1),
      List.generate(10, (i) => i + 11),
      List.generate(10, (i) => i + 21),
      List.generate(10, (i) => i + 31),
    ];
    final picked = <int>{};
    for (final range in ranges) {
      range.shuffle(rng);
      for (final n in range.take(5)) {
        picked.add(n);
      }
    }
    return MegabingoRecommendation(
      strategy: '구간 균형',
      icon: '⚖️',
      numbers: picked.toList()..sort(),
    );
  }

  MegabingoRecommendation _weightedRandomStrategy(
    Map<int, int> freq,
    Random rng,
  ) {
    final maxF = freq.values.reduce(max).toDouble();
    final picked = <int>{};
    int attempts = 0;
    while (picked.length < 20 && attempts < 3000) {
      attempts++;
      final n = rng.nextInt(40) + 1;
      final w = (freq[n] ?? 0) / (maxF > 0 ? maxF : 1);
      if (!picked.contains(n) && rng.nextDouble() < w + 0.3) {
        picked.add(n);
      }
    }
    while (picked.length < 20) {
      final n = rng.nextInt(40) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    return MegabingoRecommendation(
      strategy: '빈도 가중 랜덤',
      icon: '🎲',
      numbers: picked.toList()..sort(),
    );
  }
}
