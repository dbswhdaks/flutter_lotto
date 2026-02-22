import 'dart:math';
import '../models/pension_draw.dart';

class PensionAnalysisResult {
  final Map<int, int> groupFrequency;
  final List<Map<int, int>> digitFrequency;
  final List<List<int>> hotDigits;
  final List<List<int>> coldDigits;
  final List<PensionRecommendation> recommendations;
  final int totalDraws;

  const PensionAnalysisResult({
    required this.groupFrequency,
    required this.digitFrequency,
    required this.hotDigits,
    required this.coldDigits,
    required this.recommendations,
    required this.totalDraws,
  });
}

class PensionRecommendation {
  final String strategy;
  final String icon;
  final int group;
  final List<int> digits;

  const PensionRecommendation({
    required this.strategy,
    required this.icon,
    required this.group,
    required this.digits,
  });

  String get fullDisplay => '$group조 ${digits.join()}';
}

class PensionAnalyzer {
  final List<PensionDraw> draws;

  PensionAnalyzer(this.draws);

  PensionAnalysisResult analyze() {
    final groupFreq = _calcGroupFrequency();
    final digitFreq = _calcDigitFrequency();
    final hot = _getHotDigits(recentCount: 30);
    final cold = _getColdDigits(recentCount: 30);
    final recs = _generateRecommendations(groupFreq, digitFreq, hot, cold);

    return PensionAnalysisResult(
      groupFrequency: groupFreq,
      digitFrequency: digitFreq,
      hotDigits: hot,
      coldDigits: cold,
      recommendations: recs,
      totalDraws: draws.length,
    );
  }

  Map<int, int> _calcGroupFrequency() {
    final freq = {for (int i = 1; i <= 5; i++) i: 0};
    for (final draw in draws) {
      freq[draw.group] = (freq[draw.group] ?? 0) + 1;
    }
    return freq;
  }

  /// 각 자릿수(0~5) 별로 숫자(0~9)의 출현 빈도
  List<Map<int, int>> _calcDigitFrequency() {
    return List.generate(6, (pos) {
      final freq = {for (int d = 0; d <= 9; d++) d: 0};
      for (final draw in draws) {
        final digit = draw.digits[pos];
        freq[digit] = (freq[digit] ?? 0) + 1;
      }
      return freq;
    });
  }

  /// 각 자릿수별 최근 N회에서 자주 출현한 숫자 상위 3개
  List<List<int>> _getHotDigits({int recentCount = 30}) {
    final recent = draws.take(recentCount).toList();
    return List.generate(6, (pos) {
      final freq = <int, int>{};
      for (final draw in recent) {
        final d = draw.digits[pos];
        freq[d] = (freq[d] ?? 0) + 1;
      }
      final sorted = freq.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sorted.take(3).map((e) => e.key).toList();
    });
  }

  /// 각 자릿수별 최근 N회에서 출현하지 않은 숫자
  List<List<int>> _getColdDigits({int recentCount = 30}) {
    final recent = draws.take(recentCount).toList();
    return List.generate(6, (pos) {
      final appeared = <int>{};
      for (final draw in recent) {
        appeared.add(draw.digits[pos]);
      }
      final cold = <int>[];
      for (int d = 0; d <= 9; d++) {
        if (!appeared.contains(d)) cold.add(d);
      }
      return cold;
    });
  }

  List<PensionRecommendation> _generateRecommendations(
    Map<int, int> groupFreq,
    List<Map<int, int>> digitFreq,
    List<List<int>> hot,
    List<List<int>> cold,
  ) {
    final rng = Random();
    return [
      _hotStrategy(groupFreq, hot, rng),
      _coldStrategy(groupFreq, cold, digitFreq, rng),
      _balancedStrategy(groupFreq, digitFreq, rng),
      _frequencyWeightedStrategy(groupFreq, digitFreq, rng),
      _patternStrategy(groupFreq, digitFreq, rng),
    ];
  }

  /// 전략 1: 핫 숫자 중심 - 최근 자주 나온 숫자 위주
  PensionRecommendation _hotStrategy(
    Map<int, int> groupFreq,
    List<List<int>> hot,
    Random rng,
  ) {
    final group = _pickTopGroup(groupFreq, rng);
    final digits = List.generate(6, (pos) {
      final candidates = hot[pos];
      return candidates[rng.nextInt(candidates.length)];
    });
    return PensionRecommendation(
      strategy: '핫번호 중심',
      icon: '🔥',
      group: group,
      digits: digits,
    );
  }

