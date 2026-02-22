class TreasureDraw {
  final int round;
  final List<int> numbers; // 일반 번호 6개
  final int treasureNumber; // 보물번호

  const TreasureDraw({
    required this.round,
    required this.numbers,
    required this.treasureNumber,
  });

  factory TreasureDraw.fromJson(Map<String, dynamic> json) {
    final nums = <int>[];
    for (int i = 1; i <= 6; i++) {
      final v = json['No$i'];
      if (v != null) nums.add(v is int ? v : int.parse(v.toString()));
    }
    final treasure = json['treasureNo'];
    return TreasureDraw(
      round: json['drwNo'] as int,
      numbers: nums..sort(),
      treasureNumber:
          treasure is int ? treasure : int.parse(treasure.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'drwNo': round};
    for (int i = 0; i < numbers.length; i++) {
      map['No${i + 1}'] = numbers[i];
    }
    map['treasureNo'] = treasureNumber;
    return map;
  }
}
