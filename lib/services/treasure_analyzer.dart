import 'dart:math';
import '../models/treasure_draw.dart';

class TreasureAnalysisResult {
  final Map<int, int> frequency;
  final Map<int, int> treasureFrequency;
  final List<int> hotNumbers;
  final List<int> coldNumbers;
  final List<int> overdueNumbers;
  final List<int> hotTreasures;
  final Map<String, double> rangeDistribution;
  final double avgOddRatio;
  final double avgSum;
  final List<TreasureRecommendation> recommendations;
  final int totalDraws;

  const TreasureAnalysisResult({
    required this.frequency,
    required this.treasureFrequency,
    required this.hotNumbers,
    required this.coldNumbers,
    required this.overdueNumbers,
    required this.hotTreasures,
    required this.rangeDistribution,
    required this.avgOddRatio,
    required this.avgSum,
    required this.recommendations,
    required this.totalDraws,
  });
}

class TreasureRecommendation {
  final String strategy;
  final String icon;
  final List<int> numbers;
  final int treasureNumber;

  const TreasureRecommendation({
    required this.strategy,
    required this.icon,
    required this.numbers,
    required this.treasureNumber,
  });
}

class TreasureAnalyzer {
  final List<TreasureDraw> draws;

  TreasureAnalyzer(this.draws);

  TreasureAnalysisResult analyze() {
    final freq = _calcFrequency();
    final treasureFreq = _calcTreasureFrequency();
    final hot = _getHotNumbers(recentCount: 30);
    final cold = _getColdNumbers(recentCount: 30);
    final overdue = _getOverdueNumbers();
    final hotTreasures = _getHotTreasures();
    final range = _getRangeDistribution();
    final oddRatio = _getAvgOddRatio();
    final avgSum = _getAvgSum();
    final recs = _generateRecommendations(freq, treasureFreq, hot, cold, overdue, hotTreasures);

    return TreasureAnalysisResult(
      frequency: freq,
      treasureFrequency: treasureFreq,
      hotNumbers: hot,
      coldNumbers: cold,
      overdueNumbers: overdue,
      hotTreasures: hotTreasures,
      rangeDistribution: range,
      avgOddRatio: oddRatio,
      avgSum: avgSum,
      recommendations: recs,
      totalDraws: draws.length,
    );
  }

