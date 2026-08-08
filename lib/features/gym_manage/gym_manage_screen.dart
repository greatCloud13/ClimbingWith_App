import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// GYM_MANAGER 역할 전용 탭. 상세 설계는 추후 별도로 진행 예정 — 현재는
/// 역할 기반 탭 분기 동작 확인을 위한 최소 구현.
class GymManageScreen extends StatelessWidget {
  const GymManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background,
          title: const Text('암장 관리'),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, color: AppColors.textTertiary, size: 40),
                const SizedBox(height: 12),
                Text('암장 관리 화면은 준비 중입니다.', style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
