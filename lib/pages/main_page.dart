import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'lotto_home_page.dart';
import 'lotto_store_page.dart';
import 'pension_page.dart';
import 'powerball_page.dart';
import 'speedkino_page.dart';
import 'megabingo_page.dart';
import 'tripleluck_page.dart';
import 'doublejack_page.dart';
import 'treasure_page.dart';
import 'catchme_page.dart';
import 'winning_number_page.dart';
import 'pension_winning_page.dart';

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
          const Positioned(
            top: -90,
            left: -70,
            child: _GlowOrb(
              color: Color(0xFFF5A623),
              size: 260,
              opacity: 0.20,
            ),
          ),
          const Positioned(
            top: 220,
            right: -110,
            child: _GlowOrb(
              color: Color(0xFF7C3AED),
              size: 240,
              opacity: 0.12,
            ),
          ),
          const Positioned(
            bottom: -110,
            right: -80,
            child: _GlowOrb(
              color: Color(0xFF4FD1C5),
              size: 300,
              opacity: 0.14,
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildTitle(),
                      const SizedBox(height: 22),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 4),
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
                                  '번호 생성',
                                  '통계 분석',
                                ],
                                onTap: () => _navigateTo(const LottoHomePage()),
                                delay: const Duration(milliseconds: 200),
                              ),
                              const SizedBox(height: 14),
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
                                  '번호 분석',
                                ],
                                onTap: () => _navigateTo(const PensionPage()),
                                delay: const Duration(milliseconds: 400),
                              ),
                              const SizedBox(height: 14),
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
                                  '번호 분석',
                                ],
                                onTap: () => _navigateTo(const PowerballPage()),
                                delay: const Duration(milliseconds: 600),
                              ),
                              const SizedBox(height: 14),
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
                                  '번호 분석',
                                ],
                                onTap: () => _navigateTo(const SpeedkinoPage()),
                                delay: const Duration(milliseconds: 800),
                              ),
                              const SizedBox(height: 14),
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
                                  '번호 분석',
                                ],
                                onTap: () => _navigateTo(const MegabingoPage()),
                                delay: const Duration(milliseconds: 1000),
                              ),
                              const SizedBox(height: 14),
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
                                  '번호 분석',
                                ],
                                onTap: () => _navigateTo(const TripleluckPage()),
                                delay: const Duration(milliseconds: 1200),
                              ),
                              const SizedBox(height: 14),
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
                                  '번호 분석',
                                ],
                                onTap: () => _navigateTo(const DoublejackPage()),
                                delay: const Duration(milliseconds: 1400),
                              ),
                              const SizedBox(height: 14),
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
                                  '번호 분석',
                                ],
                                onTap: () => _navigateTo(const TreasurePage()),
                                delay: const Duration(milliseconds: 1600),
                              ),
                              const SizedBox(height: 14),
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
                                  '번호 분석',
                                ],
                                onTap: () => _navigateTo(const CatchmePage()),
                                delay: const Duration(milliseconds: 1800),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDisclaimer(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return SizedBox(
      height: 76,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildMenuButton(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTitleText(),
                const SizedBox(height: 6),
                _buildSubtitleBadge(),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildShareButton(),
        ],
      ),
    );
  }

  Widget _buildTitleText() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.auto_awesome,
          color: Color(0xFFFFE08A),
          size: 14,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFFFE08A),
                Color(0xFFF5A623),
                Color(0xFFFF8A65),
              ],
            ).createShader(rect),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                'Lotto 번호 통계 분석',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: Color(0x66F5A623),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(
          Icons.auto_awesome,
          color: Color(0xFFFF8A65),
          size: 14,
        ),
      ],
    );
  }

  Widget _buildSubtitleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFF4FD1C5).withValues(alpha: 0.22),
            const Color(0xFF4FD1C5).withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF4FD1C5).withValues(alpha: 0.45),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FD1C5).withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.stars_rounded,
            color: Color(0xFF4FD1C5),
            size: 13,
          ),
          const SizedBox(width: 5),
          const Text(
            '오늘의 행운 도전!',
            style: TextStyle(
              color: Color(0xFF7FE9DF),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return _buildIconButton(
      icon: Icons.share_rounded,
      accentColor: const Color(0xFFF5A623),
      onTap: () {
        SharePlus.instance.share(
          ShareParams(
            text:
                '🎯 Lotto 번호 통계 분석으로 행운의 번호를 뽑아보세요!\n'
                '로또 6/45, 연금복권, 파워볼 등 다양한 복권 번호를 통계 기반으로 추천해드립니다.',
          ),
        );
      },
    );
  }

  Widget _buildMenuButton() {
    return _buildIconButton(
      icon: Icons.menu_rounded,
      accentColor: const Color(0xFF4FD1C5),
      onTap: _openMenuSheet,
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: accentColor.withValues(alpha: 0.20),
        highlightColor: accentColor.withValues(alpha: 0.08),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: 0.22),
                accentColor.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.30),
                blurRadius: 18,
                spreadRadius: -2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              color: Colors.white.withValues(alpha: 0.45),
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '본 앱은 공식 동행복권 앱이 아니며 번호 추천 및 통계 참고용 앱입니다',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMenuSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        final maxHeight = MediaQuery.of(sheetCtx).size.height * 0.85;
        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF0F1B33)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '메뉴',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _MenuTile(
                          icon: Icons.confirmation_number_rounded,
                          iconColor: const Color(0xFFFFB300),
                          title: '로또 당첨번호 확인하기',
                          subtitle: '회차별 조회 + QR 코드 스캔',
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
                            _navigateTo(const WinningNumberPage());
                          },
                        ),
                        const SizedBox(height: 10),
                        _MenuTile(
                          icon: Icons.monetization_on_rounded,
                          iconColor: const Color(0xFFFF8C00),
                          title: '연금복권 당첨번호 확인하기',
                          subtitle: '연금복권 720+ 회차별 조회',
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
                            _navigateTo(const PensionWinningPage());
                          },
                        ),
                        const SizedBox(height: 10),
                        _MenuTile(
                          icon: Icons.storefront_rounded,
                          iconColor: const Color(0xFFF5A623),
                          title: '로또 판매점 찾기',
                          subtitle: '내 위치 기준 거리순 + 길찾기 연결',
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
                            _navigateTo(const LottoStorePage());
                          },
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '추천 앱',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _MenuTile(
                          icon: Icons.emoji_events_rounded,
                          iconColor: const Color(0xFFD97706),
                          title: '경마 Plus',
                          subtitle: 'AI 경마예상 · 실시간 경주결과',
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
                            _launchStore(
                              'https://play.google.com/store/apps/details?id=com.horseracingplus.app',
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _MenuTile(
                          icon: Icons.pedal_bike_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          title: '경륜 Plus',
                          subtitle: '실시간 경륜정보 및 경기 결과',
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
                            _launchStore(
                              'https://play.google.com/store/apps/details?id=com.gyeongryunplus.app',
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _MenuTile(
                          icon: Icons.directions_boat_rounded,
                          iconColor: const Color(0xFF06B6D4),
                          title: '경정 Plus',
                          subtitle: '출주표 · AI 상세분석 및 예상 · 결과정보',
                          onTap: () {
                            Navigator.of(sheetCtx).pop();
                            _launchStore(
                              'https://play.google.com/store/apps/details?id=com.boat_racing',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchStore(String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        _showLaunchError();
      }
    } catch (_) {
      if (mounted) _showLaunchError();
    }
  }

  void _showLaunchError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('스토어를 열 수 없습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowOrb({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.18),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.35),
                size: 14,
              ),
            ],
          ),
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
  bool _isPressed = false;

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
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.gradientColors[0].withValues(alpha: 0.30),
                  widget.gradientColors[1].withValues(alpha: 0.14),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              border: Border.all(
                color: widget.gradientColors[0].withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.shadowColor.withValues(alpha: 0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildIcon(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 5,
                        children: widget.features.map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  widget.gradientColors[0].withValues(
                                    alpha: 0.22,
                                  ),
                                  widget.gradientColors[1].withValues(
                                    alpha: 0.12,
                                  ),
                                ],
                              ),
                              border: Border.all(
                                color: widget.gradientColors[0].withValues(
                                  alpha: 0.32,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                color: Color.lerp(
                                  widget.gradientColors[2],
                                  Colors.white,
                                  0.25,
                                ),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _buildArrow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.gradientColors[0], widget.gradientColors[1]],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors[0].withValues(alpha: 0.55),
                blurRadius: 18,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(widget.icon, color: Colors.white, size: 28),
        ),
        Positioned(
          top: 9,
          left: 12,
          child: Container(
            width: 10,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.gradientColors[0].withValues(alpha: 0.20),
        border: Border.all(
          color: widget.gradientColors[0].withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.white.withValues(alpha: 0.85),
        size: 12,
      ),
    );
  }
}
