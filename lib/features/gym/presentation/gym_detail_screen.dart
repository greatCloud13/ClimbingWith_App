import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../data/gym_detail_mock_data.dart';
import '../domain/climbing_discipline.dart';
import '../domain/difficulty_level.dart';
import '../domain/gym_detail.dart';
import '../domain/gym_type.dart';

class GymDetailScreen extends StatefulWidget {
  const GymDetailScreen({super.key, required this.gymId});

  final String gymId;

  @override
  State<GymDetailScreen> createState() => _GymDetailScreenState();
}

class _GymDetailScreenState extends State<GymDetailScreen> {
  // 즐겨찾기/알림 구독 API가 아직 없어 로컬 상태로만 토글한다 (새로고침 시 초기화됨).
  bool _isFavorite = false;
  bool _notificationsOn = false;
  int _photoIndex = 0;

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
    final gym = mockGymDetails[widget.gymId];
    final theme = Theme.of(context);

    if (gym == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('암장 정보를 찾을 수 없습니다.')),
      );
    }

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
                  index: _photoIndex,
                  onIndexChanged: (i) => setState(() => _photoIndex = i),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => setState(() => _isFavorite = !_isFavorite),
                  icon: Icon(
                    _isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: _isFavorite
                        ? const Color(0xFFFFC53D)
                        : AppColors.textPrimary,
                  ),
                  tooltip: '즐겨찾기',
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => _notificationsOn = !_notificationsOn),
                  icon: Icon(
                    _notificationsOn
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: _notificationsOn
                        ? gym.accent
                        : AppColors.textPrimary,
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
                          onPressed: () => _openDirections(gym),
                          icon: const Icon(Icons.directions_rounded, size: 16),
                          label: const Text('길찾기'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showPricePlans(gym),
                          icon: const Icon(Icons.sell_outlined, size: 16),
                          label: const Text('가격보기'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  const SizedBox(height: 28),
                  Text('난이도 체계', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
                  _DifficultySection(gym: gym),
                  const SizedBox(height: 28),
                  Text('섹터', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 10),
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
                                            style: theme.textTheme.titleMedium,
                                          ),
                                          if (gym.gymType == GymType.both) ...[
                                            const SizedBox(width: 6),
                                            _DisciplineTag(
                                              discipline: sector.discipline,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${sector.description} · 문제 ${sector.problems.length}개',
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          onPageChanged: onIndexChanged,
          itemCount: gym.photos.length,
          itemBuilder: (context, i) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gym.photos[i].withValues(alpha: 0.28),
                  AppColors.surfaceElevated,
                ],
              ),
            ),
            child: Center(
              child: Icon(
                _icons[i % _icons.length],
                color: gym.photos[i].withValues(alpha: 0.7),
                size: 56,
              ),
            ),
          ),
        ),
        if (gym.photos.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                gym.photos.length,
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

    if (gym.gymType == GymType.boulder) {
      return _BoulderLevelStrip(levels: gym.boulderDifficultySystem);
    }
    if (gym.gymType == GymType.lead) {
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
