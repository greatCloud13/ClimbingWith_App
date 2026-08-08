import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 헤드라인은 BlackHanSans(포스터 느낌 굵은 고딕)로 임팩트를 주고,
/// 본문은 NotoSansKR로 가독성을 확보한다. 두 패밀리를 섞어 쓰되
/// 헤드라인 폰트는 본문/버튼에 쓰지 않는다 (가독성 저하).
///
/// 폰트는 런타임에 네트워크로 받아오지 않고 assets/fonts에 로컬 번들링한다.
/// (google_fonts 패키지의 웹 런타임 페치가 프리뷰 환경에서 실패해 한글이
/// 렌더링되지 않는 문제가 있었음 — pubspec.yaml의 fonts 섹션 참고)
class AppTypography {
  AppTypography._();

  static const _headline = 'BlackHanSans';
  static const _body = 'NotoSansKR';

  static TextTheme get textTheme => const TextTheme(
    displayLarge: TextStyle(
      fontFamily: _headline,
      fontSize: 40,
      height: 1.1,
      color: AppColors.textPrimary,
    ),
    headlineLarge: TextStyle(
      fontFamily: _headline,
      fontSize: 28,
      height: 1.15,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: _headline,
      fontSize: 22,
      height: 1.2,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: _body,
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: _body,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: _body,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      height: 1.4,
    ),
    bodyMedium: TextStyle(
      fontFamily: _body,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontFamily: _body,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
    labelSmall: TextStyle(
      fontFamily: _body,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.textTertiary,
    ),
  );
}
