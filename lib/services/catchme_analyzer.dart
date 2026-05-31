import 'dart:math';
import '../models/catchme_draw.dart';
import '../utils/recommendation_scoring.dart';

class CatchmeAnalysisResult {
  final Map<int, int> frequency;
  final List<int> hotNumbers;
  final List<int> coldNumbers;
  final List<int> overdueNumbers;
  final Map<String, double> rangeDistribution;
  final List<CatchmeRecommendation> recommendations;
  final int totalDraws;

  const CatchmeAnalysisResult({
    required this.frequency,
    required this.hotNumbers,
    required this.coldNumbers,
    required this.overdueNumbers,
    required this.rangeDistribution,
    required this.recommendations,
    required this.totalDraws,
  });
}

class CatchmeRecommendation {
  final String strategy;
  final String icon;
  final int number;

  const CatchmeRecommendation({
    required this.strategy,
    required this.icon,
    required this.number,
  });
}

class CatchmeAnalyzer {
  final List<CatchmeDraw> draws;

  CatchmeAnalyzer(this.draws);

  CatchmeAnalysisResult analyze() {
    final freq = _calcFrequency();
    final hot = _getHotNumbers(recentCount: 30);
    final cold = _getColdNumbers(recentCount: 30);
    final overdue = _getOverdueNumbers();
    final range = _getRangeDistribution();
    final recs = _generateRecommendations(freq, hot, cold, overdue);

    return CatchmeAnalysisResult(
      frequency: freq,
      hotNumbers: hot,
      coldNumbers: cold,
      overdueNumbers: overdue,
      rangeDistribution: range,
      recommendations: recs,
      totalDraws: draws.length,
    );
  }

  Map<int, int> _calcFrequency() {
    final freq = {for (int i = 1; i <= 45; i++) i: 0};
    for (final d in draws) {
      freq[d.drawnNumber] = (freq[d.drawnNumber] ?? 0) + 1;
    }
    return freq;
  }

  List<int> _getHotNumbers({int recentCount = 30}) {
    final recent = draws.take(recentCount).toList();
    final freq = <int, int>{};
    for (final d in recent) {
      freq[d.drawnNumber] = (freq[d.drawnNumber] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).map((e) => e.key).toList()..sort();
  }

  List<int> _getColdNumbers({int recentCount = 30}) {
    final recent = draws.take(recentCount).toList();
    final appeared = <int>{};
    for (final d in recent) {
      appeared.add(d.drawnNumber);
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
      if (lastSeen[draws[i].drawnNumber] == -1) {
        lastSeen[draws[i].drawnNumber] = i;
      }
    }
    final entries = lastSeen.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(8).map((e) => e.key).toList()..sort();
  }

  Map<String, double> _getRangeDistribution() {
    if (draws.isEmpty) return {};
    final ranges = {'1-9': 0, '10-18': 0, '19-27': 0, '28-36': 0, '37-45': 0};
    for (final d in draws) {
      final n = d.drawnNumber;
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
    final total = draws.length.toDouble();
    return ranges.map((k, v) => MapEntry(k, total > 0 ? v / total * 100 : 0));
  }

  List<CatchmeRecommendation> _generateRecommendations(
    Map<int, int> freq,
    List<int> hot,
    List<int> cold,
    List<int> overdue,
  ) {
    final rng = Random();
    CatchmeRecommendation improve(CatchmeRecommendation Function() picker) {
      return RecommendationScoring.bestCandidate(
        rng: rng,
        picker: picker,
        score: (rec) =>
            _scoreRecommendation(rec, freq, hot.toSet(), overdue.toSet()),
        attempts: 40,
      );
    }

    return [
      improve(() => _hotStrategy(hot, rng)),
      improve(() => _coldStrategy(cold, rng)),
      improve(() => _overdueStrategy(overdue, rng)),
      improve(() => _topFreqStrategy(freq)),
      improve(() => _weightedRandomStrategy(freq, rng)),
    ];
  }

  double _scoreRecommendation(
    CatchmeRecommendation rec,
    Map<int, int> freq,
    Set<int> hot,
    Set<int> overdue,
  ) {
    final maxFrequency = freq.values.isEmpty ? 1 : freq.values.reduce(max);
    final frequencyScore =
        (freq[rec.number] ?? 0) / (maxFrequency == 0 ? 1 : maxFrequency);
    final centerPenalty = (rec.number - 23).abs() * 0.05;
    final hotBonus = hot.contains(rec.number) ? 2.5 : 0;
    final overdueBonus = overdue.contains(rec.number) ? 1.5 : 0;

    return frequencyScore * 10 + hotBonus + overdueBonus - centerPenalty;
  }

  CatchmeRecommendation _hotStrategy(List<int> hot, Random rng) {
    final pick = hot.isNotEmpty
        ? hot[rng.nextInt(hot.length)]
        : rng.nextInt(45) + 1;
    return CatchmeRecommendation(
      strategy: '핫번호 중 랜덤',
      icon: '🔥',
      number: pick,
    );
  }

  CatchmeRecommendation _coldStrategy(List<int> cold, Random rng) {
    final pick = cold.isNotEmpty
        ? cold[rng.nextInt(cold.length)]
        : rng.nextInt(45) + 1;
    return CatchmeRecommendation(
      strategy: '콜드번호 반전 노림',
      icon: '❄️',
      number: pick,
    );
  }

  CatchmeRecommendation _overdueStrategy(List<int> overdue, Random rng) {
    final pick = overdue.isNotEmpty
        ? overdue[rng.nextInt(overdue.length)]
        : rng.nextInt(45) + 1;
    return CatchmeRecommendation(strategy: '장기미출현 번호', icon: '⏰', number: pick);
  }

  CatchmeRecommendation _topFreqStrategy(Map<int, int> freq) {
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return CatchmeRecommendation(
      strategy: '최다 출현 1위',
      icon: '👑',
      number: sorted.first.key,
    );
  }

  CatchmeRecommendation _weightedRandomStrategy(
    Map<int, int> freq,
    Random rng,
  ) {
    final maxF = freq.values.reduce(max).toDouble();
    for (int a = 0; a < 500; a++) {
      final n = rng.nextInt(45) + 1;
      final w = (freq[n] ?? 0) / (maxF > 0 ? maxF : 1);
      if (rng.nextDouble() < w + 0.2) {
        return CatchmeRecommendation(
          strategy: '빈도 가중 랜덤',
          icon: '🎲',
          number: n,
        );
      }
    }
    return CatchmeRecommendation(
      strategy: '빈도 가중 랜덤',
      icon: '🎲',
      number: rng.nextInt(45) + 1,
    );
  }
}