  Map<int, int> _calcFrequency() {
    final freq = {for (int i = 1; i <= 35; i++) i: 0};
    for (final d in draws) {
      for (final n in d.numbers) {
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    return freq;
  }

  Map<int, int> _calcTreasureFrequency() {
    final freq = {for (int i = 1; i <= 10; i++) i: 0};
    for (final d in draws) {
      freq[d.treasureNumber] = (freq[d.treasureNumber] ?? 0) + 1;
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
    return sorted.take(10).map((e) => e.key).toList()..sort();
  }

  List<int> _getColdNumbers({int recentCount = 30}) {
    final recent = draws.take(recentCount).toList();
    final appeared = <int>{};
    for (final d in recent) {
      appeared.addAll(d.numbers);
    }
    final cold = <int>[];
    for (int i = 1; i <= 35; i++) {
      if (!appeared.contains(i)) cold.add(i);
    }
    return cold..sort();
  }

  List<int> _getOverdueNumbers() {
    final lastSeen = <int, int>{};
    for (int i = 1; i <= 35; i++) {
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

  List<int> _getHotTreasures() {
    final recent = draws.take(30).toList();
    final freq = <int, int>{};
    for (final d in recent) {
      freq[d.treasureNumber] = (freq[d.treasureNumber] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList()..sort();
  }

  Map<String, double> _getRangeDistribution() {
    if (draws.isEmpty) return {};
    final ranges = {
      '1-7': 0, '8-14': 0, '15-21': 0, '22-28': 0, '29-35': 0
    };
    int total = 0;
    for (final d in draws) {
      for (final n in d.numbers) {
        total++;
        if (n <= 7) {
          ranges['1-7'] = (ranges['1-7'] ?? 0) + 1;
        } else if (n <= 14) {
          ranges['8-14'] = (ranges['8-14'] ?? 0) + 1;
        } else if (n <= 21) {
          ranges['15-21'] = (ranges['15-21'] ?? 0) + 1;
        } else if (n <= 28) {
          ranges['22-28'] = (ranges['22-28'] ?? 0) + 1;
        } else {
          ranges['29-35'] = (ranges['29-35'] ?? 0) + 1;
        }
      }
    }
    return ranges.map((k, v) => MapEntry(k, total > 0 ? v / total * 100 : 0));
  }

  double _getAvgOddRatio() {
    if (draws.isEmpty) return 0;
    double total = 0;
    for (final d in draws) {
      total += d.numbers.where((n) => n % 2 == 1).length / 6;
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

  int _pickTreasure(List<int> hotTreasures, Random rng) {
    if (hotTreasures.isNotEmpty && rng.nextDouble() < 0.6) {
      return hotTreasures[rng.nextInt(hotTreasures.length)];
    }
    return rng.nextInt(10) + 1;
  }

  List<TreasureRecommendation> _generateRecommendations(
    Map<int, int> freq,
    Map<int, int> treasureFreq,
    List<int> hot,
    List<int> cold,
    List<int> overdue,
    List<int> hotTreasures,
  ) {
    final rng = Random();
    return [
      _hotStrategy(hot, freq, hotTreasures, rng),
      _coldStrategy(cold, freq, hotTreasures, rng),
      _mixedStrategy(hot, overdue, hotTreasures, rng),
      _rangeBalancedStrategy(hotTreasures, rng),
      _weightedRandomStrategy(freq, treasureFreq, rng),
    ];
  }

  TreasureRecommendation _hotStrategy(
      List<int> hot, Map<int, int> freq, List<int> hotTreasures, Random rng) {
    final pool = <int>{...hot};
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      if (pool.length >= 10) break;
      pool.add(e.key);
    }
    final list = pool.toList()..shuffle(rng);
    return TreasureRecommendation(
      strategy: '핫번호 중심',
      icon: '🔥',
      numbers: list.take(6).toList()..sort(),
      treasureNumber: _pickTreasure(hotTreasures, rng),
    );
  }

  TreasureRecommendation _coldStrategy(
      List<int> cold, Map<int, int> freq, List<int> hotTreasures, Random rng) {
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
    return TreasureRecommendation(
      strategy: '콜드번호 포함',
      icon: '❄️',
      numbers: picked.toList()..sort(),
      treasureNumber: _pickTreasure(hotTreasures, rng),
    );
  }

  TreasureRecommendation _mixedStrategy(
      List<int> hot, List<int> overdue, List<int> hotTreasures, Random rng) {
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
      final n = rng.nextInt(35) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    return TreasureRecommendation(
      strategy: '핫 + 장기미출현 혼합',
      icon: '🔄',
      numbers: picked.toList()..sort(),
      treasureNumber: _pickTreasure(hotTreasures, rng),
    );
  }

  TreasureRecommendation _rangeBalancedStrategy(
      List<int> hotTreasures, Random rng) {
    final ranges = [
      List.generate(7, (i) => i + 1),
      List.generate(7, (i) => i + 8),
      List.generate(7, (i) => i + 15),
      List.generate(7, (i) => i + 22),
      List.generate(7, (i) => i + 29),
    ];
    final picked = <int>{};
    for (final range in ranges) {
      range.shuffle(rng);
      picked.add(range.first);
    }
    final all = List.generate(35, (i) => i + 1)..shuffle(rng);
    for (final n in all) {
      if (picked.length >= 6) break;
      if (!picked.contains(n)) picked.add(n);
    }
    return TreasureRecommendation(
      strategy: '구간 균형',
      icon: '⚖️',
      numbers: picked.take(6).toList()..sort(),
      treasureNumber: _pickTreasure(hotTreasures, rng),
    );
  }

  TreasureRecommendation _weightedRandomStrategy(
      Map<int, int> freq, Map<int, int> treasureFreq, Random rng) {
    final maxF = freq.values.reduce(max).toDouble();
    final picked = <int>{};
    int attempts = 0;
    while (picked.length < 6 && attempts < 2000) {
      attempts++;
      final n = rng.nextInt(35) + 1;
      final w = (freq[n] ?? 0) / (maxF > 0 ? maxF : 1);
      if (!picked.contains(n) && rng.nextDouble() < w + 0.3) {
        picked.add(n);
      }
    }
    while (picked.length < 6) {
      final n = rng.nextInt(35) + 1;
      if (!picked.contains(n)) picked.add(n);
    }

    final maxT = treasureFreq.values.reduce(max).toDouble();
    int treasure = rng.nextInt(10) + 1;
    for (int a = 0; a < 100; a++) {
      final t = rng.nextInt(10) + 1;
      final w = (treasureFreq[t] ?? 0) / (maxT > 0 ? maxT : 1);
      if (rng.nextDouble() < w + 0.2) {
        treasure = t;
        break;
      }
    }

    return TreasureRecommendation(
      strategy: '빈도 가중 랜덤',
      icon: '🎲',
      numbers: picked.toList()..sort(),
      treasureNumber: treasure,
    );
  }
}
