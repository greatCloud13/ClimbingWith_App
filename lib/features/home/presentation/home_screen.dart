import 'dart:async';
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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _noticeController = PageController(viewportFraction: 0.88);
  Timer? _timer;
  int _noticeIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_noticeController.hasClients) return;
      _noticeIndex = (_noticeIndex + 1) % mockNotices.length;
      _noticeController.animateToPage(
        _noticeIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _noticeController.dispose();
    super.dispose();
  }

  void _openNotice(Notice notice) {
    context.push('/notice/${notice.id}', extra: notice);
  }

  void _notificationsTapped() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알림 화면은 준비 중입니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: _notificationsTapped,
                  icon: const Icon(Icons.notifications_none_rounded),
                  tooltip: '알림',
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        const SliverToBoxAdapter(child: _SectionHeader(title: '주요 공지')),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 118,
            child: PageView.builder(
              controller: _noticeController,
              itemCount: mockNotices.length,
              onPageChanged: (i) => _noticeIndex = i,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _NoticeCard(notice: mockNotices[i], onTap: () => _openNotice(mockNotices[i])),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        if (isAuthenticated) ...[
          const SliverToBoxAdapter(child: _StreakStatCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const SliverToBoxAdapter(child: _SectionHeader(title: '즐겨찾기 클라이밍장')),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: mockFavoriteGyms.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _FavoriteGymCard(gym: mockFavoriteGyms[i]),
              ),
            ),
          ),
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

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.onTap});

  final Notice notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(color: notice.accent, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(notice.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(notice.subtitle, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
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

class _FavoriteGymCard extends StatelessWidget {
  const _FavoriteGymCard({required this.gym});

  final FavoriteGym gym;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.go('/gym'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gym.accent.withValues(alpha: 0.20), AppColors.surfaceElevated],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.terrain_rounded, color: gym.accent, size: 24),
            const SizedBox(height: 10),
            Text(gym.name, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(gym.area, style: theme.textTheme.labelSmall),
          ],
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
