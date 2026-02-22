class PensionDraw {
  final int round;
  final int group;
  final List<int> digits;
  final int? bonusGroup;
  final List<int>? bonusDigits;

  const PensionDraw({
    required this.round,
    required this.group,
    required this.digits,
    this.bonusGroup,
    this.bonusDigits,
  });

  factory PensionDraw.fromJson(Map<String, dynamic> json) {
    return PensionDraw(
      round: json['drwNo'] as int,
      group: _parseInt(json, 'pensionGroup'),
      digits: [
        _parseInt(json, 'pensionNo1'),
        _parseInt(json, 'pensionNo2'),
        _parseInt(json, 'pensionNo3'),
        _parseInt(json, 'pensionNo4'),
        _parseInt(json, 'pensionNo5'),
        _parseInt(json, 'pensionNo6'),
      ],
      bonusGroup: _tryParseInt(json, 'bonusGroup'),
      bonusDigits: _tryParseBonusDigits(json),
    );
  }

  static int _parseInt(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is int) return v;
    if (v is String) return int.parse(v);
    return 0;
  }

  static int? _tryParseInt(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  static List<int>? _tryParseBonusDigits(Map<String, dynamic> json) {
    if (json['bonusNo1'] == null) return null;
    return [
      _parseInt(json, 'bonusNo1'),
      _parseInt(json, 'bonusNo2'),
      _parseInt(json, 'bonusNo3'),
      _parseInt(json, 'bonusNo4'),
      _parseInt(json, 'bonusNo5'),
      _parseInt(json, 'bonusNo6'),
    ];
  }

  Map<String, dynamic> toJson() => {
        'drwNo': round,
        'pensionGroup': group,
        'pensionNo1': digits[0],
        'pensionNo2': digits[1],
        'pensionNo3': digits[2],
        'pensionNo4': digits[3],
        'pensionNo5': digits[4],
        'pensionNo6': digits[5],
        if (bonusGroup != null) 'bonusGroup': bonusGroup,
        if (bonusDigits != null) ...{
          'bonusNo1': bonusDigits![0],
          'bonusNo2': bonusDigits![1],
          'bonusNo3': bonusDigits![2],
          'bonusNo4': bonusDigits![3],
          'bonusNo5': bonusDigits![4],
          'bonusNo6': bonusDigits![5],
        },
      };

  String get formattedNumber => digits.join();
  String get fullDisplay => '$group조 ${digits.join()}';
}
