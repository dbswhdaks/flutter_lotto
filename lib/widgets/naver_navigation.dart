import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 네이버 지도 길찾기 실행 헬퍼.
///
/// 경마Plus 프로젝트(`branches_screen.dart::_openNaverDirections`)와 동일한 패턴:
///
/// 1. `canLaunchUrl` 검사를 생략하고 곧바로 `launchUrl(nmap://...)`를 시도해
///    Android 패키지 가시성 IPC 왕복(보통 300~800ms)을 없앤다.
/// 2. 네이버 지도 앱 미설치 시 `launchUrl`이 `false`/예외를 돌려주므로
///    그때 `map.naver.com` 모바일 웹으로 폴백한다.
/// 3. 사용자의 현재 좌표(`slat`/`slng`)를 함께 전달해 출발지·도착지 경로가
///    바로 그려진다(앱 내에서 출발지 검색 단계 생략).
class NaverNavigation {
  const NaverNavigation._();

  /// 네이버 지도로 길찾기를 연다.
  ///
  /// - [dlat]/[dlng] 가 있으면 자동차 길찾기(`nmap://route/car`).
  /// - 좌표가 없으면 [address] 또는 [storeName] 으로 장소 검색(`nmap://search`).
  /// - [slat]/[slng] 가 있으면 출발지로 사용. 없어도 동작.
  static Future<void> open(
    BuildContext context, {
    required String storeName,
    required String address,
    double? dlat,
    double? dlng,
    double? slat,
    double? slng,
  }) async {
    final hasDest = dlat != null && dlng != null;

    final appUri = hasDest
        ? _routeAppUri(
            storeName: storeName,
            dlat: dlat,
            dlng: dlng,
            slat: slat,
            slng: slng,
          )
        : _searchAppUri(query: address.isNotEmpty ? address : storeName);

    var launched = false;
    try {
      launched = await launchUrl(appUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (launched) return;

    final webUri = hasDest
        ? _routeWebUri(
            storeName: storeName,
            dlat: dlat,
            dlng: dlng,
            slat: slat,
            slng: slng,
          )
        : _searchWebUri(query: address.isNotEmpty ? address : storeName);

    final ok = await launchUrl(webUri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('네이버 지도를 열 수 없습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  static Uri _routeAppUri({
    required String storeName,
    required double dlat,
    required double dlng,
    double? slat,
    double? slng,
  }) {
    final dname = Uri.encodeComponent(storeName);
    final q = StringBuffer('dlat=$dlat&dlng=$dlng&dname=$dname');
    if (slat != null && slng != null) {
      q
        ..write('&slat=$slat')
        ..write('&slng=$slng')
        ..write('&sname=${Uri.encodeComponent('내 위치')}');
    }
    q.write('&appname=com.example.flutter_lotto');
    return Uri.parse('nmap://route/car?$q');
  }

  static Uri _routeWebUri({
    required String storeName,
    required double dlat,
    required double dlng,
    double? slat,
    double? slng,
  }) {
    final start = (slat != null && slng != null)
        ? '$slng,$slat,${Uri.encodeComponent('내 위치')},,PLACE_POI'
        : '-';
    final goal = '$dlng,$dlat,${Uri.encodeComponent(storeName)},,PLACE_POI';
    return Uri.parse('https://map.naver.com/p/directions/$start/$goal/-/car');
  }

  static Uri _searchAppUri({required String query}) {
    return Uri.parse(
      'nmap://search?query=${Uri.encodeComponent(query)}'
      '&appname=com.example.flutter_lotto',
    );
  }

  static Uri _searchWebUri({required String query}) {
    return Uri.parse(
      'https://map.naver.com/p/search/${Uri.encodeComponent(query)}',
    );
  }
}
