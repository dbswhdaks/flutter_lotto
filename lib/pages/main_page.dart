import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'lotto_home_page.dart';
import 'pension_page.dart';
import 'powerball_page.dart';
import 'speedkino_page.dart';
import 'megabingo_page.dart';
import 'tripleluck_page.dart';
import 'doublejack_page.dart';
import 'treasure_page.dart';
import 'catchme_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildTitle(),
                    const SizedBox(height: 28),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _LotteryCard(
                              title: '로또 6/45',
                              subtitle: '행운의 번호를 뽑아보세요!',
                              icon: Icons.casino,
                              gradientColors: const [
                                Color(0xFF7C3AED),
                                Color(0xFF9F7AEA),
                                Color(0xFFB794F4),
                              ],
                              shadowColor: const Color(0xFF7C3AED),
                              features: const [
                                '번호 추첨 애니메이션',
                                'AI 번호 추천',
                                '통계 분석',
                              ],
                              onTap: () => _navigateTo(const LottoHomePage()),
                              delay: const Duration(milliseconds: 200),
                            ),
                            const SizedBox(height: 16),
                            _LotteryCard(
                              title: '연금복권 720+',
                              subtitle: '매월 700만원 × 20년의 행운!',
                              icon: Icons.monetization_on,
                              gradientColors: const [
                                Color(0xFFFF8C00),
                                Color(0xFFFFB347),
                                Color(0xFFFFD700),
                              ],
                              shadowColor: const Color(0xFFFFB347),
                              features: const [
                                '슬롯 애니메이션',
                                '조 + 6자리 추첨',
                                'AI 분석',
                              ],
                              onTap: () => _navigateTo(const PensionPage()),
                              delay: const Duration(milliseconds: 400),
                            ),
                            const SizedBox(height: 16),
                            _LotteryCard(
                              title: '파워볼',
                              subtitle: '5개 번호 + 파워볼의 짜릿함!',
                              icon: Icons.bolt,
                              gradientColors: const [
                                Color(0xFFFF4757),
                                Color(0xFFFF6B81),
                                Color(0xFFFF8A9B),
                              ],
                              shadowColor: const Color(0xFFFF4757),
                              features: const [
                                '1~28 중 5개 추첨',
                                '파워볼 0~9',
                                'AI 분석',
                              ],
                              onTap: () => _navigateTo(const PowerballPage()),
                              delay: const Duration(milliseconds: 600),
                            ),
                            const SizedBox(height: 16),
                            _LotteryCard(
                              title: '스피드키노',
                              subtitle: '5분마다 추첨! 빠른 행운!',
                              icon: Icons.speed,
                              gradientColors: const [
                                Color(0xFF2ECC71),
                                Color(0xFF27AE60),
                                Color(0xFF58D68D),
                              ],
                              shadowColor: const Color(0xFF2ECC71),
                              features: const [
                                '1~70 중 10개 추첨',
                                '5분마다 288회',
                                'AI 분석',
                              ],
                              onTap: () => _navigateTo(const SpeedkinoPage()),
                              delay: const Duration(milliseconds: 800),
                            ),
                            const SizedBox(height: 16),
                            _LotteryCard(
                              title: '메가빙고',
                              subtitle: '4×4 빙고로 행운을 잡아라!',
                              icon: Icons.grid_view_rounded,
                              gradientColors: const [
                                Color(0xFFDA70D6),
                                Color(0xFF8E44AD),
                                Color(0xFFBB6BD9),
                              ],
                              shadowColor: const Color(0xFFDA70D6),
                              features: const [
                                '1~40 중 20개 추첨',
                                '4×4 빙고판',
                                'AI 분석',
                              ],
                              onTap: () => _navigateTo(const MegabingoPage()),
                              delay: const Duration(milliseconds: 1000),
                            ),
                            const SizedBox(height: 16),
                            _LotteryCard(
                              title: '트리플럭',
                              subtitle: '트리플 3개 + 럭 3개의 조합!',
                              icon: Icons.filter_3,
                              gradientColors: const [
                                Color(0xFF00BCD4),
                                Color(0xFF0097A7),
                                Color(0xFF4DD0E1),
                              ],
                              shadowColor: const Color(0xFF00BCD4),
                              features: const [
                                '1~27 중 6개 추첨',
                                '트리플 + 럭',
                                'AI 분석',
                              ],
                              onTap: () => _navigateTo(const TripleluckPage()),
                              delay: const Duration(milliseconds: 1200),
                            ),
                            const SizedBox(height: 16),
                            _LotteryCard(
                              title: '더블잭마이더스',
                              subtitle: '잭 6개 + 마이더스 6개의 황금 조합!',
                              icon: Icons.workspace_premium,
                              gradientColors: const [
                                Color(0xFFFFB300),
                                Color(0xFFFF8F00),
                                Color(0xFFFFD54F),
                              ],
                              shadowColor: const Color(0xFFFFB300),
                              features: const [
                                '1~45 중 6개 × 2세트',
                                '잭 + 마이더스',
                                'AI 분석',
                              ],
                              onTap: () => _navigateTo(const DoublejackPage()),
                              delay: const Duration(milliseconds: 1400),
                            ),
                            const SizedBox(height: 16),
                            _LotteryCard(
                              title: '트레져헌터',
                              subtitle: '6개 번호 + 보물번호의 모험!',
                              icon: Icons.diamond,
                              gradientColors: const [
                                Color(0xFF2ECC71),
                                Color(0xFF1ABC9C),
                                Color(0xFF00E676),
                              ],
                              shadowColor: const Color(0xFF2ECC71),
                              features: const [
                                '1~35 중 6개 추첨',
                                '보물번호 1~10',
                                'AI 분석',
                              ],
                              onTap: () => _navigateTo(const TreasurePage()),
                              delay: const Duration(milliseconds: 1600),
                            ),
                            const SizedBox(height: 16),
                            _LotteryCard(
                              title: '캐치미',
                              subtitle: '1개 번호를 골라 맞춰라!',
                              icon: Icons.gps_fixed,
                              gradientColors: const [
                                Color(0xFFE91E63),
                                Color(0xFFC2185B),
                                Color(0xFFFF80AB),
                              ],
                              shadowColor: const Color(0xFFE91E63),
                              features: const [
                                '1~45 중 1개 선택',
                                '번호 매칭 게임',
                                'AI 분석',
                              ],
                              onTap: () => _navigateTo(const CatchmePage()),
                              delay: const Duration(milliseconds: 1800),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    _buildFooter(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          '🎯 동행복권 생성기',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '오늘의 행운을 시험해보세요',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return GestureDetector(
      onTap: () async {
        try {
          await launchUrl(
            Uri.parse('https://www.dhlottery.co.kr/'),
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('브라우저를 열 수 없습니다')));
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF38B2AC), Color(0xFF4FD1C5)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38B2AC).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text(
              '동행복권 바로가기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.open_in_new,
              color: Colors.white.withValues(alpha: 0.7),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _LotteryCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color shadowColor;
  final List<String> features;
  final VoidCallback onTap;
  final Duration delay;

  const _LotteryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.shadowColor,
    required this.features,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_LotteryCard> createState() => _LotteryCardState();
}

class _LotteryCardState extends State<_LotteryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.gradientColors[0].withValues(alpha: 0.25),
                widget.gradientColors[1].withValues(alpha: 0.12),
                widget.gradientColors[2].withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: widget.gradientColors[0].withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.gradientColors[0],
                      widget.gradientColors[1],
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradientColors[0].withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: widget.features.map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: widget.gradientColors[0].withValues(
                              alpha: 0.15,
                            ),
                            border: Border.all(
                              color: widget.gradientColors[0].withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              color: widget.gradientColors[1],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.3),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
