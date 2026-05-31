import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lotto_store.dart';

/// 동행복권 판매점 조회 서비스.
///
/// Supabase RPC `public.nearby_lotto_stores(p_lat, p_lng, p_radius_m, p_limit)` 를
/// 호출해 사용자 좌표 기준 반경 내 판매점을 거리순으로 가져온다.
///
/// 실제 동행복권 API 직접 호출은 Edge Function `crawl-lotto-stores` 가 주 1회
/// 실행하면서 `public.lotto_stores` 테이블을 갱신한다.
class LottoStoreService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// 좌표 기준 가까운 판매점 목록을 반환한다. 서버에서 거리·반경 필터·정렬을 끝낸 결과.
  ///
  /// - [radiusMeters] : 기본 10km
  /// - [limit]        : 기본 200개
  Future<List<LottoStore>> fetchNearbyStores({
    required double lat,
    required double lng,
    int radiusMeters = 10000,
    int limit = 200,
  }) async {
    final dynamic res = await _client.rpc(
      'nearby_lotto_stores',
      params: {
        'p_lat': lat,
        'p_lng': lng,
        'p_radius_m': radiusMeters,
        'p_limit': limit,
      },
    );

    if (res is! List) return const [];
    return res
        .whereType<Map<String, dynamic>>()
        .map(LottoStore.fromSupabase)
        .toList();
  }
}
