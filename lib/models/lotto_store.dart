import 'dart:math' as math;

/// 동행복권 판매점 모델.
///
/// 두 가지 소스에서 만들어진다:
///
/// - [LottoStore.fromSupabase] : `public.nearby_lotto_stores` RPC 응답 (snake_case + `distance_m`)
/// - [LottoStore.fromJson]     : (legacy) 동행복권 API 직접 응답. 현재 앱에선 사용하지 않음.
class LottoStore {
  final String id;
  final String name;
  final String address;
  final String? sido;
  final String? sigungu;
  final String? dong;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final bool sellsLotto645;
  final bool sellsPension720;

  /// 서버가 계산해서 내려준 거리(m). 클라이언트 측 정렬·표시에 그대로 사용.
  /// 없을 수도 있음 → null.
  final double? distanceMeters;

  const LottoStore({
    required this.id,
    required this.name,
    required this.address,
    this.sido,
    this.sigungu,
    this.dong,
    this.phone,
    this.latitude,
    this.longitude,
    this.sellsLotto645 = false,
    this.sellsPension720 = false,
    this.distanceMeters,
  });

  bool get hasCoordinate =>
      latitude != null &&
      longitude != null &&
      latitude!.abs() > 0.0001 &&
      longitude!.abs() > 0.0001;

  /// 서버 거리 우선, 없으면 직접 계산.
  double? distanceTo(double lat, double lng) {
    if (distanceMeters != null) return distanceMeters;
    if (!hasCoordinate) return null;
    return _haversine(lat, lng, latitude!, longitude!);
  }

  /// Supabase RPC `nearby_lotto_stores` 응답 → 모델.
  factory LottoStore.fromSupabase(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString().trim();

    double? d(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return LottoStore(
      id: s(json['store_no']),
      name: s(json['name']),
      address: s(json['address']),
      sido: s(json['sido']).isEmpty ? null : s(json['sido']),
      sigungu: s(json['sigungu']).isEmpty ? null : s(json['sigungu']),
      dong: s(json['dong']).isEmpty ? null : s(json['dong']),
      phone: s(json['phone']).isEmpty ? null : s(json['phone']),
      latitude: d(json['latitude']),
      longitude: d(json['longitude']),
      sellsLotto645: json['sells_lotto645'] == true,
      sellsPension720: json['sells_pension720'] == true,
      distanceMeters: d(json['distance_m']),
    );
  }
}

double _haversine(double lat1, double lng1, double lat2, double lng2) {
  const earthR = 6371000.0;
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthR * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _toRad(double deg) => deg * math.pi / 180.0;
