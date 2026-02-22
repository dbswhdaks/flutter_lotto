import 'dart:math';
import '../models/doublejack_draw.dart';

class DoublejackAnalysisResult {
  final Map<int, int> frequency;
  final Map<int, int> jackFrequency;
  final Map<int, int> midasFrequency;
  final List<int> hotNumbers;
  final List<int> coldNumbers;
  final List<int> overdueNumbers;
  final Map<String, double> rangeDistribution;
  final double avgOddRatio;
  final double avgSum;
  final List<DoublejackRecommendation> recommendations;
  final int totalDraws;

  const DoublejackAnalysisResult({
    required this.frequency,
    required this.jackFrequency,
    required this.midasFrequency,
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

class DoublejackRecommendation {
  final String strategy;
  final String icon;
  final List<int> jackNumbers;
  final List<int> midasNumbers;

  const DoublejackRecommendation({
    required this.strategy,
    required this.icon,
    required this.jackNumbers,
    required this.midasNumbers,
  });
}

class DoublejackAnalyzer {
  final List<DoublejackDraw> draws;

  DoublejackAnalyzer(this.draws);

  DoublejackAnalysisResult analyze() {
    final freq = _calcFrequency();
    final jackFreq = _calcJackFrequency();
    final midasFreq = _calcMidasFrequency();
    final hot = _getHotNumbers(recentCount: 30);
    final cold = _getColdNumbers(recentCount: 30);
    final overdue = _getOverdueNumbers();
    final range = _getRangeDistribution();
    final oddRatio = _getAvgOddRatio();
    final avgSum = _getAvgSum();
    final recs =
        _generateRecommendations(freq, jackFreq, midasFreq, hot, cold, overdue);

    return DoublejackAnalysisResult(
      frequency: freq,
      jackFrequency: jackFreq,
      midasFrequency: midasFreq,
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
    final freq = {for (int i = 1; i <= 45; i++) i: 0};
    for (final d in draws) {
      for (final n in d.allNumbers) {
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    return freq;
  }

  Map<int, int> _calcJackFrequency() {
    final freq = {for (int i = 1; i <= 45; i++) i: 0};
    for (final d in draws) {
      for (final n in d.jackNumbers) {
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    return freq;
  }

  Map<int, int> _calcMidasFrequency() {
    final freq = {for (int i = 1; i <= 45; i++) i: 0};
    for (final d in draws) {
      for (final n in d.midasNumbers) {
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
    return sorted.take(12).map((e) => e.key).toList()..sort();
  }

  List<int> _getColdNumbers({int recentCount = 30}) {
    final recent = draws.take(recentCount).toList();
    final appeared = <int>{};
    for (final d in recent) {
      appeared.addAll(d.allNumbers);
    }
    final cold = <int>[];
    for (int i = 1; i <= 45; i++) {
      if (!appeared.contains(i)) cold.add(i);
    }
    return cold..sort();
  }

  List<int> _getOverdueNumbers() {
    final lastSeen = <int, int>{};
    for (int i = 1; i <= 45; i++) {
      lastSeen[i] = -1;
    }
    for (int i = 0; i < draws.length; i++) {
      for (final n in draws[i].allNumbers) {
        if (lastSeen[n] == -1) lastSeen[n] = i;
      }
    }
    final entries = lastSeen.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(8).map((e) => e.key).toList()..sort();
  }

  Map<String, double> _getRangeDistribution() {
    if (draws.isEmpty) return {};
    final ranges = {
      '1-9': 0, '10-18': 0, '19-27': 0, '28-36': 0, '37-45': 0
    };
    int total = 0;
    for (final d in draws) {
      for (final n in d.allNumbers) {
        total++;
        if (n <= 9) {
          ranges['1-9'] = (ranges['1-9'] ?? 0) + 1;
        } else if (n <= 18) {
          ranges['10-18'] = (ranges['10-18'] ?? 0) + 1;
        } else if (n <= 27) {
          ranges['19-27'] = (ranges['19-27'] ?? 0) + 1;
        } else if (n <= 36) {
          ranges['28-36'] = (ranges['28-36'] ?? 0) + 1;
        } else {
          ranges['37-45'] = (ranges['37-45'] ?? 0) + 1;
        }
      }
    }
    return ranges.map((k, v) => MapEntry(k, total > 0 ? v / total * 100 : 0));
  }

  double _getAvgOddRatio() {
    if (draws.isEmpty) return 0;
    double total = 0;
    for (final d in draws) {
      total += d.allNumbers.where((n) => n % 2 == 1).length / 12;
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

  List<DoublejackRecommendation> _generateRecommendations(
    Map<int, int> freq,
    Map<int, int> jackFreq,
    Map<int, int> midasFreq,
    List<int> hot,
    List<int> cold,
    List<int> overdue,
  ) {
    final rng = Random();
    return [
      _hotStrategy(hot, freq, rng),
      _coldStrategy(cold, freq, rng),
      _mixedStrategy(hot, overdue, rng),
      _positionBiasStrategy(jackFreq, midasFreq, rng),
      _weightedRandomStrategy(freq, rng),
    ];
  }

  DoublejackRecommendation _hotStrategy(
      List<int> hot, Map<int, int> freq, Random rng) {
    final pool = <int>{...hot};
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      if (pool.length >= 16) break;
      pool.add(e.key);
    }
    final list = pool.toList()..shuffle(rng);
    return DoublejackRecommendation(
      strategy: '핫번호 중심',
      icon: '🔥',
      jackNumbers: (list.sublist(0, 6)..sort()),
      midasNumbers: (list.sublist(6, 12)..sort()),
    );
  }

  DoublejackRecommendation _coldStrategy(
      List<int> cold, Map<int, int> freq, Random rng) {
    final picked = <int>{};
    final coldList = List<int>.from(cold)..shuffle(rng);
    for (final n in coldList.take(4)) {
      picked.add(n);
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      if (picked.length >= 12) break;
      if (!picked.contains(e.key)) picked.add(e.key);
    }
    final list = picked.toList()..shuffle(rng);
    return DoublejackRecommendation(
      strategy: '콜드번호 포함',
      icon: '❄️',
      jackNumbers: (list.sublist(0, 6)..sort()),
      midasNumbers: (list.sublist(6, 12)..sort()),
    );
  }

  DoublejackRecommendation _mixedStrategy(
      List<int> hot, List<int> overdue, Random rng) {
    final picked = <int>{};
    final hotS = List<int>.from(hot)..shuffle(rng);
    final overdueS = List<int>.from(overdue)..shuffle(rng);
    for (final n in hotS.take(6)) {
      picked.add(n);
    }
    for (final n in overdueS) {
      if (picked.length >= 12) break;
      if (!picked.contains(n)) picked.add(n);
    }
    while (picked.length < 12) {
      final n = rng.nextInt(45) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    final list = picked.toList()..shuffle(rng);
    return DoublejackRecommendation(
      strategy: '핫 + 장기미출현 혼합',
      icon: '🔄',
      jackNumbers: (list.sublist(0, 6)..sort()),
      midasNumbers: (list.sublist(6, 12)..sort()),
    );
  }

  DoublejackRecommendation _positionBiasStrategy(
      Map<int, int> jackFreq, Map<int, int> midasFreq, Random rng) {
    final jackSorted = jackFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final midasSorted = midasFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final jack = <int>{};
    for (final e in jackSorted) {
      if (jack.length >= 6) break;
      jack.add(e.key);
    }
    final midas = <int>{};
    for (final e in midasSorted) {
      if (midas.length >= 6) break;
      if (!jack.contains(e.key)) midas.add(e.key);
    }
    while (midas.length < 6) {
      final n = rng.nextInt(45) + 1;
      if (!jack.contains(n) && !midas.contains(n)) midas.add(n);
    }
    return DoublejackRecommendation(
      strategy: '포지션 빈도 기반',
      icon: '📍',
      jackNumbers: jack.toList()..sort(),
      midasNumbers: midas.toList()..sort(),
    );
  }

  DoublejackRecommendation _weightedRandomStrategy(
      Map<int, int> freq, Random rng) {
    final maxF = freq.values.reduce(max).toDouble();
    final picked = <int>{};
    int attempts = 0;
    while (picked.length < 12 && attempts < 3000) {
      attempts++;
      final n = rng.nextInt(45) + 1;
      final w = (freq[n] ?? 0) / (maxF > 0 ? maxF : 1);
      if (!picked.contains(n) && rng.nextDouble() < w + 0.3) {
        picked.add(n);
      }
    }
    while (picked.length < 12) {
      final n = rng.nextInt(45) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    final list = picked.toList()..shuffle(rng);
    return DoublejackRecommendation(
      strategy: '빈도 가중 랜덤',
      icon: '🎲',
      jackNumbers: (list.sublist(0, 6)..sort()),
      midasNumbers: (list.sublist(6, 12)..sort()),
    );
  }
}
