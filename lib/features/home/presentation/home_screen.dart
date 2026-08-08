import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';
import '../application/home_providers.dart';
import '../data/home_mock_data.dart';
import '../domain/friend_activity.dart';
import '../domain/home_gym_card.dart';
import '../domain/notice.dart';

const _cardAccents = [
  AppColors.holdLime,
  AppColors.holdMagenta,
  AppColors.holdCyan,
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _notificationsTapped(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('알림 화면은 준비 중입니다.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAuthenticated =
        ref.watch(authControllerProvider) is AuthAuthenticated;

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
                itemBuilder: (context, i) =>
                    _FriendActivityCard(activity: mockFriendActivities[i]),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          const _HomeGymCardsSection(),
        ] else
          const SliverToBoxAdapter(child: _GuestPromptCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

/// GET /api/home 결과를 로딩/에러/빈 상태까지 포함해서 보여준다.
class _HomeGymCardsSection extends ConsumerWidget {
  const _HomeGymCardsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymCardsAsync = ref.watch(homeGymCardsProvider);

    return SliverToBoxAdapter(
      child: gymCardsAsync.when(
        data: (gymCards) {
          if (gymCards.isEmpty) {
            return const _EmptyGymBookmarksCard();
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (var i = 0; i < gymCards.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == gymCards.length - 1 ? 0 : 16,
                    ),
                    child: _GymFeedCard(
                      gymCard: gymCards[i],
                      accent: _cardAccents[i % _cardAccents.length],
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => _HomeGymCardsErrorCard(
          onRetry: () => ref.invalidate(homeGymCardsProvider),
        ),
      ),
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
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.holdMagenta,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$mockStreakDays일 연속 방문 중',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '이번달 완등 $mockMonthlyClimbCount회',
                      style: theme.textTheme.bodyMedium,
                    ),
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
              style: TextStyle(
                color: activity.accent,
                fontWeight: FontWeight.w800,
              ),
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

/// 즐겨찾기(북마크) 암장 피드 카드 — 암장 이름 + 메인 사진 + 그 암장의 최근 공지(있으면).
class _GymFeedCard extends StatelessWidget {
  const _GymFeedCard({required this.gymCard, required this.accent});

  final HomeGymCard gymCard;
  final Color accent;

  void _openGym(BuildContext context) => context.push('/gym/${gymCard.gymId}');

  void _openNotice(BuildContext context, HomeNoticeSummary notice) {
    final detail = Notice(
      id: notice.postId.toString(),
      title: notice.noticeTitle,
      subtitle: notice.date,
      body: '자세한 공지 내용은 곧 제공될 예정입니다.',
      accent: accent,
    );
    context.push('/notice/${detail.id}', extra: detail);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notice = gymCard.notices.isNotEmpty ? gymCard.notices.first : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _openGym(context),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gymCard.gymName,
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          gymCard.address,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _openGym(context),
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: gymCard.imageUrl != null
                      ? Image.network(
                          gymCard.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _GymPhotoPlaceholder(accent: accent),
                        )
                      : _GymPhotoPlaceholder(accent: accent),
                ),
              ),
            ),
            if (notice != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _openNotice(context, notice),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
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
                          color: accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notice.noticeTitle,
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              notice.date,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GymPhotoPlaceholder extends StatelessWidget {
  const _GymPhotoPlaceholder({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.22), AppColors.surfaceElevated],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.terrain_rounded,
          color: accent.withValues(alpha: 0.7),
          size: 40,
        ),
      ),
    );
  }
}

/// 로그아웃 상태 — 로그인 유도와 함께, 로그인 없이도 볼 수 있는 암장 목록으로 안내한다.
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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.push('/login'),
                      child: const Text('로그인하기'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/gym'),
                      child: const Text('암장 리스트 보기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 로그인 상태지만 북마크한 암장이 없는 경우.
class _EmptyGymBookmarksCard extends StatelessWidget {
  const _EmptyGymBookmarksCard();

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
              Text('아직 즐겨찾기한 암장이 없어요', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                '암장 목록에서 자주 가는 곳을 즐겨찾기해보세요.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => context.go('/gym'),
                child: const Text('등록된 암장 리스트 보기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeGymCardsErrorCard extends StatelessWidget {
  const _HomeGymCardsErrorCard({required this.onRetry});

  final VoidCallback onRetry;

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
              Text('암장 정보를 불러오지 못했어요', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                '네트워크 상태를 확인하고 다시 시도해주세요.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ),
        ),
      ),
    );
  }
}
