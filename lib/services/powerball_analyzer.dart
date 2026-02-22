import 'dart:math';
import '../models/powerball_draw.dart';

class PowerballAnalysisResult {
  final Map<int, int> numberFrequency;
  final Map<int, int> powerballFrequency;
  final List<int> hotNumbers;
  final List<int> coldNumbers;
  final List<int> overdueNumbers;
  final List<int> hotPowerballs;
  final Map<String, double> rangeDistribution;
  final List<PowerballRecommendation> recommendations;
  final int totalDraws;

  const PowerballAnalysisResult({
    required this.numberFrequency,
    required this.powerballFrequency,
    required this.hotNumbers,
    required this.coldNumbers,
    required this.overdueNumbers,
    required this.hotPowerballs,
    required this.rangeDistribution,
    required this.recommendations,
    required this.totalDraws,
  });
}

class PowerballRecommendation {
  final String strategy;
  final String icon;
  final List<int> numbers;
  final int powerball;

  const PowerballRecommendation({
    required this.strategy,
    required this.icon,
    required this.numbers,
    required this.powerball,
  });
}

class PowerballAnalyzer {
  final List<PowerballDraw> draws;

  PowerballAnalyzer(this.draws);

  PowerballAnalysisResult analyze() {
    final numFreq = _calcNumberFrequency();
    final pbFreq = _calcPowerballFrequency();
    final hot = _getHotNumbers(recentCount: 30);
    final cold = _getColdNumbers(recentCount: 30);
    final overdue = _getOverdueNumbers();
    final hotPb = _getHotPowerballs(recentCount: 30);
    final rangeDist = _getRangeDistribution();
    final recs = _generateRecommendations(numFreq, pbFreq, hot, cold, overdue, hotPb);

    return PowerballAnalysisResult(
      numberFrequency: numFreq,
      powerballFrequency: pbFreq,
      hotNumbers: hot,
      coldNumbers: cold,
      overdueNumbers: overdue,
      hotPowerballs: hotPb,
      rangeDistribution: rangeDist,
      recommendations: recs,
      totalDraws: draws.length,
    );
  }

