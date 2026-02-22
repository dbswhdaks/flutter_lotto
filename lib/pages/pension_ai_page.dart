import 'package:flutter/material.dart';
import '../services/pension_data_service.dart';
import '../services/pension_analyzer.dart';

class PensionAiPage extends StatefulWidget {
  const PensionAiPage({super.key});

  @override
  State<PensionAiPage> createState() => _PensionAiPageState();
}

class _PensionAiPageState extends State<PensionAiPage>
    with SingleTickerProviderStateMixin {
  final _dataService = PensionDataService();
  late TabController _tabController;

  bool _loading = true;
  String? _error;
  PensionAnalysisResult? _analysis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _dataService.loadData(fetchCount: 300);
      final analyzer = PensionAnalyzer(_dataService.draws);
      setState(() {
        _analysis = analyzer.analyze();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '데이터를 불러올 수 없습니다: $e';
        _loading = false;
      });
    }
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
          '연금복권 AI 분석',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'AI 추천'),
            Tab(text: '통계 분석'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFFD700)),
                  SizedBox(height: 16),
                  Text(
                    '연금복권 당첨 데이터 로딩 중...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRecommendationTab(),
                    _buildStatsTab(),
                  ],
                ),
    );
  }

  // ── 탭 1: AI 추천 ──
  Widget _buildRecommendationTab() {
    final a = _analysis!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('AI 추천 번호 (5세트)'),
          const SizedBox(height: 4),
          Text(
            '과거 ${a.totalDraws}회 데이터 기반 분석',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          ...a.recommendations.map((rec) => _buildRecommendationCard(rec)),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                final analyzer = PensionAnalyzer(_dataService.draws);
                setState(() => _analysis = analyzer.analyze());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('다시 추천받기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF1A1A2E),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(PensionRecommendation rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${rec.icon} ${rec.strategy}',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                _GroupBadge(group: rec.group),
                const SizedBox(width: 10),
                ...List.generate(6, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _DigitBox(
                      digit: rec.digits[i],
                      index: i,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 탭 2: 통계 분석 ──
  Widget _buildStatsTab() {
    final a = _analysis!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📊 조별 출현 빈도'),
          const SizedBox(height: 8),
          _buildGroupChart(a.groupFrequency),
          const SizedBox(height: 24),
          _sectionTitle('🔥 자릿수별 핫 숫자 (최근 30회)'),
          const SizedBox(height: 8),
          _buildHotColdTable(a.hotDigits, isHot: true),
          const SizedBox(height: 24),
          _sectionTitle('❄️ 자릿수별 콜드 숫자 (최근 30회 미출현)'),
          const SizedBox(height: 8),
          _buildHotColdTable(a.coldDigits, isHot: false),
          const SizedBox(height: 24),
          _sectionTitle('📈 자릿수별 숫자 출현 빈도'),
          const SizedBox(height: 8),
          ...List.generate(6, (pos) {
            return _buildDigitFrequencyRow(pos, a.digitFrequency[pos]);
          }),
          const SizedBox(height: 16),
          _statRow('분석 데이터', '${a.totalDraws}회분'),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildGroupChart(Map<int, int> groupFreq) {
    final maxVal =
        groupFreq.values.fold(0, (a, b) => a > b ? a : b).toDouble();

    return Column(
      children: groupFreq.entries.map((e) {
        final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              _GroupBadge(group: e.key, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
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
                  '${e.value}회',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHotColdTable(List<List<int>> data, {required bool isHot}) {
    final color = isHot ? const Color(0xFFFF6B6B) : const Color(0xFF4D96FF);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: List.generate(6, (pos) {
          final digits = data[pos];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    '${pos + 1}번째 자리',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (digits.isEmpty)
                  Text(
                    '없음',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    children: digits.map((d) {
                      return Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: color.withValues(alpha: 0.2),
                          border: Border.all(
                            color: color.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$d',
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDigitFrequencyRow(int pos, Map<int, int> freq) {
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pos + 1}번째 자리',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ...sorted.map((e) {
            final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${e.key}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                colors: [
                                  _digitColors[pos],
                                  _digitColors[pos].withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${e.value}',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 공통 ──
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
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

  static const _digitColors = [
    Color(0xFFFF6B6B),
    Color(0xFFFFD93D),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFC084FC),
    Color(0xFFFF922B),
  ];
}

class _GroupBadge extends StatelessWidget {
  final int group;
  final double size;

  const _GroupBadge({required this.group, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$group조',
          style: TextStyle(
            color: const Color(0xFF1A1A2E),
            fontSize: size * 0.3,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  final int digit;
  final int index;

  const _DigitBox({required this.digit, required this.index});

  static const _colors = [
    [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
    [Color(0xFFFFD93D), Color(0xFFF39C12)],
    [Color(0xFF6BCB77), Color(0xFF27AE60)],
    [Color(0xFF4D96FF), Color(0xFF2980B9)],
    [Color(0xFFC084FC), Color(0xFF8E44AD)],
    [Color(0xFFFF922B), Color(0xFFD35400)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _colors[index];
    return Container(
      width: 40,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$digit',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Color(0x55000000),
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
