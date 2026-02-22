class TripleluckDraw {
  final int round;
  final List<int> tripleNumbers; // 트리플 3개
  final List<int> luckNumbers; // 럭 3개

  const TripleluckDraw({
    required this.round,
    required this.tripleNumbers,
    required this.luckNumbers,
  });

  List<int> get allNumbers => [...tripleNumbers, ...luckNumbers];

  factory TripleluckDraw.fromJson(Map<String, dynamic> json) {
    final triple = <int>[];
    final luck = <int>[];
    for (int i = 1; i <= 3; i++) {
      final t = json['tripleNo$i'];
      if (t != null) triple.add(t is int ? t : int.parse(t.toString()));
      final l = json['luckNo$i'];
      if (l != null) luck.add(l is int ? l : int.parse(l.toString()));
    }
    return TripleluckDraw(
      round: json['drwNo'] as int,
      tripleNumbers: triple..sort(),
      luckNumbers: luck..sort(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'drwNo': round};
    for (int i = 0; i < tripleNumbers.length; i++) {
      map['tripleNo${i + 1}'] = tripleNumbers[i];
    }
    for (int i = 0; i < luckNumbers.length; i++) {
      map['luckNo${i + 1}'] = luckNumbers[i];
    }
    return map;
  }
}
