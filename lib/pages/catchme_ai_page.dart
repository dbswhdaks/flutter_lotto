import 'package:flutter/material.dart';
import '../services/catchme_data_service.dart';
import '../services/catchme_analyzer.dart';

class CatchmeAiPage extends StatefulWidget {
  const CatchmeAiPage({super.key});

  @override
  State<CatchmeAiPage> createState() => _CatchmeAiPageState();
}

class _CatchmeAiPageState extends State<CatchmeAiPage>
    with SingleTickerProviderStateMixin {
  final _dataService = CatchmeDataService();
  late TabController _tabController;

  bool _loading = true;
  String? _error;
  CatchmeAnalysisResult? _analysis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _dataService.loadData(fetchCount: 300);
      final analyzer = CatchmeAnalyzer(_dataService.draws);
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

  Color _ballColor(int number) {
    if (number <= 9) return const Color(0xFFFF6B9D);
    if (number <= 18) return const Color(0xFFE91E63);
    if (number <= 27) return const Color(0xFFC2185B);
    if (number <= 36) return const Color(0xFFAD1457);
    return const Color(0xFF880E4F);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('캐치미 AI 분석',
            style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE91E63),
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
                  CircularProgressIndicator(color: Color(0xFFE91E63)),
                  SizedBox(height: 16),
                  Text('캐치미 데이터 로딩 중...',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center),
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

  Widget _buildRecommendationTab() {
    final a = _analysis!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('AI 추천 번호 (5가지 전략)'),
          const SizedBox(height: 4),
          Text(
            '과거 ${a.totalDraws}회 데이터 기반 분석 · 1개 번호 추천',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...a.recommendations.map((rec) => _buildRecCard(rec)),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                final analyzer = CatchmeAnalyzer(_dataService.draws);
                setState(() => _analysis = analyzer.analyze());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('다시 추천받기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildRecCard(CatchmeRecommendation rec) {
    final c = _ballColor(rec.number);
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${rec.icon} ${rec.strategy}',
                    style: const TextStyle(
                      color: Color(0xFFFF80AB),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '추천 번호',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _CatchBall(number: rec.number, color: c, size: 56),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final a = _analysis!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('🔥 핫번호 (최근 30회 자주 출현)'),
          const SizedBox(height: 8),
          _buildBallWrap(a.hotNumbers),
          const SizedBox(height: 20),
          _sectionTitle('❄️ 콜드번호 (최근 30회 미출현)'),
          const SizedBox(height: 8),
          a.coldNumbers.isEmpty
              ? Text('없음',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13))
              : _buildBallWrap(a.coldNumbers),
          const SizedBox(height: 20),
          _sectionTitle('⏰ 장기 미출현 번호'),
          const SizedBox(height: 8),
          _buildBallWrap(a.overdueNumbers),
          const SizedBox(height: 20),
          _sectionTitle('📊 구간별 출현 비율'),
          const SizedBox(height: 8),
          ...a.rangeDistribution.entries.map((e) => _buildBar(e.key, e.value)),
          const SizedBox(height: 20),
          _sectionTitle('📈 기본 통계'),
          _statRow('분석 데이터', '${a.totalDraws}회분'),
          _statRow('확률', '1/45 (약 2.2%)'),
          const SizedBox(height: 20),
          _sectionTitle('🏆 번호별 출현 빈도 TOP 15'),
          const SizedBox(height: 8),
          _buildFrequencyChart(a.frequency),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildBallWrap(List<int> numbers) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: numbers
          .map((n) => _CatchBall(number: n, color: _ballColor(n), size: 36))
          .toList(),
    );
  }

  Widget _buildFrequencyChart(Map<int, int> freq) {
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(15);
    final maxVal = top.isNotEmpty ? top.first.value.toDouble() : 1.0;

    return Column(
      children: top.map((e) {
        final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
        final c = _ballColor(e.key);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              _CatchBall(number: e.key, color: c, size: 28),
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
                          gradient: LinearGradient(
                            colors: [c, c.withValues(alpha: 0.6)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 35,
                child: Text('${e.value}회',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBar(String label, double percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ),
          const SizedBox(width: 6),
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
                  widthFactor: (percent / 25).clamp(0, 1),
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 45,
            child: Text('${percent.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800));
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CatchBall extends StatelessWidget {
  final int number;
  final Color color;
  final double size;

  const _CatchBall({
    required this.number,
    required this.color,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.35),
          radius: 0.75,
          colors: [
            Color.lerp(color, Colors.white, 0.35)!,
            color,
            Color.lerp(color, Colors.black, 0.2)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w900,
            shadows: const [
              Shadow(
                  color: Color(0x55000000),
                  offset: Offset(0, 1),
                  blurRadius: 2),
            ],
          ),
        ),
      ),
    );
  }
}
