import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lotto_result.dart';
import '../widgets/lotto_machine.dart';
import '../widgets/result_panel.dart';
import '../widgets/history_panel.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/traveling_ball.dart';
import 'ai_page.dart';

class LottoHomePage extends StatefulWidget {
  const LottoHomePage({super.key});

  @override
  State<LottoHomePage> createState() => _LottoHomePageState();
}

class _LottoHomePageState extends State<LottoHomePage> {
  int _drawCount = 0;
  bool _isDrawing = false;
  bool _showConfetti = false;
  LottoResult? _currentResult;
  List<int> _revealedNumbers = [];
  bool _showPlus = false;
  bool _showBonus = false;
  final List<LottoResult> _history = [];
  final GlobalKey<LottoMachineState> _machineKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  int? _travelingNumber;
  Completer<void>? _arrivalCompleter;

  static const double _sphereSize = 260;
  static const double _headerHeight = 80;
  static const double _machineAreaTop = _headerHeight;
  static const double _sphereScreenTop = _machineAreaTop + 50;
  static const double _sphereRadius = _sphereSize / 2;
  static const double _sphereCenterY = _sphereScreenTop + _sphereRadius;
  static const double _tubeTopY = _machineAreaTop + 2;

  Path _buildUpwardPath(double screenWidth) {
    final cx = screenWidth / 2;
    return Path()
      ..moveTo(cx, _sphereCenterY)
      ..lineTo(cx, _tubeTopY - 30);
  }

  Future<void> _startDraw() async {
    if (_isDrawing) return;

    setState(() {
      _isDrawing = true;
      _showConfetti = false;
      _drawCount++;
      _revealedNumbers = [];
      _showPlus = false;
      _showBonus = false;
      _currentResult = LottoResult.generate(_drawCount);
    });

    if (_scrollController.offset > 0) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }

    await Future.delayed(const Duration(milliseconds: 400));

    for (int i = 0; i < 6; i++) {
      _machineKey.currentState?.boostBalls();
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      _arrivalCompleter = Completer<void>();
      setState(() {
        _travelingNumber = _currentResult!.mainNumbers[i];
      });

      await _arrivalCompleter!.future;
      if (!mounted) return;

      setState(() {
        _travelingNumber = null;
        _revealedNumbers = List.from(_revealedNumbers)
          ..add(_currentResult!.mainNumbers[i]);
      });

      await Future.delayed(const Duration(milliseconds: 100));
    }

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _showPlus = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));
    _machineKey.currentState?.boostBalls();

    _arrivalCompleter = Completer<void>();
    setState(() {
      _travelingNumber = _currentResult!.bonusNumber;
    });

    await _arrivalCompleter!.future;
    if (!mounted) return;

    setState(() {
      _travelingNumber = null;
      _showBonus = true;
    });

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    setState(() {
      _isDrawing = false;
      _showConfetti = true;
      _history.insert(0, _currentResult!);
    });

    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _showConfetti = false);
  }

  void _onBallArrived() {
    _arrivalCompleter?.complete();
  }

  void _reset() {
    setState(() {
      _isDrawing = false;
      _drawCount = 0;
      _currentResult = null;
      _revealedNumbers = [];
      _showPlus = false;
      _showBonus = false;
      _history.clear();
      _showConfetti = false;
      _travelingNumber = null;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final upwardPath = _buildUpwardPath(screenWidth);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              '🎱 6/45 로또 번호 추첨기',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 36),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '행운의 번호를 뽑아보세요!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: LottoMachine(
                        key: _machineKey,
                        isSpinning: _isDrawing,
                        sphereSize: _sphereSize,
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 4, bottom: 2),
                              child: _ResetButton(onPressed: _reset),
                            ),
                            ResultPanel(
                              result: _currentResult,
                              revealedNumbers: _revealedNumbers,
                              showPlus: _showPlus,
                              showBonus: _showBonus,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DrawButton(
                              onPressed: _isDrawing ? null : _startDraw,
                              isDrawing: _isDrawing,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  _AiButton(
                                    onPressed: _isDrawing
                                        ? null
                                        : () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const AiPage()),
                                            );
                                          },
                                  ),
                                  const SizedBox(height: 8),
                                  const _BuyButton(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    HistoryPanel(history: _history),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // 위로 올라가는 추첨 공
              if (_travelingNumber != null)
                TravelingBall(
                  key: ValueKey(
                      'ball_${_travelingNumber}_${_revealedNumbers.length}'),
                  number: _travelingNumber!,
                  path: upwardPath,
                  onArrived: _onBallArrived,
                ),

              Positioned.fill(
                child: IgnorePointer(
                  child: ConfettiOverlay(trigger: _showConfetti),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final List<Color> gradientColors;
  final Color? shadowColor;

  const _ActionButton({
    required this.onPressed,
    required this.label,
    this.icon,
    this.gradientColors = const [],
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: gradientColors),
        boxShadow: shadowColor != null
            ? [
                BoxShadow(
                  color: shadowColor!.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white.withValues(alpha: enabled ? 1 : 0.5), size: 17),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isDrawing;

  const _DrawButton({required this.onPressed, required this.isDrawing});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Container(
      width: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDrawing ? Icons.hourglass_top : Icons.casino,
                color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                isDrawing ? '추첨 중' : '추첨 시작',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _ResetButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.refresh,
          color: Colors.white.withValues(alpha: enabled ? 0.9 : 0.4),
          size: 26,
        ),
      ),
    );
  }
}

class _AiButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _AiButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      onPressed: onPressed,
      label: 'AI 추천',
      icon: Icons.auto_awesome,
      gradientColors: const [Color(0xFF4F8CFF), Color(0xFF6FA3FF)],
      shadowColor: const Color(0xFF4F8CFF),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton();

  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      onPressed: () async {
        try {
          await launchUrl(
            Uri.parse('https://el.dhlottery.co.kr/game/TotalGame.jsp?LottoId=LO40'),
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('브라우저를 열 수 없습니다')),
            );
          }
        }
      },
      label: '동행복권 바로구매',
      icon: Icons.shopping_cart,
      gradientColors: const [Color(0xFF38B2AC), Color(0xFF4FD1C5)],
      shadowColor: const Color(0xFF38B2AC),
    );
  }
}
