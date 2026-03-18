import 'package:flutter/material.dart';
import '../services/lotto_data_service.dart';
import '../services/lotto_analyzer.dart';
import '../widgets/lotto_ball.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> with SingleTickerProviderStateMixin {
  final _dataService = LottoDataService();
  late TabController _tabController;

  bool _loading = true;
  String? _error;
  int _loadedCount = 0;
  int _totalCount = 0;
  FullAnalysisResult? _fullAnalysis;
  int _recommendRoundCount = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      await _dataService.loadAllData(
        onProgress: (loaded, total) {
          if (mounted) {
            setState(() {
              _loadedCount = loaded;
              _totalCount = total;
            });
          }
        },
      );
      final analyzer = LottoAnalyzer(_dataService.draws);
      setState(() {
        _fullAnalysis = analyzer.fullAnalyze(
          recommendCount: _recommendRoundCount,
          overrideLatestRound: _dataService.latestRound > 0
              ? _dataService.latestRound
              : null,
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '데이터를 불러올 수 없습니다: $e';
        _loading = false;
      });
    }
  }

  void _refreshRecommendations() {
    if (_dataService.draws.isEmpty) return;
    final analyzer = LottoAnalyzer(_dataService.draws);
    setState(() {
      _fullAnalysis = analyzer.fullAnalyze(
        recommendCount: _recommendRoundCount,
        overrideLatestRound: _dataService.latestRound > 0
            ? _dataService.latestRound
            : null,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          '전체 통계 분석 & 추천번호',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFF5A623),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: '추천번호'),
            Tab(text: '통계분석'),
            Tab(text: '상세분석'),
          ],
        ),
      ),
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRecommendTab(),
                    _buildStatsTab(),
                    _buildDetailTab(),
                  ],
                ),
    );
  }

  // ── 로딩 화면 ──
  Widget _buildLoading() {
    final progress = _totalCount > 0 ? _loadedCount / _totalCount : 0.0;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.analytics, color: Color(0xFFF5A623), size: 48),
              const SizedBox(height: 24),
              const Text(
                '전체 당첨번호 데이터 로딩 중...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_loadedCount / $_totalCount 회차',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFF5A623)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '1회부터 전체 데이터를 분석합니다',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadAllData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                foregroundColor: Colors.white,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  //  탭 1: 추천번호
  // ══════════════════════════════════════════
  Widget _buildRecommendTab() {
    final a = _fullAnalysis!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard(
            '1회 ~ ${a.latestRound}회 (총 ${a.totalDraws}회) 전체 데이터 기반 분석\n'
            '제 ${a.latestRound + 1}회 추천번호를 제공합니다',
            const Color(0xFFF5A623),
          ),
          const SizedBox(height: 16),
          ...a.roundRecommendations.map(_buildRoundSection),
          const SizedBox(height: 12),
          _gradientButton(
            label: '다시 추천받기',
            icon: Icons.refresh,
            colors: const [Color(0xFFE94560), Color(0xFFFF6B81)],
            onPressed: _refreshRecommendations,
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  String _weekLabel(int round) {
    final a = _fullAnalysis!;
    final offset = round - (a.latestRound + 1);
    if (offset == 0) return '이번주';
    if (offset == 1) return '다음주';
    if (offset == 2) return '다다음주';
    return '${offset + 1}주 후';
  }

  Widget _buildRoundSection(RoundRecommendation rr) {
    final weekText = _weekLabel(rr.round);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10, top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                '제 ${rr.round}회 추천번호',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  weekText,
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...rr.sets.asMap().entries.map((entry) {
          return _buildSetCard(entry.value, entry.key);
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSetCard(RecommendationSet set, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '세트 ${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFFFF6B81),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${set.emoji} ${set.strategy}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: set.numbers.map((n) => LottoBall(number: n, size: 40)).toList(),
          ),
          const SizedBox(height: 6),
          Text(
            set.reason,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  //  탭 2: 통계분석
  // ══════════════════════════════════════════
  Widget _buildStatsTab() {
    final a = _fullAnalysis!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoCard(
            '1회 ~ ${a.latestRound}회 | 전체 분석 완료',
            const Color(0xFF4FD1C5),
          ),
          const SizedBox(height: 20),

          _sectionTitle('🔥 핫번호 (최근 50회 자주 출현)'),
          _buildBallRow(a.hotNumbers),
          const SizedBox(height: 20),

          _sectionTitle('❄️ 콜드번호 (최근 50회 미출현)'),
          _buildBallRow(a.coldNumbers),
          const SizedBox(height: 20),

          _sectionTitle('⏰ 장기 미출현 번호'),
          _buildBallRow(a.overdueNumbers),
          const SizedBox(height: 4),
          ...a.overdueNumbers.take(5).map((n) {
            final gap = a.overdueGap[n] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '  $n번: $gap회 연속 미출현',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            );
          }),
          const SizedBox(height: 20),

          _sectionTitle('📊 구간별 출현 비율'),
          ...a.rangeDistribution.entries.map((e) => _buildBar(e.key, e.value)),
          const SizedBox(height: 20),

          _sectionTitle('📈 기본 통계'),
          _statRow('총 분석 회차', '${a.totalDraws}회'),
          _statRow('평균 홀수 비율', '${(a.avgOddEvenRatio * 100).toStringAsFixed(1)}%'),
          _statRow('평균 번호 합계', a.avgSum.toStringAsFixed(0)),
          const SizedBox(height: 20),

          if (a.recentTrend.isNotEmpty) ...[
            _sectionTitle('📉 최근 추세'),
            ...a.recentTrend.entries.map((e) =>
              _statRow(e.key, e.value.toStringAsFixed(1)),
            ),
            const SizedBox(height: 20),
          ],

          _sectionTitle('🏆 번호별 출현 빈도 TOP 15'),
          _buildFrequencyChart(a.frequency, 15),
          const SizedBox(height: 20),

          _sectionTitle('🎁 보너스 번호 빈도 TOP 10'),
          _buildFrequencyChart(a.bonusFrequency, 10),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  //  탭 3: 상세분석
  // ══════════════════════════════════════════
  Widget _buildDetailTab() {
    final a = _fullAnalysis!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🔢 끝자리별 출현 빈도'),
          _buildEndDigitChart(a.endDigitFrequency),
          const SizedBox(height: 24),

          _sectionTitle('🤝 자주 함께 나오는 번호 쌍 TOP 15'),
          ...a.topPairs.map((e) => _buildPairRow(e.key, e.value)),
          const SizedBox(height: 24),

          _sectionTitle('🎯 자주 함께 나오는 3개 조합 TOP 10'),
          ...a.topTriplets.map((e) => _buildPairRow(e.key, e.value)),
          const SizedBox(height: 24),

          _sectionTitle('📐 연번(연속 번호) 출현 통계'),
          _buildConsecutiveChart(a.consecutivePairCount),
          const SizedBox(height: 24),

          _sectionTitle('📊 전체 번호 출현 빈도 (1~45)'),
          _buildAllNumbersChart(a.frequency),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  //  공통 위젯
  // ══════════════════════════════════════════

  Widget _infoCard(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildBallRow(List<int> numbers) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: numbers.map((n) => LottoBall(number: n, size: 36)).toList(),
    );
  }

  Widget _buildBar(String label, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (percent / 30).clamp(0, 1),
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF5A623), Color(0xFFFFD54F)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              '${percent.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyChart(Map<int, int> freq, int topN) {
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(topN);
    final maxVal = top.first.value.toDouble();

    return Column(
      children: top.map((e) {
        final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              LottoBall(number: e.key, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE94560), Color(0xFFFF6B81)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 38,
                child: Text(
                  '${e.value}회',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEndDigitChart(Map<int, int> endDigitFreq) {
    final maxVal = endDigitFreq.values.fold(0, (a, b) => a > b ? a : b).toDouble();
    return Column(
      children: List.generate(10, (digit) {
        final count = endDigitFreq[digit] ?? 0;
        final ratio = maxVal > 0 ? count / maxVal : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '끝 $digit',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F8CFF), Color(0xFF6FA3FF)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '$count회',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPairRow(String pairKey, int count) {
    final numbers = pairKey.split('-').map(int.parse).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          ...numbers.map((n) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: LottoBall(number: n, size: 26),
          )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5A623).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count회 동반 출현',
              style: const TextStyle(
                color: Color(0xFFF5A623),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsecutiveChart(Map<int, int> counts) {
    final sorted = counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final total = sorted.fold<int>(0, (s, e) => s + e.value);

    return Column(
      children: sorted.map((e) {
        final pct = total > 0 ? (e.value / total * 100) : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  '연번 ${e.key}쌍',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: (pct / 60).clamp(0, 1),
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2ECC71), Color(0xFF58D68D)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 75,
                child: Text(
                  '${e.value}회 (${pct.toStringAsFixed(1)}%)',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAllNumbersChart(Map<int, int> freq) {
    final maxVal = freq.values.fold(0, (a, b) => a > b ? a : b).toDouble();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(45, (i) {
        final num = i + 1;
        final count = freq[num] ?? 0;
        final ratio = maxVal > 0 ? count / maxVal : 0.0;
        final opacity = 0.3 + ratio * 0.7;

        return Tooltip(
          message: '$num번: $count회 출현',
          child: Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _getNumberColor(num).withValues(alpha: opacity * 0.3),
              border: Border.all(
                color: _getNumberColor(num).withValues(alpha: opacity * 0.5),
              ),
            ),
            child: Column(
              children: [
                LottoBall(number: num, size: 26),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Color _getNumberColor(int n) {
    if (n <= 10) return const Color(0xFFF5A623);
    if (n <= 20) return const Color(0xFF4F8CFF);
    if (n <= 30) return const Color(0xFFE94560);
    if (n <= 40) return const Color(0xFF9B9B9B);
    return const Color(0xFF2ECC71);
  }

  Widget _gradientButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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
