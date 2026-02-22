class DoublejackDraw {
  final int round;
  final List<int> jackNumbers; // 잭 6개
  final List<int> midasNumbers; // 마이더스 6개

  const DoublejackDraw({
    required this.round,
    required this.jackNumbers,
    required this.midasNumbers,
  });

  List<int> get allNumbers => [...jackNumbers, ...midasNumbers];

  factory DoublejackDraw.fromJson(Map<String, dynamic> json) {
    final jack = <int>[];
    final midas = <int>[];
    for (int i = 1; i <= 6; i++) {
      final j = json['jackNo$i'];
      if (j != null) jack.add(j is int ? j : int.parse(j.toString()));
      final m = json['midasNo$i'];
      if (m != null) midas.add(m is int ? m : int.parse(m.toString()));
    }
    return DoublejackDraw(
      round: json['drwNo'] as int,
      jackNumbers: jack..sort(),
      midasNumbers: midas..sort(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'drwNo': round};
    for (int i = 0; i < jackNumbers.length; i++) {
      map['jackNo${i + 1}'] = jackNumbers[i];
    }
    for (int i = 0; i < midasNumbers.length; i++) {
      map['midasNo${i + 1}'] = midasNumbers[i];
    }
    return map;
  }
}
