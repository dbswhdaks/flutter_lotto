import 'package:flutter/material.dart';
import '../models/pension_winning_detail.dart';
import '../services/pension_winning_service.dart';

class PensionWinningPage extends StatefulWidget {
  const PensionWinningPage({super.key});

  @override
  State<PensionWinningPage> createState() => _PensionWinningPageState();
}

class _PensionWinningPageState extends State<PensionWinningPage> {
  final PensionWinningService _service = PensionWinningService();
  final TextEditingController _roundController = TextEditingController();

  int _selectedRound = PensionWinningService.calcLatestDrawnRound();
  PensionWinningDetail? _detail;
  bool _loading = false;
  String? _errorMessage;

  static const Color _accent = Color(0xFFFFB347);

  @override
  void initState() {
    super.initState();
    _roundController.text = _selectedRound.toString();
    _loadLatest();
  }

  @override
  void dispose() {
    _roundController.dispose();
    super.dispose();
  }

  Future<void> _loadLatest() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final detail = await _service.fetchLatest();
    if (!mounted) return;

    if (detail == null) {
      setState(() {
        _loading = false;
        _errorMessage = '당첨번호 데이터를 불러올 수 없습니다\n(네트워크 연결을 확인해주세요)';
      });
      return;
    }

    setState(() {
      _detail = detail;
      _selectedRound = detail.round;
      _roundController.text = detail.round.toString();
      _loading = false;
    });
  }

  Future<void> _loadRound(int round) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final detail = await _service.fetch(round);
    if (!mounted) return;

    if (detail == null || !detail.isValid) {
      setState(() {
        _loading = false;
        _errorMessage = '$round회 데이터를 불러올 수 없습니다\n(아직 추첨 전이거나 존재하지 않는 회차입니다)';
      });
      return;
    }

    setState(() {
      _detail = detail;
      _selectedRound = detail.round;
      _roundController.text = detail.round.toString();
      _loading = false;
    });
  }

  void _goPrev() {
    if (_selectedRound <= 1) return;
    _loadRound(_selectedRound - 1);
  }

  void _goNext() => _loadRound(_selectedRound + 1);

  void _goLatest() => _loadLatest();

  void _submitRound() {
    final v = int.tryParse(_roundController.text.trim());
    if (v == null || v < 1) {
      setState(() => _errorMessage = '올바른 회차를 입력하세요');
      return;
    }
    _loadRound(v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B0F1F),
                  Color(0xFF111935),
                  Color(0xFF0A1F3D),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRoundSelector(),
                        const SizedBox(height: 16),
                        _buildWinningCard(),
                        const SizedBox(height: 16),
                        _buildRankGuide(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              '연금복권 당첨번호',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _navBtn(Icons.chevron_left_rounded, onTap: _goPrev),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _roundController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '회차 입력',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                suffixText: '회',
                suffixStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                ),
              ),
              onSubmitted: (_) => _submitRound(),
            ),
          ),
          const SizedBox(width: 8),
          _navBtn(Icons.chevron_right_rounded, onTap: _goNext),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _goLatest,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: _accent.withValues(alpha: 0.20),
                border: Border.all(color: _accent.withValues(alpha: 0.55)),
              ),
              child: const Text(
                '최신',
                style: TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.02),
        ],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildWinningCard() {
    if (_loading) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: _cardDecoration(),
        child: const CircularProgressIndicator(color: _accent),
      );
    }

    if (_errorMessage != null && _detail == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent.withValues(alpha: 0.85),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final d = _detail;
    if (d == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8C00), Color(0xFFFFD700)],
                  ),
                ),
                child: Text(
                  '${d.round}회',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (d.date != null)
                Text(
                  d.date!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _buildFirstRankRow(d),
          const SizedBox(height: 18),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 16),
          _buildBonusRow(d),
        ],
      ),
    );
  }

  Widget _buildFirstRankRow(PensionWinningDetail d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: _accent,
              size: 16,
            ),
            const SizedBox(width: 6),
            const Text(
              '1등 당첨번호',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            // 조1개 + 구분자('-') + 번호6개 = 총 7개 슬롯 + 갭
            const dividerWidth = 14.0;
            const gaps = 6 * 4;
            final ballSize =
                ((constraints.maxWidth - dividerWidth - gaps) / 7).clamp(
                  30.0,
                  42.0,
                );
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PensionBall(
                    digit: d.group,
                    size: ballSize,
                    kind: _BallKind.group,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '-',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  for (int i = 0; i < d.numbers.length; i++) ...[
                    _PensionBall(
                      digit: d.numbers[i],
                      size: ballSize,
                      kind: _BallKind.normal,
                    ),
                    if (i != d.numbers.length - 1) const SizedBox(width: 4),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          '조 1개 + 각 자리 번호 6개 (좌 → 우)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBonusRow(PensionWinningDetail d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.stars_rounded,
              color: Color(0xFF4FD1C5),
              size: 16,
            ),
            const SizedBox(width: 6),
            const Text(
              '보너스 당첨번호',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFF4FD1C5).withValues(alpha: 0.18),
              ),
              child: const Text(
                '매주 5명',
                style: TextStyle(
                  color: Color(0xFF4FD1C5),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const gaps = 5 * 4;
            final ballSize = ((constraints.maxWidth - gaps) / 6).clamp(
              30.0,
              42.0,
            );
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < d.bonusNumbers.length; i++) ...[
                    _PensionBall(
                      digit: d.bonusNumbers[i],
                      size: ballSize,
                      kind: _BallKind.bonus,
                    ),
                    if (i != d.bonusNumbers.length - 1)
                      const SizedBox(width: 4),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRankGuide() {
    final d = _detail;

    final rows = <_RankRow>[
      _RankRow(
        '1등',
        '조 + 6자리 전체 일치',
        '매월 700만원 × 20년',
        d?.first.winnerCount,
      ),
      _RankRow(
        '2등',
        '조 제외 6자리 일치',
        '매월 100만원 × 10년',
        d?.second.winnerCount,
      ),
      _RankRow('3등', '뒤 5자리 일치', '100만원', d?.third.winnerCount),
      _RankRow('4등', '뒤 4자리 일치', '10만원', d?.fourth.winnerCount),
      _RankRow('5등', '뒤 3자리 일치', '5만원', d?.fifth.winnerCount),
      _RankRow('6등', '뒤 2자리 일치', '5천원', d?.sixth.winnerCount),
      _RankRow('7등', '뒤 1자리 일치', '1천원', d?.seventh.winnerCount),
      _RankRow(
        '보너스',
        '보너스 6자리 일치',
        '매월 100만원 × 10년',
        d?.bonus.winnerCount,
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: _accent,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                '등수별 당첨 정보',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (d != null)
                Text(
                  '${d.round}회',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < rows.length; i++) ...[
            _rankInfoRow(rows[i]),
            if (i != rows.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _rankInfoRow(_RankRow r) {
    final isBonus = r.rank == '보너스';
    final labelColor = isBonus ? const Color(0xFF4FD1C5) : _accent;
    return Row(
      children: [
        Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: labelColor.withValues(alpha: 0.18),
          ),
          child: Text(
            r.rank,
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.condition,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (r.winnerCount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '당첨 ${_formatCount(r.winnerCount!)}명',
                    style: TextStyle(
                      color: labelColor.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Text(
          r.prize,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _RankRow {
  final String rank;
  final String condition;
  final String prize;
  final int? winnerCount;
  const _RankRow(this.rank, this.condition, this.prize, this.winnerCount);
}

enum _BallKind { group, normal, bonus }

class _PensionBall extends StatelessWidget {
  final int digit;
  final double size;
  final _BallKind kind;

  const _PensionBall({
    required this.digit,
    required this.size,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    late final List<Color> gradient;
    late final Color glow;
    late final Color textColor;

    switch (kind) {
      case _BallKind.group:
        gradient = const [Color(0xFFFF8C00), Color(0xFFFFB347)];
        glow = const Color(0xFFFF8C00);
        textColor = Colors.white;
        break;
      case _BallKind.normal:
        gradient = const [Color(0xFFFFD700), Color(0xFFFFB347)];
        glow = const Color(0xFFFFB347);
        textColor = const Color(0xFF3A2A00);
        break;
      case _BallKind.bonus:
        gradient = const [Color(0xFF4FD1C5), Color(0xFF38B2AC)];
        glow = const Color(0xFF4FD1C5);
        textColor = Colors.white;
        break;
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        border: kind == _BallKind.bonus
            ? Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.45),
            blurRadius: 10,
            spreadRadius: -1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '$digit',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.48,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
