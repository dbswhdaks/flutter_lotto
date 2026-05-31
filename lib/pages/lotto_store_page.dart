import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lotto_store.dart';
import '../services/lotto_store_service.dart';
import '../widgets/naver_navigation.dart';

/// 현재 위치 기준으로 가까운 로또 판매점을 자동으로 거리순 정렬해 보여주는 페이지.
///
/// 동행복권 API를 직접 호출하지 않고 Supabase RPC `nearby_lotto_stores` 한 번만
/// 호출한다. 거리·정렬·필터 모두 서버(PostGIS)에서 수행한 결과를 그대로 표시.
class LottoStorePage extends StatefulWidget {
  const LottoStorePage({super.key});

  @override
  State<LottoStorePage> createState() => _LottoStorePageState();
}

class _LottoStorePageState extends State<LottoStorePage> {
  final LottoStoreService _service = LottoStoreService();

  Position? _myPos;
  bool _loading = false;
  String? _error;
  bool _permissionDenied = false;
  bool _serviceDisabled = false;

  List<LottoStore> _stores = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  /// 로딩 전략 (체감 속도 최적화):
  ///
  /// 1. 권한/서비스 체크
  /// 2. `getLastKnownPosition()` — 수십 ms 만에 즉시 캐시 좌표 확보 →
  ///    있으면 곧장 RPC 호출해 1차 결과를 화면에 표시 (loading 해제)
  /// 3. 동시에 `getCurrentPosition(low, 10s)` 로 정확한 fresh 좌표 시도
  ///    - 캐시와 50 m 이내면 좌표만 갱신 (RPC 재호출 생략)
  ///    - 50 m 초과면 RPC 재호출해서 정렬·거리 갱신
  ///    - fresh 실패 + 캐시 없음 → 에러 안내
  Future<void> _refresh() async {
    // 이미 결과가 있으면 풀스크린 로딩을 띄우지 않고 silent refresh.
    setState(() {
      _loading = _stores.isEmpty;
      _error = null;
      _permissionDenied = false;
      _serviceDisabled = false;
    });

    if (!await _ensurePermission()) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _stores = const [];
      });
      return;
    }

    // ── 1차: 캐시된 마지막 위치 즉시 사용 ────────────────────────────
    Position? cached;
    try {
      cached = await Geolocator.getLastKnownPosition();
    } catch (_) {
      cached = null;
    }
    if (cached != null) {
      await _loadStoresFor(cached);
    }

    // ── 2차: fresh 위치 시도 ─────────────────────────────────────────
    try {
      final fresh = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;

      if (cached == null) {
        await _loadStoresFor(fresh);
        return;
      }

      final movedM = Geolocator.distanceBetween(
        cached.latitude,
        cached.longitude,
        fresh.latitude,
        fresh.longitude,
      );
      if (movedM > 50) {
        await _loadStoresFor(fresh);
      } else {
        setState(() => _myPos = fresh);
      }
    } catch (_) {
      // fresh 실패. 캐시 결과가 이미 있으면 그대로 유지.
      if (cached != null) return;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _stores = const [];
        if (!_serviceDisabled && !_permissionDenied && _error == null) {
          _error = '내 위치를 찾지 못했어요.\n'
              '실내·약전계 환경에서는 위치 확인이 더 오래 걸릴 수 있어요.\n'
              '하늘이 잘 보이는 곳에서 다시 시도하거나, 위치 정확도 설정을 확인해주세요.';
        }
      });
    }
  }

  /// 위치 서비스/권한 확인. false 면 `_serviceDisabled` 또는 `_permissionDenied` 가 세팅됨.
  Future<bool> _ensurePermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _serviceDisabled = true);
        return false;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _permissionDenied = true);
        return false;
      }
      return true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '위치 권한 확인 중 오류가 발생했어요.\n'
              '(${e.toString().replaceAll('Exception: ', '')})';
        });
      }
      return false;
    }
  }

  /// 주어진 좌표로 RPC 호출 후 결과 반영. 성공/실패 모두 loading 을 해제.
  Future<void> _loadStoresFor(Position pos) async {
    try {
      final stores = await _service.fetchNearbyStores(
        lat: pos.latitude,
        lng: pos.longitude,
      );
      if (!mounted) return;
      setState(() {
        _myPos = pos;
        _stores = stores;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      // 1차(캐시) 호출 실패 시 결과를 비우면 사용자가 화면이 깜빡거리는 경험을 함.
      // 기존 결과가 있으면 유지하고 에러만 표시하지 않는다.
      setState(() {
        _myPos = pos;
        _loading = false;
        if (_stores.isEmpty) {
          _error = '판매점 정보를 불러오지 못했어요.\n'
              '${e.toString().replaceAll('Exception: ', '')}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B33),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '내 주변 로또 판매점',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _stores.isNotEmpty
                      ? '내 위치 기준 가까운 순 ${_stores.length}곳'
                      : (_myPos != null
                            ? '내 위치 기준 가까운 순으로 정렬'
                            : (_loading ? '위치 확인 중…' : '위치 확인 필요')),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: '내 위치 다시 받기',
            onPressed: _loading ? null : _refresh,
            icon: Icon(
              _loading ? Icons.hourglass_top : Icons.my_location,
              color: _myPos != null
                  ? const Color(0xFF4FD1C5)
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    color: const Color(0xFFF5A623),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _myPos == null ? '내 위치를 빠르게 찾는 중…' : '주변 판매점을 불러오는 중…',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_serviceDisabled) {
      return _buildInfoState(
        icon: Icons.location_disabled,
        title: '위치 서비스가 꺼져 있어요',
        message: '시스템 설정에서 위치 서비스를 켠 후 다시 시도해주세요.',
        primaryLabel: '다시 시도',
        primaryAction: _refresh,
      );
    }
    if (_permissionDenied) {
      return _buildInfoState(
        icon: Icons.location_off_rounded,
        title: '위치 권한이 필요해요',
        message:
            '내 주변 로또 판매점을 거리순으로 보여드리려면 위치 권한이 필요합니다.\n'
            '권한 허용 후 다시 시도해주세요.',
        primaryLabel: '권한 다시 요청',
        primaryAction: _refresh,
        secondaryLabel: '앱 설정 열기',
        secondaryAction: () => Geolocator.openAppSettings(),
      );
    }
    if (_error != null) {
      return _buildInfoState(
        icon: Icons.error_outline,
        title: '판매점 정보를 불러오지 못했어요',
        message: _error!,
        primaryLabel: '다시 시도',
        primaryAction: _refresh,
        secondaryLabel: '동행복권에서 보기',
        secondaryAction: _openOfficial,
      );
    }
    if (_stores.isEmpty) {
      return _buildInfoState(
        icon: Icons.search_off,
        title: '내 위치 주변 판매점이 없어요',
        message: '반경 10km 안에 등록된 판매점이 없습니다.\n'
            '동행복권 공식 페이지에서 더 넓은 범위를 확인해 보세요.',
        primaryLabel: '다시 시도',
        primaryAction: _refresh,
        secondaryLabel: '동행복권에서 보기',
        secondaryAction: _openOfficial,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _stores.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = _stores[i];
        return _StoreCard(
          index: i + 1,
          store: s,
          distanceMeters: s.distanceMeters,
          onNavigate: () => NaverNavigation.open(
            context,
            storeName: s.name,
            address: s.address,
            dlat: s.hasCoordinate ? s.latitude : null,
            dlng: s.hasCoordinate ? s.longitude : null,
            slat: _myPos?.latitude,
            slng: _myPos?.longitude,
          ),
        );
      },
    );
  }

  Widget _buildInfoState({
    required IconData icon,
    required String title,
    required String message,
    required String primaryLabel,
    required VoidCallback primaryAction,
    String? secondaryLabel,
    VoidCallback? secondaryAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 44),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: primaryAction,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(primaryLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
            if (secondaryLabel != null && secondaryAction != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: secondaryAction,
                child: Text(
                  secondaryLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openOfficial() async {
    final uri = Uri.parse('https://www.dhlottery.co.kr/prchsplcsrch/home');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _StoreCard extends StatelessWidget {
  final int index;
  final LottoStore store;
  final double? distanceMeters;
  final VoidCallback onNavigate;

  const _StoreCard({
    required this.index,
    required this.store,
    required this.distanceMeters,
    required this.onNavigate,
  });

  String _formatDistance(double m) {
    if (m < 1000) return '${m.toStringAsFixed(0)}m';
    if (m < 10000) return '${(m / 1000).toStringAsFixed(1)}km';
    return '${(m / 1000).toStringAsFixed(0)}km';
  }

  @override
  Widget build(BuildContext context) {
    final dist = distanceMeters;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF5A623).withValues(alpha: 0.85),
                  const Color(0xFFFFC569).withValues(alpha: 0.6),
                ],
              ),
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        store.name.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (dist != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF4FD1C5,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(
                              0xFF4FD1C5,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _formatDistance(dist),
                          style: const TextStyle(
                            color: Color(0xFF4FD1C5),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  store.address,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                if ((store.phone ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        store.phone!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.directions, size: 16),
                    label: const Text(
                      '길찾기',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFF5A623,
                      ).withValues(alpha: 0.18),
                      foregroundColor: const Color(0xFFF5A623),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: const Color(
                            0xFFF5A623,
                          ).withValues(alpha: 0.4),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
}
