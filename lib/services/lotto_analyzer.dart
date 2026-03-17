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

class FullAnalysisResult {
  final int totalDraws;
  final int latestRound;
  final Map<int, int> frequency;
  final Map<int, int> bonusFrequency;
  final List<int> hotNumbers;
  final List<int> coldNumbers;
  final List<int> overdueNumbers;
  final Map<int, int> overdueGap;
  final Map<String, double> rangeDistribution;
  final double avgOddEvenRatio;
  final double avgSum;
  final Map<int, int> endDigitFrequency;
  final List<MapEntry<String, int>> topPairs;
  final List<MapEntry<String, int>> topTriplets;
  final Map<int, int> consecutivePairCount;
  final Map<String, double> recentTrend;
  final List<RoundRecommendation> roundRecommendations;

  const FullAnalysisResult({
    required this.totalDraws,
    required this.latestRound,
    required this.frequency,
    required this.bonusFrequency,
    required this.hotNumbers,
    required this.coldNumbers,
    required this.overdueNumbers,
    required this.overdueGap,
    required this.rangeDistribution,
    required this.avgOddEvenRatio,
    required this.avgSum,
    required this.endDigitFrequency,
    required this.topPairs,
    required this.topTriplets,
    required this.consecutivePairCount,
    required this.recentTrend,
    required this.roundRecommendations,
  });
}

class RoundRecommendation {
  final int round;
  final List<RecommendationSet> sets;

  const RoundRecommendation({required this.round, required this.sets});
}

class RecommendationSet {
  final String strategy;
  final String emoji;
  final List<int> numbers;
  final String reason;

