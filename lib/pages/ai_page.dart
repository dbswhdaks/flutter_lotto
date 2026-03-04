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
  AnalysisResult? _analysis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _dataService.loadData(fetchCount: 1000);
      final analyzer = LottoAnalyzer(_dataService.draws);
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
          '번호 분석',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE94560),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: '번호 생성'),
            Tab(text: '통계 분석'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE94560)),
                  SizedBox(height: 16),
                  Text(
                    '과거 당첨 데이터 로딩 중...',
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
                    _buildLocalAiTab(),
                    _buildStatsTab(),
                  ],
                ),
    );
  }

  // ── 탭 1: 통계 분석 ──
  Widget _buildStatsTab() {
    final a = _analysis!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🔥 핫번호 (최근 20회 자주 출현)'),
          _buildBallRow(a.hotNumbers),
          const SizedBox(height: 20),

          _sectionTitle('❄️ 콜드번호 (최근 20회 미출현)'),
          _buildBallRow(a.coldNumbers),
          const SizedBox(height: 20),

          _sectionTitle('⏰ 장기 미출현 번호'),
          _buildBallRow(a.overdueNumbers),
          const SizedBox(height: 20),

          _sectionTitle('📊 구간별 출현 비율'),
          ...a.rangeDistribution.entries.map((e) => _buildBar(e.key, e.value)),
          const SizedBox(height: 20),

          _sectionTitle('📈 기본 통계'),
          _statRow('평균 홀수 비율', '${(a.avgOddEvenRatio * 100).toStringAsFixed(1)}%'),
          _statRow('평균 번호 합계', a.avgSum.toStringAsFixed(0)),
          _statRow('분석 데이터', '${_dataService.draws.length}회분'),
          const SizedBox(height: 20),

          _sectionTitle('🏆 번호별 출현 빈도 TOP 10'),
          _buildFrequencyChart(a.frequency),
        ],
      ),
    );
  }

  Widget _buildFrequencyChart(Map<int, int> freq) {
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(10);
    final maxVal = top.first.value.toDouble();

    return Column(
      children: top.map((e) {
        final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              LottoBall(number: e.key, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                        height: 22,
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
                width: 35,
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

  // ── 탭 2: 번호 생성 ──
  Widget _buildLocalAiTab() {
    final a = _analysis!;
    final strategies = [
      '🔥 핫번호 중심',
      '❄️ 콜드번호 포함',
      '🔄 핫 + 오래된 번호 혼합',
      '⚖️ 구간 균형',
      '🎲 빈도 가중 랜덤',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('추천 번호 (5세트)'),
          const SizedBox(height: 4),
          Text(
            '과거 ${_dataService.draws.length}회 (최대 1,000회) 데이터 기반 분석',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...List.generate(a.recommendations.length, (i) {
            return _buildRecommendationCard(
              strategies[i],
              a.recommendations[i],
              i,
            );
          }),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                final analyzer = LottoAnalyzer(_dataService.draws);
                setState(() => _analysis = analyzer.analyze());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('다시 추천받기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE94560),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String strategy, List<int> numbers, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE94560).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '세트 ${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFFFF6B81),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strategy,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: numbers
                .map((n) => LottoBall(number: n, size: 42))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── 공통 위젯 ──
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

  Widget _buildBallRow(List<int> numbers) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: numbers.map((n) => LottoBall(number: n, size: 36)).toList(),
      ),
    );
  }

  Widget _buildBar(String label, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
            width: 45,
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
}
