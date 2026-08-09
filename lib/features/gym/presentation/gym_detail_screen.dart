import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';
import '../../home/application/home_providers.dart';
import '../application/gym_providers.dart';
import '../data/gym_detail_mock_data.dart';
import '../domain/climbing_discipline.dart';
import '../domain/difficulty_level.dart';
import '../domain/gym_detail.dart';
import '../domain/gym_type.dart';
import '../domain/sector.dart';

class GymDetailScreen extends ConsumerStatefulWidget {
  const GymDetailScreen({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymDetailScreen> createState() => _GymDetailScreenState();
}

class _GymDetailScreenState extends ConsumerState<GymDetailScreen> {
  // 즐겨찾기 등록/해제 API가 아직 없어 로컬에서 토글한 값(override)이 있으면
  // 그걸 우선 쓰고, 없으면 홈 화면의 즐겨찾기 목록(GET /api/home)에 이 암장이
  // 있는지로 초기 별 채움 여부를 판단한다. 알림 구독은 여전히 API가 없어
  // 로컬 상태로만 토글한다 (새로고침 시 초기화됨).
  bool? _favoriteOverride;
  bool _favoriteLoading = false;
  bool _notificationsOn = false;
  int _photoIndex = 0;

  bool _resolveFavorite(int? numericId) {
    if (_favoriteOverride != null) return _favoriteOverride!;
    if (numericId == null) return false;
    if (ref.watch(authControllerProvider) is! AuthAuthenticated) return false;
    return ref
        .watch(homeGymCardsProvider)
        .maybeWhen(
          data: (cards) => cards.any((c) => c.gymId == numericId),
          orElse: () => false,
        );
  }

  Future<void> _toggleFavorite(int numericId, bool currentlyFavorite) async {
    if (ref.read(authControllerProvider) is! AuthAuthenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }
    setState(() => _favoriteLoading = true);
    try {
      final api = ref.read(bookmarkApiProvider);
      final bookmarkIds = ref.read(bookmarkIdMapProvider);
      if (!currentlyFavorite) {
        final bookmarkId = await api.createBookmark(numericId);
        ref.read(bookmarkIdMapProvider.notifier).state = {
          ...bookmarkIds,
          numericId: bookmarkId,
        };
        if (mounted) setState(() => _favoriteOverride = true);
      } else {
        // 이번 세션에 등록한 북마크는 로컬 맵에 있고, 이전부터 즐겨찾기된
        // 암장은 GET /api/home의 bookmarkId(카드에 매칭된 값)로 찾는다.
        int? bookmarkId = bookmarkIds[numericId];
        if (bookmarkId == null) {
          final homeCards =
              ref.read(homeGymCardsProvider).valueOrNull ?? const [];
          for (final card in homeCards) {
            if (card.gymId == numericId) {
              bookmarkId = card.bookmarkId;
              break;
            }
          }
        }
        if (bookmarkId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('즐겨찾기 해제 정보를 찾을 수 없어요. 앱을 다시 시작한 뒤 시도해주세요.'),
              ),
            );
          }
          return;
        }
        await api.deleteBookmark(bookmarkId);
        final newMap = {...bookmarkIds}..remove(numericId);
        ref.read(bookmarkIdMapProvider.notifier).state = newMap;
        if (mounted) setState(() => _favoriteOverride = false);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('즐겨찾기 처리 중 문제가 발생했어요.')));
      }
    } finally {
      if (mounted) setState(() => _favoriteLoading = false);
    }
  }

  void _openDirections(GymDetail gym) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${gym.address}로 길찾기는 준비 중입니다.')));
  }

  void _showPricePlans(GymDetail gym) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이용권', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 16),
                for (final plan in gym.pricePlans)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.label,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        Text(
                          plan.price,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: gym.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 목업 암장은 문자열 id('seongsu' 등), 실제 암장은 정수 id — 정수로 파싱되면
    // GET /api/gym/{id}로 실제 데이터를 가져오고, 아니면 목업에서 찾는다.
    final numericId = int.tryParse(widget.gymId);
    if (numericId == null) {
      final gym = mockGymDetails[widget.gymId];
      if (gym == null) {
        return const Scaffold(body: Center(child: Text('암장 정보를 찾을 수 없습니다.')));
      }
      final isFavorite = _resolveFavorite(null);
      return _GymDetailBody(
        gym: gym,
        isFavorite: isFavorite,
        favoriteLoading: false,
        notificationsOn: _notificationsOn,
        photoIndex: _photoIndex,
        // 목업 암장은 실제 gymId가 없어 북마크 API를 호출할 수 없다 — 로컬 토글만.
        onFavoriteToggle: () => setState(() => _favoriteOverride = !isFavorite),
        onNotificationToggle: () =>
            setState(() => _notificationsOn = !_notificationsOn),
        onPhotoIndexChanged: (i) => setState(() => _photoIndex = i),
        onDirectionsTap: _openDirections,
        onPricePlansTap: _showPricePlans,
        onNoticesTap: (g) =>
            context.push('/gym/${g.id}/board', extra: g.accent),
      );
    }

    final gymAsync = ref.watch(gymDetailProvider(numericId));
    final isFavorite = _resolveFavorite(numericId);
    return gymAsync.when(
      data: (gym) => _GymDetailBody(
        gym: gym,
        isFavorite: isFavorite,
        favoriteLoading: _favoriteLoading,
        notificationsOn: _notificationsOn,
        photoIndex: _photoIndex,
        onFavoriteToggle: () => _toggleFavorite(numericId, isFavorite),
        onNotificationToggle: () =>
            setState(() => _notificationsOn = !_notificationsOn),
        onPhotoIndexChanged: (i) => setState(() => _photoIndex = i),
        onDirectionsTap: _openDirections,
        onPricePlansTap: _showPricePlans,
        onNoticesTap: (g) =>
            context.push('/gym/${g.id}/board', extra: g.accent),
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('암장 정보를 불러오지 못했어요.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.invalidate(gymDetailProvider(numericId)),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GymDetailBody extends StatelessWidget {
  const _GymDetailBody({
    required this.gym,
    required this.isFavorite,
    required this.favoriteLoading,
    required this.notificationsOn,
    required this.photoIndex,
    required this.onFavoriteToggle,
    required this.onNotificationToggle,
    required this.onPhotoIndexChanged,
    required this.onDirectionsTap,
    required this.onPricePlansTap,
    required this.onNoticesTap,
  });

  final GymDetail gym;
  final bool isFavorite;
  final bool favoriteLoading;
  final bool notificationsOn;
  final int photoIndex;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onNotificationToggle;
  final ValueChanged<int> onPhotoIndexChanged;
  final void Function(GymDetail) onDirectionsTap;
  final void Function(GymDetail) onPricePlansTap;
  final void Function(GymDetail) onNoticesTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDifficultyData =
        gym.boulderDifficultySystem.isNotEmpty ||
        gym.leadDifficultySystem.isNotEmpty;

    return Scaffold(
      body: MatTextureBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background,
              expandedHeight: 220,
              flexibleSpace: FlexibleSpaceBar(
                background: _GymPhotoGallery(
                  gym: gym,
                  index: photoIndex,
                  onIndexChanged: onPhotoIndexChanged,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: favoriteLoading ? null : onFavoriteToggle,
                  icon: favoriteLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isFavorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: isFavorite
                              ? const Color(0xFFFFC53D)
                              : AppColors.textPrimary,
                        ),
                  tooltip: '즐겨찾기',
                ),
                IconButton(
                  onPressed: onNotificationToggle,
                  icon: Icon(
                    notificationsOn
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: notificationsOn ? gym.accent : AppColors.textPrimary,
                  ),
                  tooltip: '알림 받기',
                ),
                const SizedBox(width: 4),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: gym.accent.withValues(alpha: 0.18),
                        child: Text(
                          gym.name.characters.first,
                          style: TextStyle(
                            color: gym.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gym.name,
                              style: theme.textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    gym.businessHours,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          gym.address,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onDirectionsTap(gym),
                          icon: const Icon(Icons.directions_rounded, size: 16),
                          label: const Text('길찾기'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                          ),
                        ),
                      ),
                      if (gym.pricePlans.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => onPricePlansTap(gym),
                            icon: const Icon(Icons.sell_outlined, size: 16),
                            label: const Text('가격보기'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ),
                      ],
                      // 목업 암장(문자열 id)은 실제 게시글 API 대상이 아니라 버튼을 숨긴다.
                      if (int.tryParse(gym.id) != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => onNoticesTap(gym),
                            icon: const Icon(Icons.forum_outlined, size: 16),
                            label: const Text('게시판'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (gym.hashtags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: gym.hashtags
                          .map(
                            (t) => Chip(
                              label: Text(t),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text('난이도 체계', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                  if (hasDifficultyData)
                    _DifficultySection(gym: gym)
                  else
                    Text(
                      '난이도 정보가 아직 등록되지 않았어요.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 28),
                  Text('섹터', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                  if (gym.sectors.isEmpty)
                    Text('등록된 섹터가 아직 없어요.', style: theme.textTheme.bodyMedium)
                  else
                    ...gym.sectors.map(
                      (sector) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => context.push(
                            '/gym/${gym.id}/sector/${sector.id}',
                            extra: {'gym': gym, 'sector': sector},
                          ),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              sector.name,
                                              style:
                                                  theme.textTheme.titleMedium,
                                            ),
                                            if (gym.gymType ==
                                                GymType.both) ...[
                                              const SizedBox(width: 6),
                                              _DisciplineTag(
                                                discipline: sector.discipline,
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _sectorSubtitle(sector),
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
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sectorSubtitle(Sector sector) {
    final parts = <String>[];
    if (sector.description != null && sector.description!.isNotEmpty) {
      parts.add(sector.description!);
    }
    parts.add('문제 ${sector.problemCount}개');
    if (sector.settingDate != null) {
      parts.add('최근 셋팅 ${sector.settingDate}');
    }
    return parts.join(' · ');
  }
}

class _GymPhotoGallery extends StatelessWidget {
  const _GymPhotoGallery({
    required this.gym,
    required this.index,
    required this.onIndexChanged,
  });

  final GymDetail gym;
  final int index;
  final ValueChanged<int> onIndexChanged;

  static const _icons = [
    Icons.terrain_rounded,
    Icons.groups_rounded,
    Icons.emoji_events_rounded,
  ];

  bool get _hasRealPhotos => gym.imageUrls.isNotEmpty;

  int get _count => _hasRealPhotos
      ? gym.imageUrls.length
      : (gym.photos.isEmpty ? 1 : gym.photos.length);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          onPageChanged: onIndexChanged,
          itemCount: _count,
          itemBuilder: (context, i) {
            if (_hasRealPhotos) {
              return Image.network(
                gym.imageUrls[i],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(i),
              );
            }
            return _placeholder(i);
          },
        ),
        if (_count > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _count,
                (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == index
                        ? AppColors.textPrimary
                        : AppColors.textPrimary.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _placeholder(int i) {
    final accent = gym.photos.isEmpty
        ? gym.accent
        : gym.photos[i % gym.photos.length];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.28), AppColors.surfaceElevated],
        ),
      ),
      child: Center(
        child: Icon(
          _icons[i % _icons.length],
          color: accent.withValues(alpha: 0.7),
          size: 56,
        ),
      ),
    );
  }
}

/// gymType에 따라 난이도 체계를 다르게 보여준다.
/// BOULDER → 색 스트립만, LEAD → 라벨+색 리스트만, BOTH → 좌우 스와이프로 둘 다.
class _DifficultySection extends StatefulWidget {
  const _DifficultySection({required this.gym});

  final GymDetail gym;

  @override
  State<_DifficultySection> createState() => _DifficultySectionState();
}

class _DifficultySectionState extends State<_DifficultySection> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final gym = widget.gym;

    if (gym.gymType == GymType.boulder || gym.leadDifficultySystem.isEmpty) {
      return _BoulderLevelStrip(levels: gym.boulderDifficultySystem);
    }
    if (gym.gymType == GymType.lead || gym.boulderDifficultySystem.isEmpty) {
      return _LeadLevelList(levels: gym.leadDifficultySystem);
    }

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: PageView(
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              _BoulderLevelStrip(levels: gym.boulderDifficultySystem),
              _LeadLevelList(levels: gym.leadDifficultySystem),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PageDot(active: _page == 0, label: '볼더'),
            const SizedBox(width: 8),
            _PageDot(active: _page == 1, label: '리드'),
          ],
        ),
      ],
    );
  }
}

/// 볼더링 난이도 — 왼쪽(쉬움)에서 오른쪽(어려움)으로 가는 색 스트립.
/// 암장마다 단계 수·색이 다르므로 항상 gym 데이터 길이만큼만 그린다.
class _BoulderLevelStrip extends StatelessWidget {
  const _BoulderLevelStrip({required this.levels});

  final List<DifficultyLevel> levels;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          for (final level in levels)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: level.color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LeadLevelList extends StatelessWidget {
  const _LeadLevelList({required this.levels});

  final List<DifficultyLevel> levels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 14,
      runSpacing: 10,
      children: levels
          .map(
            (d) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: d.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                const SizedBox(width: 6),
                Text(d.label, style: theme.textTheme.bodyMedium),
              ],
            ),
          )
          .toList(),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active, required this.label});

  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.holdLime : AppColors.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DisciplineTag extends StatelessWidget {
  const _DisciplineTag({required this.discipline});

  final ClimbingDiscipline discipline;

  @override
  Widget build(BuildContext context) {
    final isLead = discipline == ClimbingDiscipline.lead;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isLead ? '리드' : '볼더',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
