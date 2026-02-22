import 'dart:math';
import '../models/tripleluck_draw.dart';

class TripleluckAnalysisResult {
  final Map<int, int> frequency;
  final Map<int, int> tripleFrequency;
  final Map<int, int> luckFrequency;
  final List<int> hotNumbers;
  final List<int> coldNumbers;
  final List<int> overdueNumbers;
  final Map<String, double> rangeDistribution;
  final double avgOddRatio;
  final double avgSum;
  final List<TripleluckRecommendation> recommendations;
  final int totalDraws;

  const TripleluckAnalysisResult({
    required this.frequency,
    required this.tripleFrequency,
    required this.luckFrequency,
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

class TripleluckRecommendation {
  final String strategy;
  final String icon;
  final List<int> tripleNumbers;
  final List<int> luckNumbers;

  const TripleluckRecommendation({
    required this.strategy,
    required this.icon,
    required this.tripleNumbers,
    required this.luckNumbers,
  });

  List<int> get allNumbers => [...tripleNumbers, ...luckNumbers];
}

class TripleluckAnalyzer {
  final List<TripleluckDraw> draws;

  TripleluckAnalyzer(this.draws);

  TripleluckAnalysisResult analyze() {
    final freq = _calcFrequency();
    final tripleFreq = _calcTripleFrequency();
    final luckFreq = _calcLuckFrequency();
    final hot = _getHotNumbers(recentCount: 30);
    final cold = _getColdNumbers(recentCount: 30);
    final overdue = _getOverdueNumbers();
    final range = _getRangeDistribution();
    final oddRatio = _getAvgOddRatio();
    final avgSum = _getAvgSum();
    final recs = _generateRecommendations(freq, tripleFreq, luckFreq, hot, cold, overdue);

    return TripleluckAnalysisResult(
      frequency: freq,
      tripleFrequency: tripleFreq,
      luckFrequency: luckFreq,
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
    final freq = {for (int i = 1; i <= 27; i++) i: 0};
    for (final d in draws) {
      for (final n in d.allNumbers) {
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    return freq;
  }

  Map<int, int> _calcTripleFrequency() {
    final freq = {for (int i = 1; i <= 27; i++) i: 0};
    for (final d in draws) {
      for (final n in d.tripleNumbers) {
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    return freq;
  }

  Map<int, int> _calcLuckFrequency() {
    final freq = {for (int i = 1; i <= 27; i++) i: 0};
    for (final d in draws) {
      for (final n in d.luckNumbers) {
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    return freq;
  }

  List<int> _getHotNumbers({int recentCount = 30}) {
    final recent = draws.take(recentCount).toList();
    final freq = <int, int>{};
    for (final d in recent) {
      for (final n in d.allNumbers) {
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).map((e) => e.key).toList()..sort();
  }

  List<int> _getColdNumbers({int recentCount = 30}) {
    final recent = draws.take(recentCount).toList();
    final appeared = <int>{};
    for (final d in recent) {
      appeared.addAll(d.allNumbers);
    }
    final cold = <int>[];
    for (int i = 1; i <= 27; i++) {
      if (!appeared.contains(i)) cold.add(i);
    }
    return cold..sort();
  }

  List<int> _getOverdueNumbers() {
    final lastSeen = <int, int>{};
    for (int i = 1; i <= 27; i++) {
      lastSeen[i] = -1;
    }
    for (int i = 0; i < draws.length; i++) {
      for (final n in draws[i].allNumbers) {
        if (lastSeen[n] == -1) lastSeen[n] = i;
      }
    }
    final entries = lastSeen.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(6).map((e) => e.key).toList()..sort();
  }

  Map<String, double> _getRangeDistribution() {
    if (draws.isEmpty) return {};
    final ranges = {'1-9': 0, '10-18': 0, '19-27': 0};
    int total = 0;
    for (final d in draws) {
      for (final n in d.allNumbers) {
        total++;
        if (n <= 9) {
          ranges['1-9'] = (ranges['1-9'] ?? 0) + 1;
        } else if (n <= 18) {
          ranges['10-18'] = (ranges['10-18'] ?? 0) + 1;
        } else {
          ranges['19-27'] = (ranges['19-27'] ?? 0) + 1;
        }
      }
    }
    return ranges.map((k, v) => MapEntry(k, total > 0 ? v / total * 100 : 0));
  }

  double _getAvgOddRatio() {
    if (draws.isEmpty) return 0;
    double total = 0;
    for (final d in draws) {
      total += d.allNumbers.where((n) => n % 2 == 1).length / 6;
    }
    return total / draws.length;
  }

  double _getAvgSum() {
    if (draws.isEmpty) return 0;
    double total = 0;
    for (final d in draws) {
      total += d.allNumbers.reduce((a, b) => a + b);
    }
    return total / draws.length;
  }

  List<TripleluckRecommendation> _generateRecommendations(
    Map<int, int> freq,
    Map<int, int> tripleFreq,
    Map<int, int> luckFreq,
    List<int> hot,
    List<int> cold,
    List<int> overdue,
  ) {
    final rng = Random();
    return [
      _hotStrategy(hot, tripleFreq, luckFreq, rng),
      _coldStrategy(cold, freq, rng),
      _mixedStrategy(hot, overdue, rng),
      _positionBiasStrategy(tripleFreq, luckFreq, rng),
      _weightedRandomStrategy(freq, rng),
    ];
  }

  TripleluckRecommendation _hotStrategy(
      List<int> hot, Map<int, int> tripleFreq, Map<int, int> luckFreq, Random rng) {
    final hotShuffled = List<int>.from(hot)..shuffle(rng);
    final picked = <int>{};
    for (final n in hotShuffled.take(6)) {
      picked.add(n);
    }
    while (picked.length < 6) {
      final n = rng.nextInt(27) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    final list = picked.toList()..shuffle(rng);
    return TripleluckRecommendation(
      strategy: '핫번호 중심',
      icon: '🔥',
      tripleNumbers: (list.sublist(0, 3)..sort()),
      luckNumbers: (list.sublist(3, 6)..sort()),
    );
  }

  TripleluckRecommendation _coldStrategy(
      List<int> cold, Map<int, int> freq, Random rng) {
    final picked = <int>{};
    final coldList = List<int>.from(cold)..shuffle(rng);
    for (final n in coldList.take(2)) {
      picked.add(n);
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      if (picked.length >= 6) break;
      if (!picked.contains(e.key)) picked.add(e.key);
    }
    final list = picked.toList()..shuffle(rng);
    return TripleluckRecommendation(
      strategy: '콜드번호 포함',
      icon: '❄️',
      tripleNumbers: (list.sublist(0, 3)..sort()),
      luckNumbers: (list.sublist(3, 6)..sort()),
    );
  }

  TripleluckRecommendation _mixedStrategy(
      List<int> hot, List<int> overdue, Random rng) {
    final picked = <int>{};
    final hotS = List<int>.from(hot)..shuffle(rng);
    final overdueS = List<int>.from(overdue)..shuffle(rng);
    for (final n in hotS.take(3)) {
      picked.add(n);
    }
    for (final n in overdueS) {
      if (picked.length >= 6) break;
      if (!picked.contains(n)) picked.add(n);
    }
    while (picked.length < 6) {
      final n = rng.nextInt(27) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    final list = picked.toList()..shuffle(rng);
    return TripleluckRecommendation(
      strategy: '핫 + 장기미출현 혼합',
      icon: '🔄',
      tripleNumbers: (list.sublist(0, 3)..sort()),
      luckNumbers: (list.sublist(3, 6)..sort()),
    );
  }

  TripleluckRecommendation _positionBiasStrategy(
      Map<int, int> tripleFreq, Map<int, int> luckFreq, Random rng) {
    final tripleSorted = tripleFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final luckSorted = luckFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final triple = <int>{};
    for (final e in tripleSorted) {
      if (triple.length >= 3) break;
      triple.add(e.key);
    }
    final luck = <int>{};
    for (final e in luckSorted) {
      if (luck.length >= 3) break;
      if (!triple.contains(e.key)) luck.add(e.key);
    }
    while (luck.length < 3) {
      final n = rng.nextInt(27) + 1;
      if (!triple.contains(n) && !luck.contains(n)) luck.add(n);
    }
    return TripleluckRecommendation(
      strategy: '포지션 빈도 기반',
      icon: '📍',
      tripleNumbers: triple.toList()..sort(),
      luckNumbers: luck.toList()..sort(),
    );
  }

  TripleluckRecommendation _weightedRandomStrategy(
      Map<int, int> freq, Random rng) {
    final maxF = freq.values.reduce(max).toDouble();
    final picked = <int>{};
    int attempts = 0;
    while (picked.length < 6 && attempts < 2000) {
      attempts++;
      final n = rng.nextInt(27) + 1;
      final w = (freq[n] ?? 0) / (maxF > 0 ? maxF : 1);
      if (!picked.contains(n) && rng.nextDouble() < w + 0.3) {
        picked.add(n);
      }
    }
    while (picked.length < 6) {
      final n = rng.nextInt(27) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    final list = picked.toList()..shuffle(rng);
    return TripleluckRecommendation(
      strategy: '빈도 가중 랜덤',
      icon: '🎲',
      tripleNumbers: (list.sublist(0, 3)..sort()),
      luckNumbers: (list.sublist(3, 6)..sort()),
    );
  }
}
