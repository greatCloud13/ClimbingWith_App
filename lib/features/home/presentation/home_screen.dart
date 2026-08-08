import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';
import '../data/home_mock_data.dart';
import '../domain/favorite_gym.dart';
import '../domain/friend_activity.dart';
import '../domain/notice.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openNotice(BuildContext context, Notice notice) {
    context.push('/notice/${notice.id}', extra: notice);
  }

  void _notificationsTapped(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알림 화면은 준비 중입니다.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAuthenticated = ref.watch(authControllerProvider) is AuthAuthenticated;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 12, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '오늘은 어느 암장으로\n가실건가요?',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  onPressed: () => _notificationsTapped(context),
                  icon: const Icon(Icons.notifications_none_rounded),
                  tooltip: '알림',
                ),
              ],
            ),
          ),
        ),
        if (isAuthenticated) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          const SliverToBoxAdapter(child: _StreakStatCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(child: _SectionHeader(title: '친구 활동')),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: mockFriendActivities.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _FriendActivityCard(activity: mockFriendActivities[i]),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: mockFavoriteGyms.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, i) => _GymFeedCard(
                gym: mockFavoriteGyms[i],
                onNoticeTap: () => _openNotice(context, mockFavoriteGyms[i].notice),
              ),
            ),
          ),
        ] else
          const SliverToBoxAdapter(child: _GuestPromptCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _StreakStatCard extends StatelessWidget {
  const _StreakStatCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, color: AppColors.holdMagenta, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$mockStreakDays일 연속 방문 중', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text('이번달 완등 $mockMonthlyClimbCount회', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendActivityCard extends StatelessWidget {
  const _FriendActivityCard({required this.activity});

  final FriendActivity activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: activity.accent.withValues(alpha: 0.18),
            child: Text(
              activity.friendNickname.characters.first,
              style: TextStyle(color: activity.accent, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity.friendNickname} · ${activity.grade} 완등',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${activity.gymName} · ${activity.timeAgo}',
                  style: theme.textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 즐겨찾기 암장 피드 카드 — 암장 이름 + 메인 사진 + 그 암장에 종속된 공지.
class _GymFeedCard extends StatelessWidget {
  const _GymFeedCard({required this.gym, required this.onNoticeTap});

  final FavoriteGym gym;
  final VoidCallback onNoticeTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => context.go('/gym'),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(gym.name, style: theme.textTheme.titleLarge),
                        Text(gym.area, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => context.go('/gym'),
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [gym.accent.withValues(alpha: 0.22), AppColors.surfaceElevated],
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.terrain_rounded, color: gym.accent.withValues(alpha: 0.7), size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onNoticeTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 32,
                      decoration: BoxDecoration(
                        color: gym.notice.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(gym.notice.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(gym.notice.subtitle, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestPromptCard extends StatelessWidget {
  const _GuestPromptCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('로그인하고 더 많은 기능을 만나보세요', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                '즐겨찾기 클라이밍장, 완등 스트릭, 친구 활동은 로그인 후 확인할 수 있어요.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                child: const Text('로그인하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
