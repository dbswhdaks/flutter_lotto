import 'dart:math';
import '../models/lotto_draw.dart';

class AnalysisResult {
  final Map<int, int> frequency;
  final List<int> hotNumbers;
  final List<int> coldNumbers;
  final List<int> overdueNumbers;
  final Map<String, double> rangeDistribution;
  final double avgOddEvenRatio;
  final double avgSum;
  final List<List<int>> recommendations;

  const AnalysisResult({
    required this.frequency,
    required this.hotNumbers,
    required this.coldNumbers,
    required this.overdueNumbers,
    required this.rangeDistribution,
    required this.avgOddEvenRatio,
    required this.avgSum,
    required this.recommendations,
  });
}

class LottoAnalyzer {
  final List<LottoDraw> draws;

  LottoAnalyzer(this.draws);

  AnalysisResult analyze() {
    final freq = _calcFrequency();
    final hot = _getHotNumbers(recentCount: 20);
    final cold = _getColdNumbers(recentCount: 20);
    final overdue = _getOverdueNumbers();
    final rangeDist = _getRangeDistribution();
    final oddEven = _getAvgOddEvenRatio();
    final avgSum = _getAvgSum();
    final recs = _generateRecommendations(freq, hot, cold, overdue);

    return AnalysisResult(
      frequency: freq,
      hotNumbers: hot,
      coldNumbers: cold,
      overdueNumbers: overdue,
      rangeDistribution: rangeDist,
      avgOddEvenRatio: oddEven,
      avgSum: avgSum,
      recommendations: recs,
    );
  }

  Map<int, int> _calcFrequency() {
    final freq = <int, int>{};
    for (int i = 1; i <= 45; i++) {
      freq[i] = 0;
    }
    for (final draw in draws) {
      for (final n in draw.numbers) {
        freq[n] = (freq[n] ?? 0) + 1;
      }
    }
    return freq;
  }