  Map<int, int> _calcNumberFrequency() {
    final freq = {for (int i = 1; i <= 28; i++) i: 0};
    for (final draw in draws) {
      for (final n in draw.numbers) {
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    return freq;
  }

  Map<int, int> _calcPowerballFrequency() {
    final freq = {for (int i = 0; i <= 9; i++) i: 0};
    for (final draw in draws) {
      freq[draw.powerball] = (freq[draw.powerball] ?? 0) + 1;
    }
    return freq;
  }

  List<int> _getHotNumbers({int recentCount = 30}) {
    final recent = draws.take(recentCount).toList();
    final freq = <int, int>{};
    for (final draw in recent) {
      for (final n in draw.numbers) {
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
    for (final draw in recent) {
      appeared.addAll(draw.numbers);
    }
    final cold = <int>[];
    for (int i = 1; i <= 28; i++) {
      if (!appeared.contains(i)) cold.add(i);
    }
    return cold..sort();
  }

  List<int> _getOverdueNumbers() {
    final lastSeen = <int, int>{};
    for (int i = 1; i <= 28; i++) {
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

  List<int> _getHotPowerballs({int recentCount = 30}) {
    final recent = draws.take(recentCount).toList();
    final freq = <int, int>{};
    for (final draw in recent) {
      freq[draw.powerball] = (freq[draw.powerball] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }

  Map<String, double> _getRangeDistribution() {
    if (draws.isEmpty) return {};
    final ranges = {'1-7': 0, '8-14': 0, '15-21': 0, '22-28': 0};
    int total = 0;
    for (final draw in draws) {
      for (final n in draw.numbers) {
        total++;
        if (n <= 7) {
          ranges['1-7'] = ranges['1-7']! + 1;
        } else if (n <= 14) {
          ranges['8-14'] = ranges['8-14']! + 1;
        } else if (n <= 21) {
          ranges['15-21'] = ranges['15-21']! + 1;
        } else {
          ranges['22-28'] = ranges['22-28']! + 1;
        }
      }
    }
    return ranges.map((k, v) => MapEntry(k, total > 0 ? v / total * 100 : 0));
  }

  List<PowerballRecommendation> _generateRecommendations(
    Map<int, int> numFreq,
    Map<int, int> pbFreq,
    List<int> hot,
    List<int> cold,
    List<int> overdue,
    List<int> hotPb,
  ) {
    final rng = Random();
    return [
      _hotStrategy(hot, hotPb, rng),
      _coldStrategy(cold, numFreq, pbFreq, rng),
      _mixedStrategy(hot, overdue, hotPb, numFreq, rng),
      _rangeBalancedStrategy(numFreq, pbFreq, rng),
      _weightedRandomStrategy(numFreq, pbFreq, rng),
    ];
  }

  PowerballRecommendation _hotStrategy(
      List<int> hot, List<int> hotPb, Random rng) {
    final pool = List<int>.from(hot);
    while (pool.length < 10) {
      final n = rng.nextInt(28) + 1;
      if (!pool.contains(n)) pool.add(n);
    }
    pool.shuffle(rng);
    final picked = pool.take(5).toList()..sort();
    return PowerballRecommendation(
      strategy: '핫번호 중심',
      icon: '🔥',
      numbers: picked,
      powerball: hotPb[rng.nextInt(hotPb.length)],
    );
  }

  PowerballRecommendation _coldStrategy(
      List<int> cold, Map<int, int> numFreq, Map<int, int> pbFreq, Random rng) {
    final picked = <int>{};
    final coldList = List<int>.from(cold)..shuffle(rng);
    for (final n in coldList.take(2)) {
      picked.add(n);
    }
    final sorted = numFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      if (picked.length >= 5) break;
      if (!picked.contains(e.key)) picked.add(e.key);
    }
    final pbSorted = pbFreq.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return PowerballRecommendation(
      strategy: '콜드번호 포함',
      icon: '❄️',
      numbers: picked.toList()..sort(),
      powerball: pbSorted.first.key,
    );
  }

  PowerballRecommendation _mixedStrategy(
      List<int> hot, List<int> overdue, List<int> hotPb,
      Map<int, int> numFreq, Random rng) {
    final picked = <int>{};
    final hotShuffled = List<int>.from(hot)..shuffle(rng);
    final overdueShuffled = List<int>.from(overdue)..shuffle(rng);
    for (final n in hotShuffled.take(3)) {
      picked.add(n);
    }
    for (final n in overdueShuffled) {
      if (picked.length >= 5) break;
      if (!picked.contains(n)) picked.add(n);
    }
    while (picked.length < 5) {
      final n = rng.nextInt(28) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    return PowerballRecommendation(
      strategy: '핫 + 장기미출현 혼합',
      icon: '🔄',
      numbers: picked.toList()..sort(),
      powerball: hotPb[rng.nextInt(hotPb.length)],
    );
  }

  PowerballRecommendation _rangeBalancedStrategy(
      Map<int, int> numFreq, Map<int, int> pbFreq, Random rng) {
    final ranges = [
      List.generate(7, (i) => i + 1),
      List.generate(7, (i) => i + 8),
      List.generate(7, (i) => i + 15),
      List.generate(7, (i) => i + 22),
    ];
    final picked = <int>{};
    for (final range in ranges) {
      range.shuffle(rng);
      picked.add(range.first);
    }
    while (picked.length < 5) {
      final n = rng.nextInt(28) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    return PowerballRecommendation(
      strategy: '구간 균형',
      icon: '⚖️',
      numbers: picked.toList()..sort(),
      powerball: rng.nextInt(10),
    );
  }

  PowerballRecommendation _weightedRandomStrategy(
      Map<int, int> numFreq, Map<int, int> pbFreq, Random rng) {
    final maxF = numFreq.values.reduce(max).toDouble();
    final picked = <int>{};
    int attempts = 0;
    while (picked.length < 5 && attempts < 1000) {
      attempts++;
      final n = rng.nextInt(28) + 1;
      final w = (numFreq[n] ?? 0) / (maxF > 0 ? maxF : 1);
      if (!picked.contains(n) && rng.nextDouble() < w + 0.3) {
        picked.add(n);
      }
    }
    while (picked.length < 5) {
      final n = rng.nextInt(28) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    final pbMax = pbFreq.values.reduce(max).toDouble();
    int bestPb = 0;
    double bestW = -1;
    for (final e in pbFreq.entries) {
      final w = e.value / (pbMax > 0 ? pbMax : 1) + rng.nextDouble() * 0.3;
      if (w > bestW) {
        bestW = w;
        bestPb = e.key;
      }
    }
    return PowerballRecommendation(
      strategy: '빈도 가중 랜덤',
      icon: '🎲',
      numbers: picked.toList()..sort(),
      powerball: bestPb,
    );
  }
}
