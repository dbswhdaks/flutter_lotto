import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/winning_number_detail.dart';
import '../services/winning_number_service.dart';
import '../widgets/lotto_ball.dart';

class WinningNumberPage extends StatefulWidget {
  const WinningNumberPage({super.key});

  @override
  State<WinningNumberPage> createState() => _WinningNumberPageState();
}

class _WinningNumberPageState extends State<WinningNumberPage> {
  final WinningNumberService _service = WinningNumberService();
  final TextEditingController _roundController = TextEditingController();

  int _selectedRound = WinningNumberService.calcLatestDrawnRound();
  WinningNumberDetail? _detail;
  bool _loading = false;
  String? _errorMessage;
  LottoQrResult? _qrResult;

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

  /// 앱 시작 시: 추정 최신 회차부터 뒤로 폴백하며 실제 데이터가 있는 회차를 로드
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

    if (detail == null) {
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

  void _goNext() {
    _loadRound(_selectedRound + 1);
  }

  void _goLatest() {
    _loadLatest();
  }

  void _submitRound() {
    final v = int.tryParse(_roundController.text.trim());
    if (v == null || v < 1) {
      setState(() => _errorMessage = '올바른 회차를 입력하세요');
      return;
    }
    _loadRound(v);
  }

  Future<void> _openQrScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrScannerPage()),
    );

    if (result == null || !mounted) return;

    final parsed = WinningNumberService.parseQr(result);
    if (parsed == null) {
      setState(() {
        _qrResult = null;
        _errorMessage = 'QR 코드를 인식할 수 없습니다';
      });
      return;
    }

    setState(() {
      _qrResult = parsed;
      _errorMessage = null;
    });

    // 사용자 QR 회차의 당첨번호를 자동으로 조회
    if (parsed.round != _selectedRound) {
      await _loadRound(parsed.round);
    }
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
                        _buildPrizeCard(),
                        const SizedBox(height: 16),
                        _buildRankGuide(),
                        const SizedBox(height: 20),
                        _buildQrSection(),
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
              '당첨번호 확인',
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
                color: const Color(0xFFF5A623).withValues(alpha: 0.20),
                border: Border.all(
                  color: const Color(0xFFF5A623).withValues(alpha: 0.55),
                ),
              ),
              child: const Text(
                '최신',
                style: TextStyle(
                  color: Color(0xFFF5A623),
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

  Widget _buildWinningCard() {
    if (_loading) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: _cardDecoration(),
        child: const CircularProgressIndicator(color: Color(0xFFF5A623)),
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
                    colors: [Color(0xFFF5A623), Color(0xFFFF8A65)],
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
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // 7개 볼 + 5개 볼사이 갭(4px) + "+"영역(약 24px) + 안전여유(8px)
              const nonBallWidth = 5 * 4 + 24 + 8;
              final ballSize = ((constraints.maxWidth - nonBallWidth) / 7)
                  .clamp(30.0, 42.0);
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final n in d.numbers) ...[
                      LottoBall(number: n, size: ballSize),
                      if (n != d.numbers.last) const SizedBox(width: 4),
                    ],
                    const SizedBox(width: 4),
                    Text(
                      '+',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    LottoBall(number: d.bonus, size: ballSize, isBonus: true),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            '보너스 번호는 오른쪽 흰색 테두리 볼입니다',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeCard() {
    final d = _detail;
    if (d == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFF5A623),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                '등수별 당첨 정보',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _rankRow('1등', d.firstWinnerCount, d.firstWinAmount, highlight: true),
          const SizedBox(height: 6),
          _rankRow('2등', d.secondWinnerCount, d.secondWinAmount),
          const SizedBox(height: 6),
          _rankRow('3등', d.thirdWinnerCount, d.thirdWinAmount),
          const SizedBox(height: 6),
          _rankRow('4등', d.fourthWinnerCount, d.fourthWinAmount),
          const SizedBox(height: 6),
          _rankRow('5등', d.fifthWinnerCount, d.fifthWinAmount),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 판매금액',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _formatWon(d.totalSellAmount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rankRow(
    String rank,
    int winners,
    int amount, {
    bool highlight = false,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          padding: const EdgeInsets.symmetric(vertical: 3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: highlight
                ? const Color(0xFFF5A623).withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.06),
          ),
          child: Text(
            rank,
            style: TextStyle(
              color: highlight ? const Color(0xFFF5A623) : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$winners명',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          _formatWon(amount),
          style: TextStyle(
            color: highlight ? const Color(0xFFF5A623) : Colors.white,
            fontSize: highlight ? 14 : 12,
            fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildRankGuide() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.rule_rounded,
                color: Color(0xFF4FD1C5),
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                '등수별 당첨 조건',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _guideRow(
            rank: '1등',
            title: '6개 번호 모두 일치',
            description: '추첨된 6개의 당첨번호와 완벽하게 동일',
            matches: 6,
            withBonus: false,
            highlight: true,
          ),
          const SizedBox(height: 10),
          _guideRow(
            rank: '2등',
            title: '5개 번호 + 보너스 번호 일치',
            description: '6개 중 5개가 일치하고, 남은 1개가 보너스 번호와 동일',
            matches: 5,
            withBonus: true,
          ),
          const SizedBox(height: 10),
          _guideRow(
            rank: '3등',
            title: '5개 번호 일치',
            description: '6개 중 5개가 당첨번호와 일치 (보너스 미포함)',
            matches: 5,
            withBonus: false,
          ),
          const SizedBox(height: 10),
          _guideRow(
            rank: '4등',
            title: '4개 번호 일치',
            description: '6개 중 4개가 당첨번호와 일치',
            matches: 4,
            withBonus: false,
          ),
          const SizedBox(height: 10),
          _guideRow(
            rank: '5등',
            title: '3개 번호 일치',
            description: '6개 중 3개가 당첨번호와 일치',
            matches: 3,
            withBonus: false,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF4FD1C5).withValues(alpha: 0.08),
              border: Border.all(
                color: const Color(0xFF4FD1C5).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: const Color(0xFF4FD1C5).withValues(alpha: 0.85),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '4·5등 당첨금은 회차와 무관하게 각각 50,000원 / 5,000원 고정, '
                    '1~3등은 판매금액과 당첨자 수에 따라 매회 변동됩니다.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
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

  Widget _guideRow({
    required String rank,
    required String title,
    required String description,
    required int matches,
    required bool withBonus,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: highlight
            ? const Color(0xFFF5A623).withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: highlight
              ? const Color(0xFFF5A623).withValues(alpha: 0.40)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                padding: const EdgeInsets.symmetric(vertical: 3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: highlight
                      ? const LinearGradient(
                          colors: [Color(0xFFF5A623), Color(0xFFFF8A65)],
                        )
                      : null,
                  color: highlight
                      ? null
                      : Colors.white.withValues(alpha: 0.06),
                ),
                child: Text(
                  rank,
                  style: TextStyle(
                    color: highlight ? Colors.white : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _guideDots(matches: matches, withBonus: withBonus),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideDots({required int matches, required bool withBonus}) {
    Widget dot({required bool matched, bool bonus = false}) {
      return Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: matched
              ? const Color(0xFFF5A623)
              : Colors.white.withValues(alpha: 0.12),
          border: bonus
              ? Border.all(color: Colors.white, width: 1.4)
              : null,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 6; i++) dot(matched: i < matches),
        if (withBonus) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              '+',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          dot(matched: true, bonus: true),
        ],
      ],
    );
  }

  Widget _buildQrSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFF4FD1C5), Color(0xFF3B82F6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4FD1C5).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openQrScanner,
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'QR 코드로 당첨 확인',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_qrResult != null) ...[
          const SizedBox(height: 14),
          _buildQrResult(_qrResult!),
        ],
      ],
    );
  }

  Widget _buildQrResult(LottoQrResult qr) {
    final d = _detail;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: Color(0xFF4FD1C5),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '내 구매 결과 (${qr.round}회 · ${qr.games.length}게임)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (d == null || d.round != qr.round)
            Text(
              '${qr.round}회 당첨번호를 불러오는 중입니다...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            )
          else
            for (final g in qr.games) ...[
              _buildQrGameRow(g, d),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildQrGameRow(LottoQrGame game, WinningNumberDetail d) {
    final rank = WinningNumberService.calcRank(
      userNumbers: game.numbers,
      winningNumbers: d.numbers,
      bonus: d.bonus,
    );
    final winSet = d.numbers.toSet();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(
          color: rank == 0
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFF5A623).withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Colors.white.withValues(alpha: 0.10),
            ),
            child: Text(
              game.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final n in game.numbers)
                  _miniBall(
                    n,
                    matched: winSet.contains(n),
                    isBonus: n == d.bonus && rank == 2,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _rankBadge(rank),
        ],
      ),
    );
  }

  Widget _miniBall(int n, {required bool matched, required bool isBonus}) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: matched
            ? const Color(0xFFF5A623)
            : Colors.white.withValues(alpha: 0.10),
        border: isBonus
            ? Border.all(color: Colors.white, width: 1.5)
            : null,
      ),
      child: Text(
        '$n',
        style: TextStyle(
          color: matched ? Colors.white : Colors.white.withValues(alpha: 0.7),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _rankBadge(int rank) {
    if (rank == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.06),
        ),
        child: Text(
          '낙첨',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFF5A623), Color(0xFFFF6B6B)],
        ),
      ),
      child: Text(
        '$rank등 당첨!',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: Colors.white.withValues(alpha: 0.05),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    );
  }

  String _formatWon(int amount) {
    if (amount <= 0) return '-';
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()}원';
  }
}

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw != null && raw.isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(raw);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      '로또 QR 코드를 카메라에 비춰주세요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.flash_on_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => _controller.toggleTorch(),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4FD1C5),
                  width: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
