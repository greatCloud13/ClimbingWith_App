import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';
import '../../shell/record_or_manage_screen.dart' show gymManagerRole;
import '../application/home_providers.dart';
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
    final authState = ref.watch(authControllerProvider);
    final isAuthenticated = authState is AuthAuthenticated;
    final isGymManager =
        authState is AuthAuthenticated && authState.user.role == gymManagerRole;

    if (isGymManager) {
      return const _GymManagerHome();
    }

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
          // 연속방문 스트릭 / 친구 활동은 API 없어 목업으로 있던 것을 숨김
          // 처리함(2026-08-18) — 개발 완료되면 다시 추가 예정.
          const _HomeGymCardsSection(),
        ] else
          const SliverToBoxAdapter(child: _GuestPromptCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

/// GYM_MANAGER 전용 홈 — 캘린더 + 게시판 CRUD가 메인 콘텐츠. 레이아웃은
/// 사용자 와이어프레임 수령 후 확정 예정, 지금은 자리만 잡아둔 placeholder.
class _GymManagerHome extends StatelessWidget {
  const _GymManagerHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Text('암장 관리', style: theme.textTheme.headlineMedium),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ManagerPlaceholderCard(
                  icon: Icons.calendar_month_rounded,
                  title: '캘린더',
                  description: '셋팅일·이벤트 캘린더는 준비 중입니다.',
                ),
                const SizedBox(height: 16),
                _ManagerPlaceholderCard(
                  icon: Icons.dashboard_customize_rounded,
                  title: '게시판 관리',
                  description: '게시글을 작성·수정·삭제할 수 있어요.',
                  onTap: () => context.push('/gym-manage/board'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ManagerPlaceholderCard extends StatelessWidget {
  const _ManagerPlaceholderCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
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
            if (gymCard.notices.isNotEmpty) ...[
              const SizedBox(height: 12),
              _GymNoticeCarousel(
                notices: gymCard.notices,
                accent: accent,
                onNoticeTap: (notice) => _openNotice(context, notice),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 암장 카드에 종속된 공지 슬라이드 — 3초마다 다음 공지로 자동 전환된다.
/// 공지가 1개뿐이면 넘기지 않고 고정해서 보여준다.
class _GymNoticeCarousel extends StatefulWidget {
  const _GymNoticeCarousel({
    required this.notices,
    required this.accent,
    required this.onNoticeTap,
  });

  final List<HomeNoticeSummary> notices;
  final Color accent;
  final ValueChanged<HomeNoticeSummary> onNoticeTap;

  @override
  State<_GymNoticeCarousel> createState() => _GymNoticeCarouselState();
}

class _GymNoticeCarouselState extends State<_GymNoticeCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    if (widget.notices.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_controller.hasClients) return;
        _index = (_index + 1) % widget.notices.length;
        _controller.animateToPage(
          _index,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notices.length == 1) {
      return _NoticeRow(
        notice: widget.notices.first,
        accent: widget.accent,
        onTap: widget.onNoticeTap,
      );
    }

    return SizedBox(
      height: 72,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.notices.length,
        onPageChanged: (i) => _index = i,
        itemBuilder: (context, i) => _NoticeRow(
          notice: widget.notices[i],
          accent: widget.accent,
          onTap: widget.onNoticeTap,
        ),
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({
    required this.notice,
    required this.accent,
    required this.onTap,
  });

  final HomeNoticeSummary notice;
  final Color accent;
  final ValueChanged<HomeNoticeSummary> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onTap(notice),
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
                  const SizedBox(height: 2),
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
                '즐겨찾기 클라이밍장은 로그인 후 확인할 수 있어요.',
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
