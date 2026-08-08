import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 크래시 패드(볼더링 매트) 스티치 패턴을 흉내낸 배경 텍스처.
/// 그라데이션 블러 배경 대신 도메인에서 나온 모티프를 써서
/// 전형적인 "AI 배경"을 피한다. 아주 낮은 명도차로 은은하게만 보여야 함.
class MatTextureBackground extends StatelessWidget {
  const MatTextureBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: AppColors.background),
        Positioned.fill(
          child: CustomPaint(
            painter: _DiamondStitchPainter(),
          ),
        ),
        child,
      ],
    );
  }
}

class _DiamondStitchPainter extends CustomPainter {
  static const double _cell = 46;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;

    for (double x = -size.height; x < size.width + size.height; x += _cell) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), linePaint);
      canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), linePaint);
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.2,
        colors: [
          AppColors.holdLime.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.6));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.6), vignette);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