  List<int> _getHotNumbers({int recentCount = 20}) {
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

  List<int> _getColdNumbers({int recentCount = 20}) {
    final recent = draws.take(recentCount).toList();
    final appeared = <int>{};
    for (final draw in recent) {
      appeared.addAll(draw.numbers);
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
    final ranges = {'1-10': 0, '11-20': 0, '21-30': 0, '31-40': 0, '41-45': 0};
    int total = 0;
    for (final draw in draws) {
      for (final n in draw.numbers) {
        total++;
        if (n <= 10) {
          ranges['1-10'] = ranges['1-10']! + 1;
        } else if (n <= 20) {
          ranges['11-20'] = ranges['11-20']! + 1;
        } else if (n <= 30) {
          ranges['21-30'] = ranges['21-30']! + 1;
        } else if (n <= 40) {
          ranges['31-40'] = ranges['31-40']! + 1;
        } else {
          ranges['41-45'] = ranges['41-45']! + 1;
        }
      }
    }
    return ranges.map((k, v) => MapEntry(k, total > 0 ? v / total * 100 : 0));
  }

  double _getAvgOddEvenRatio() {
    if (draws.isEmpty) return 0;
    double totalRatio = 0;
    for (final draw in draws) {
      final odd = draw.numbers.where((n) => n % 2 == 1).length;
      totalRatio += odd / 6;
    }
    return totalRatio / draws.length;
  }

  double _getAvgSum() {
    if (draws.isEmpty) return 0;
    double totalSum = 0;
    for (final draw in draws) {
      totalSum += draw.numbers.reduce((a, b) => a + b);
    }
    return totalSum / draws.length;
  }

  List<List<int>> _generateRecommendations(
    Map<int, int> freq,
    List<int> hot,
    List<int> cold,
    List<int> overdue,
  ) {
    final rng = Random();
    final results = <List<int>>[];

    // 전략 1: 핫번호 중심
    results.add(_pickBalanced(hot, freq, rng));

    // 전략 2: 콜드번호 포함 (안 나왔으니 나올 때)
    results.add(_pickWithCold(cold, freq, rng));

    // 전략 3: 오래된 번호 + 핫번호 혼합
    results.add(_pickMixed(hot, overdue, freq, rng));

    // 전략 4: 구간 균형 전략
    results.add(_pickRangeBalanced(freq, rng));

    // 전략 5: 빈도 기반 가중 랜덤
    results.add(_pickWeightedRandom(freq, rng));

    return results;
  }

  List<int> _pickBalanced(List<int> preferred, Map<int, int> freq, Random rng) {
    final pool = List<int>.from(preferred);
    while (pool.length < 20) {
      final n = rng.nextInt(45) + 1;
      if (!pool.contains(n)) pool.add(n);
    }
    pool.shuffle(rng);
    final picked = pool.take(6).toList()..sort();
    return picked;
  }

  List<int> _pickWithCold(List<int> cold, Map<int, int> freq, Random rng) {
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
    return picked.toList()..sort();
  }

  List<int> _pickMixed(
      List<int> hot, List<int> overdue, Map<int, int> freq, Random rng) {
    final picked = <int>{};
    final hotShuffled = List<int>.from(hot)..shuffle(rng);
    final overdueShuffled = List<int>.from(overdue)..shuffle(rng);
    for (final n in hotShuffled.take(3)) {
      picked.add(n);
    }
    for (final n in overdueShuffled) {
      if (picked.length >= 6) break;
      if (!picked.contains(n)) picked.add(n);
    }
    while (picked.length < 6) {
      final n = rng.nextInt(45) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    return picked.toList()..sort();
  }

  List<int> _pickRangeBalanced(Map<int, int> freq, Random rng) {
    final ranges = [
      List.generate(10, (i) => i + 1),
      List.generate(10, (i) => i + 11),
      List.generate(10, (i) => i + 21),
      List.generate(10, (i) => i + 31),
      List.generate(5, (i) => i + 41),
    ];
    final picked = <int>{};
    // 각 구간에서 1개 이상
    for (final range in ranges) {
      range.shuffle(rng);
      picked.add(range.first);
    }
    // 나머지 1개 랜덤
    while (picked.length < 6) {
      final n = rng.nextInt(45) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    return picked.toList()..sort();
  }

  List<int> _pickWeightedRandom(Map<int, int> freq, Random rng) {
    final weights = <int, double>{};
    final maxF = freq.values.reduce(max).toDouble();
    for (int i = 1; i <= 45; i++) {
      weights[i] = (freq[i] ?? 0) / (maxF > 0 ? maxF : 1);
    }
    final picked = <int>{};
    int attempts = 0;
    while (picked.length < 6 && attempts < 1000) {
      attempts++;
      final n = rng.nextInt(45) + 1;
      if (!picked.contains(n) && rng.nextDouble() < (weights[n] ?? 0.5) + 0.3) {
        picked.add(n);
      }
    }
    while (picked.length < 6) {
      final n = rng.nextInt(45) + 1;
      if (!picked.contains(n)) picked.add(n);
    }
    return picked.toList()..sort();
  }

  String buildPromptForAI() {
    final result = analyze();
    final buf = StringBuffer();

    buf.writeln('한국 로또 6/45 최근 ${draws.length}회 당첨번호 분석 데이터:');
    buf.writeln();

    buf.writeln('## 최근 10회 당첨번호');
    for (final d in draws.take(10)) {
      buf.writeln('${d.round}회: ${d.numbers.join(", ")} + 보너스 ${d.bonus}');
    }
    buf.writeln();

    buf.writeln('## 핫번호 (최근 20회 자주 출현): ${result.hotNumbers.join(", ")}');
    buf.writeln('## 콜드번호 (최근 20회 미출현): ${result.coldNumbers.join(", ")}');
    buf.writeln('## 장기 미출현 번호: ${result.overdueNumbers.join(", ")}');
    buf.writeln();

    buf.writeln('## 구간별 출현 비율');
    for (final e in result.rangeDistribution.entries) {
      buf.writeln('  ${e.key}: ${e.value.toStringAsFixed(1)}%');
    }
    buf.writeln();

    buf.writeln('평균 홀수 비율: ${(result.avgOddEvenRatio * 100).toStringAsFixed(1)}%');
    buf.writeln('평균 합계: ${result.avgSum.toStringAsFixed(0)}');
    buf.writeln();

    buf.writeln('위 데이터를 바탕으로 다음 회차 로또 번호 5세트를 추천해 주세요.');
    buf.writeln('각 세트는 1~45 중 중복 없는 6개 번호이며, 오름차순으로 정렬해 주세요.');
    buf.writeln('각 세트에 대해 간단한 추천 이유도 한 줄로 설명해 주세요.');
    buf.writeln('응답 형식: "세트N: [번호6개] - 이유"');

    return buf.toString();
  }
}
