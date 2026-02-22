import 'dart:math';
import '../models/speedkino_draw.dart';

class SpeedkinoAnalysisResult {
  final Map<int, int> frequency;
  final List<int> hotNumbers;
  final List<int> coldNumbers;
  final List<int> overdueNumbers;
  final Map<String, double> rangeDistribution;
  final double avgOddRatio;
  final double avgSum;
  final List<SpeedkinoRecommendation> recommendations;
  final int totalDraws;

  const SpeedkinoAnalysisResult({
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

class SpeedkinoRecommendation {
  final String strategy;
  final String icon;
  final List<int> numbers;

  const SpeedkinoRecommendation({
    required this.strategy,
    required this.icon,
    required this.numbers,
  });
}

class SpeedkinoAnalyzer {
  final List<SpeedkinoDraw> draws;

  SpeedkinoAnalyzer(this.draws);

  SpeedkinoAnalysisResult analyze() {
    final freq = _calcFrequency();
    final hot = _getHotNumbers(recentCount: 30);
    final cold = _getColdNumbers(recentCount: 30);
    final overdue = _getOverdueNumbers();
    final range = _getRangeDistribution();
    final oddRatio = _getAvgOddRatio();
    final avgSum = _getAvgSum();
    final recs = _generateRecommendations(freq, hot, cold, overdue);

    return SpeedkinoAnalysisResult(
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
    final freq = {for (int i = 1; i <= 70; i++) i: 0};
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
    for (int i = 1; i <= 70; i++) {
      if (!appeared.contains(i)) cold.add(i);
    }
    return cold..sort();
  }

  List<int> _getOverdueNumbers() {
    final lastSeen = <int, int>{};
    for (int i = 1; i <= 70; i++) {
      lastSeen[i] = -1;
    }
    for (int i = 0; i < draws.length; i++) {
      for (final n in draws[i].numbers) {
        if (lastSeen[n] == -1) lastSeen[n] = i;
      }
    }
    final entries = lastSeen.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(10).map((e) => e.key).toList()..sort();
  }

  Map<String, double> _getRangeDistribution() {
    if (draws.isEmpty) return {};
    final ranges = {
      '1-10': 0, '11-20': 0, '21-30': 0, '31-40': 0,
      '41-50': 0, '51-60': 0, '61-70': 0,
    };
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
      total += d.numbers.where((n) => n % 2 == 1).length / 10;
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

  List<SpeedkinoRecommendation> _generateRecommendations(
    Map<int, int> freq,
    List<int> hot,
    List<int> cold,
    List<int> overdue,
  ) {
    final rng = Random();
    return [
      _hotStrategy(hot, freq, rng),
      _coldStrategy(cold, freq, rng),
      _mixedStrategy(hot, overdue, freq, rng),
      _rangeBalancedStrategy(freq, rng),
      _weightedRandomStrategy(freq, rng),
    ];
  }

  SpeedkinoRecommendation _hotStrategy(
      List<int> hot, Map<int, int> freq, Random rng) {
    final pool = List<int>.from(hot);
    while (pool.length < 20) {
      final n = rng.nextInt(70) + 1;
      if (!pool.contains(n)) pool.add(n);
    }
    pool.shuffle(rng);
    return SpeedkinoRecommendation(
      strategy: '핫번호 중심',
      icon: '🔥',
      numbers: pool.take(10).toList()..sort(),
    );
  }

  SpeedkinoRecommendation _coldStrategy(
      List<int> cold, Map<int, int> freq, Random rng) {
    final picked = <int>{};
    final coldList = List<int>.from(cold)..shuffle(rng);
    for (final n in coldList.take(4)) {
      picked.add(n);
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      if (picked.length >= 10) break;
      if (!picked.contains(e.key)) picked.add(e.key);
    }
    return SpeedkinoRecommendation(
      strategy: '콜드번호 포함',
      icon: '❄️',
      numbers: picked.toList()..sort(),
    );
  }

  SpeedkinoRecommendation _mixedStrategy(
      List<int> hot, List<int> overdue, Map<int, int> freq, Random rng) {
    final picked = <int>{};
    final hotS = List<int>.from(hot)..shuffle(rng);
    final overdueS = List<int>.from(overdue)..shuffle(rng);
    for (final n in hotS.take(5)) {
      picked.add(n);
    }
    for (final n in overdueS) {
      if (picked.length >= 10) break;
      if (!picked.contains(n)) picked.add(n);
    }
    while (picked.length < 10) {
      final n = rng.nextInt(70) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    return SpeedkinoRecommendation(
      strategy: '핫 + 장기미출현 혼합',
      icon: '🔄',
      numbers: picked.toList()..sort(),
    );
  }

  SpeedkinoRecommendation _rangeBalancedStrategy(
      Map<int, int> freq, Random rng) {
    final ranges = List.generate(
        7, (i) => List.generate(10, (j) => i * 10 + j + 1));
    final picked = <int>{};
    for (final range in ranges) {
      range.shuffle(rng);
      picked.add(range.first);
    }
    while (picked.length < 10) {
      final n = rng.nextInt(70) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    return SpeedkinoRecommendation(
      strategy: '구간 균형',
      icon: '⚖️',
      numbers: picked.toList()..sort(),
    );
  }

  SpeedkinoRecommendation _weightedRandomStrategy(
      Map<int, int> freq, Random rng) {
    final maxF = freq.values.reduce(max).toDouble();
    final picked = <int>{};
    int attempts = 0;
    while (picked.length < 10 && attempts < 2000) {
      attempts++;
      final n = rng.nextInt(70) + 1;
      final w = (freq[n] ?? 0) / (maxF > 0 ? maxF : 1);
      if (!picked.contains(n) && rng.nextDouble() < w + 0.3) {
        picked.add(n);
      }
    }
    while (picked.length < 10) {
      final n = rng.nextInt(70) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    return SpeedkinoRecommendation(
      strategy: '빈도 가중 랜덤',
      icon: '🎲',
      numbers: picked.toList()..sort(),
    );
  }
}
