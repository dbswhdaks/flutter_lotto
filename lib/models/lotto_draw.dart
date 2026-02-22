class LottoDraw {
  final int round;
  final List<int> numbers;
  final int bonus;
  final String? date;

  const LottoDraw({
    required this.round,
    required this.numbers,
    required this.bonus,
    this.date,
  });

  factory LottoDraw.fromJson(Map<String, dynamic> json) {
    return LottoDraw(
      round: json['drwNo'] as int,
      numbers: [
        json['drwtNo1'] as int,
        json['drwtNo2'] as int,
        json['drwtNo3'] as int,
        json['drwtNo4'] as int,
        json['drwtNo5'] as int,
        json['drwtNo6'] as int,
      ]..sort(),
      bonus: json['bnusNo'] as int,
      date: json['drwNoDate'] as String?,
    );
  }

  List<int> get allNumbers => [...numbers, bonus];
}
