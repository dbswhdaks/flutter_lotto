class CatchmeDraw {
  final int round;
  final int drawnNumber;

  const CatchmeDraw({
    required this.round,
    required this.drawnNumber,
  });

  factory CatchmeDraw.fromJson(Map<String, dynamic> json) {
    final n = json['No1'];
    return CatchmeDraw(
      round: json['drwNo'] as int,
      drawnNumber: n is int ? n : int.parse(n.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'drwNo': round,
        'No1': drawnNumber,
      };
}
