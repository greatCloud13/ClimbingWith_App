import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../auth/application/auth_providers.dart';
import '../auth/application/auth_state.dart';

/// 상세 디자인은 추후 별도 설계안으로 교체 예정 — 현재는 라우팅 구조와
/// 로그아웃 동작 확인을 위한 최소 구현.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background,
          title: const Text('프로필'),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.holdLime.withValues(alpha: 0.16),
                          child: Text(
                            (user?.nickname.isNotEmpty ?? false) ? user!.nickname.characters.first : '?',
                            style: const TextStyle(color: AppColors.holdLime, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.nickname ?? '알 수 없음', style: theme.textTheme.titleLarge),
                              const SizedBox(height: 2),
                              Text('@${user?.username ?? '-'} · ${user?.role ?? '-'}', style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('로그아웃'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