  /// 전략 2: 콜드 숫자 포함 - 안 나온 번호가 나올 때
  PensionRecommendation _coldStrategy(
    Map<int, int> groupFreq,
    List<List<int>> cold,
    List<Map<int, int>> digitFreq,
    Random rng,
  ) {
    final group = _pickLeastGroup(groupFreq, rng);
    final digits = List.generate(6, (pos) {
      if (cold[pos].isNotEmpty && rng.nextBool()) {
        return cold[pos][rng.nextInt(cold[pos].length)];
      }
      return _pickWeightedDigit(digitFreq[pos], rng);
    });
    return PensionRecommendation(
      strategy: '콜드번호 포함',
      icon: '❄️',
      group: group,
      digits: digits,
    );
  }

  /// 전략 3: 균형 전략 - 각 자릿수에서 고르게 분포
  PensionRecommendation _balancedStrategy(
    Map<int, int> groupFreq,
    List<Map<int, int>> digitFreq,
    Random rng,
  ) {
    final group = _pickTopGroup(groupFreq, rng);
    final digits = List.generate(6, (pos) {
      final freq = digitFreq[pos];
      final sorted = freq.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final midRange = sorted.sublist(
        (sorted.length * 0.2).floor(),
        (sorted.length * 0.8).ceil(),
      );
      return midRange[rng.nextInt(midRange.length)].key;
    });
    return PensionRecommendation(
      strategy: '균형 전략',
      icon: '⚖️',
      group: group,
      digits: digits,
    );
  }

  /// 전략 4: 빈도 가중 랜덤 - 출현 빈도에 비례한 확률
  PensionRecommendation _frequencyWeightedStrategy(
    Map<int, int> groupFreq,
    List<Map<int, int>> digitFreq,
    Random rng,
  ) {
    final group = _pickWeightedGroup(groupFreq, rng);
    final digits = List.generate(6, (pos) {
      return _pickWeightedDigit(digitFreq[pos], rng);
    });
    return PensionRecommendation(
      strategy: '빈도 가중 랜덤',
      icon: '🎲',
      group: group,
      digits: digits,
    );
  }

  /// 전략 5: 패턴 분석 - 홀짝/고저 균형
  PensionRecommendation _patternStrategy(
    Map<int, int> groupFreq,
    List<Map<int, int>> digitFreq,
    Random rng,
  ) {
    final group = _pickTopGroup(groupFreq, rng);
    final digits = <int>[];
    for (int pos = 0; pos < 6; pos++) {
      final needOdd = digits.where((d) => d % 2 == 1).length < 3;
      final needEven = digits.where((d) => d % 2 == 0).length < 3;
      final freq = digitFreq[pos];
      final sorted = freq.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      int picked = sorted.first.key;
      for (final e in sorted) {
        if (needOdd && e.key % 2 == 1) {
          picked = e.key;
          break;
        }
        if (needEven && e.key % 2 == 0) {
          picked = e.key;
          break;
        }
      }
      digits.add(picked);
    }
    return PensionRecommendation(
      strategy: '홀짝 균형 패턴',
      icon: '🔄',
      group: group,
      digits: digits,
    );
  }

  int _pickTopGroup(Map<int, int> freq, Random rng) {
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(2).toList();
    return top[rng.nextInt(top.length)].key;
  }

  int _pickLeastGroup(Map<int, int> freq, Random rng) {
    final sorted = freq.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final bottom = sorted.take(2).toList();
    return bottom[rng.nextInt(bottom.length)].key;
  }

  int _pickWeightedGroup(Map<int, int> freq, Random rng) {
    final total = freq.values.fold(0, (a, b) => a + b);
    if (total == 0) return rng.nextInt(5) + 1;
    var r = rng.nextInt(total);
    for (final e in freq.entries) {
      r -= e.value;
      if (r < 0) return e.key;
    }
    return freq.keys.first;
  }

  int _pickWeightedDigit(Map<int, int> freq, Random rng) {
    final total = freq.values.fold(0, (a, b) => a + b);
    if (total == 0) return rng.nextInt(10);
    var r = rng.nextInt(total);
    for (final e in freq.entries) {
      r -= e.value;
      if (r < 0) return e.key;
    }
    return freq.keys.first;
  }
}