  const RecommendationSet({
    required this.strategy,
    required this.emoji,
    required this.numbers,
    required this.reason,
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

  FullAnalysisResult fullAnalyze({
    int recommendCount = 5,
    int? overrideLatestRound,
  }) {
    final freq = _calcFrequency();
    final bonusFreq = _calcBonusFrequency();
    final hot = _getHotNumbers(recentCount: 50);
    final cold = _getColdNumbers(recentCount: 50);
    final overdueResult = _getOverdueNumbersWithGap();
    final rangeDist = _getRangeDistribution();
    final oddEven = _getAvgOddEvenRatio();
    final avgSum = _getAvgSum();
    final endDigit = _getEndDigitFrequency();
    final pairs = _getTopPairs();
    final triplets = _getTopTriplets();
    final consecutive = _getConsecutivePairCount();
    final trend = _getRecentTrend();

    final latestRound = overrideLatestRound
        ?? (draws.isNotEmpty ? draws.first.round : 0);

    final recommendations = <RoundRecommendation>[];
    for (int i = 0; i < recommendCount; i++) {
      final round = latestRound + 1 + i;
      recommendations.add(RoundRecommendation(
        round: round,
        sets: _generateRoundSets(
          freq, hot, cold, overdueResult['numbers'] as List<int>,
          overdueResult['gap'] as Map<int, int>, pairs, round,
        ),
      ));
    }

    return FullAnalysisResult(
      totalDraws: draws.length,
      latestRound: latestRound,
      frequency: freq,
      bonusFrequency: bonusFreq,
      hotNumbers: hot,
      coldNumbers: cold,
      overdueNumbers: overdueResult['numbers'] as List<int>,
      overdueGap: overdueResult['gap'] as Map<int, int>,
      rangeDistribution: rangeDist,
      avgOddEvenRatio: oddEven,
      avgSum: avgSum,
      endDigitFrequency: endDigit,
      topPairs: pairs,
      topTriplets: triplets,
      consecutivePairCount: consecutive,
      recentTrend: trend,
      roundRecommendations: recommendations,
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

  Map<int, int> _calcBonusFrequency() {
    final freq = <int, int>{};
    for (int i = 1; i <= 45; i++) {
      freq[i] = 0;
    }
    for (final draw in draws) {
      freq[draw.bonus] = (freq[draw.bonus] ?? 0) + 1;
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
    return _getOverdueNumbersWithGap()['numbers'] as List<int>;
  }

  Map<String, dynamic> _getOverdueNumbersWithGap() {
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
    final overdueNumbers = entries.take(10).map((e) => e.key).toList()..sort();
    final gapMap = <int, int>{};
    for (final e in entries) {
      gapMap[e.key] = e.value;
    }
    return {'numbers': overdueNumbers, 'gap': gapMap};
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

  Map<int, int> _getEndDigitFrequency() {
    final freq = <int, int>{};
    for (int i = 0; i <= 9; i++) {
      freq[i] = 0;
    }
    for (final draw in draws) {
      for (final n in draw.numbers) {
        freq[n % 10] = (freq[n % 10] ?? 0) + 1;
      }
    }
    return freq;
  }

  List<MapEntry<String, int>> _getTopPairs() {
    final pairs = <String, int>{};
    for (final draw in draws) {
      final nums = draw.numbers;
      for (int i = 0; i < nums.length; i++) {
        for (int j = i + 1; j < nums.length; j++) {
          final key = '${nums[i]}-${nums[j]}';
          pairs[key] = (pairs[key] ?? 0) + 1;
        }
      }
    }
    final sorted = pairs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(15).toList();
  }

  List<MapEntry<String, int>> _getTopTriplets() {
    final triplets = <String, int>{};
    for (final draw in draws) {
      final nums = draw.numbers;
      for (int i = 0; i < nums.length; i++) {
        for (int j = i + 1; j < nums.length; j++) {
          for (int k = j + 1; k < nums.length; k++) {
            final key = '${nums[i]}-${nums[j]}-${nums[k]}';
            triplets[key] = (triplets[key] ?? 0) + 1;
          }
        }
      }
    }
    final sorted = triplets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).toList();
  }

  Map<int, int> _getConsecutivePairCount() {
    final counts = <int, int>{};
    for (final draw in draws) {
      int consecutive = 0;
      for (int i = 1; i < draw.numbers.length; i++) {
        if (draw.numbers[i] - draw.numbers[i - 1] == 1) {
          consecutive++;
        }
      }
      counts[consecutive] = (counts[consecutive] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, double> _getRecentTrend() {
    if (draws.length < 20) return {};
    final recent10 = draws.take(10).toList();
    final prev10 = draws.skip(10).take(10).toList();

    double recentAvgSum = 0;
    double prevAvgSum = 0;
    double recentOdd = 0;
    double prevOdd = 0;

    for (final d in recent10) {
      recentAvgSum += d.numbers.reduce((a, b) => a + b);
      recentOdd += d.numbers.where((n) => n % 2 == 1).length;
    }
    for (final d in prev10) {
      prevAvgSum += d.numbers.reduce((a, b) => a + b);
      prevOdd += d.numbers.where((n) => n % 2 == 1).length;
    }

    return {
      '최근10회 평균합': recentAvgSum / 10,
      '이전10회 평균합': prevAvgSum / 10,
      '최근10회 홀수비율': (recentOdd / 60) * 100,
      '이전10회 홀수비율': (prevOdd / 60) * 100,
    };
  }

  List<RecommendationSet> _generateRoundSets(
    Map<int, int> freq,
    List<int> hot,
    List<int> cold,
    List<int> overdue,
    Map<int, int> overdueGap,
    List<MapEntry<String, int>> topPairs,
    int targetRound,
  ) {
    final rng = Random(targetRound * 31 + DateTime.now().millisecondsSinceEpoch);
    final sets = <RecommendationSet>[];

    sets.add(RecommendationSet(
      strategy: '핫번호 집중',
      emoji: '🔥',
      numbers: _pickBalanced(hot, freq, rng),
      reason: '최근 50회 자주 출현한 번호 위주',
    ));

    sets.add(RecommendationSet(
      strategy: '콜드번호 반등',
      emoji: '❄️',
      numbers: _pickWithCold(cold, freq, rng),
      reason: '장기 미출현 번호의 반등 기대',
    ));

    sets.add(RecommendationSet(
      strategy: '핫+콜드 혼합',
      emoji: '🔄',
      numbers: _pickMixed(hot, overdue, freq, rng),
      reason: '핫번호와 장기미출현 번호를 균형 배합',
    ));

    sets.add(RecommendationSet(
      strategy: '구간 균형',
      emoji: '⚖️',
      numbers: _pickRangeBalanced(freq, rng),
      reason: '1~45를 5구간으로 나누어 균등 배분',
    ));

    sets.add(RecommendationSet(
      strategy: '빈도 가중 랜덤',
      emoji: '🎲',
      numbers: _pickWeightedRandom(freq, rng),
      reason: '역대 출현빈도에 비례한 확률 추첨',
    ));

    sets.add(RecommendationSet(
      strategy: '동반출현 기반',
      emoji: '🤝',
      numbers: _pickFromPairs(topPairs, freq, rng),
      reason: '자주 함께 나오는 번호 조합 활용',
    ));

    return sets;
  }

  List<int> _pickFromPairs(
    List<MapEntry<String, int>> topPairs,
    Map<int, int> freq,
    Random rng,
  ) {
    final picked = <int>{};
    final shuffledPairs = List<MapEntry<String, int>>.from(topPairs)..shuffle(rng);

    for (final pair in shuffledPairs) {
      if (picked.length >= 6) break;
      final parts = pair.key.split('-').map(int.parse).toList();
      for (final n in parts) {
        if (picked.length < 6) picked.add(n);
      }
    }

    while (picked.length < 6) {
      final n = rng.nextInt(45) + 1;
      if (!picked.contains(n)) picked.add(n);
    }

    final result = picked.take(6).toList()..sort();
    return result;
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
    for (final range in ranges) {
      range.shuffle(rng);
      picked.add(range.first);
    }
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

  List<List<int>> _generateRecommendations(
    Map<int, int> freq,
    List<int> hot,
    List<int> cold,
    List<int> overdue,
  ) {
    final rng = Random();
    return [
      _pickBalanced(hot, freq, rng),
      _pickWithCold(cold, freq, rng),
      _pickMixed(hot, overdue, freq, rng),
      _pickRangeBalanced(freq, rng),
      _pickWeightedRandom(freq, rng),
    ];
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
