class PowerballDraw {
  final int round;
  final List<int> numbers;
  final int powerball;

  const PowerballDraw({
    required this.round,
    required this.numbers,
    required this.powerball,
  });

  factory PowerballDraw.fromJson(Map<String, dynamic> json) {
    return PowerballDraw(
      round: json['drwNo'] as int,
      numbers: [
        json['No1'] as int,
        json['No2'] as int,
        json['No3'] as int,
        json['No4'] as int,
        json['No5'] as int,
      ]..sort(),
      powerball: json['pBall'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'drwNo': round,
        'No1': numbers[0],
        'No2': numbers[1],
        'No3': numbers[2],
        'No4': numbers[3],
        'No5': numbers[4],
        'pBall': powerball,
      };
}
