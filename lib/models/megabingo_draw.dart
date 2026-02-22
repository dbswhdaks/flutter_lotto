class MegabingoDraw {
  final int round;
  final List<int> numbers; // 추첨된 20개 번호

  const MegabingoDraw({
    required this.round,
    required this.numbers,
  });

  factory MegabingoDraw.fromJson(Map<String, dynamic> json) {
    final nums = <int>[];
    for (int i = 1; i <= 20; i++) {
      final v = json['No$i'];
      if (v != null) nums.add(v is int ? v : int.parse(v.toString()));
    }
    return MegabingoDraw(
      round: json['drwNo'] as int,
      numbers: nums..sort(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'drwNo': round};
    for (int i = 0; i < numbers.length; i++) {
      map['No${i + 1}'] = numbers[i];
    }
    return map;
  }
}
