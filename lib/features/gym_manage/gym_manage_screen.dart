import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../auth/application/auth_providers.dart';
import '../auth/application/auth_state.dart';
import '../gym/application/gym_providers.dart';
import '../gym/domain/gym_level.dart';
import '../gym/domain/gym_problem.dart';
import '../gym/domain/gym_type.dart';
import '../gym/domain/sector.dart';

/// GYM_MANAGER 역할 전용 탭 — 문제(루트) 관리. "섹터" 탭은 depth(섹터→세팅→문제)의
/// 첫 단계, "난이도" 탭은 문제 등록에 쓰이는 난이도(GymLevel) 자체의 관리다.
/// 게시판 CRUD는 여기 아니라 홈 화면 쪽에 위치한다(HomeScreen 참고).
class GymManageScreen extends ConsumerStatefulWidget {
  const GymManageScreen({super.key});

  @override
  ConsumerState<GymManageScreen> createState() => _GymManageScreenState();
}

class _GymManageScreenState extends ConsumerState<GymManageScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int? get _gymId {
    final authState = ref.watch(authControllerProvider);
    return authState is AuthAuthenticated ? authState.user.managedGymId : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gymId = _gymId;

    if (gymId == null) {
      return CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            title: const Text('문제 관리'),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('관리 중인 암장 정보를 찾을 수 없어요.', style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('문제 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '섹터'), Tab(text: '난이도')],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? _SectorFab(gymId: gymId)
          : _LevelFab(gymId: gymId),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SectorTab(gymId: gymId),
          _LevelTab(gymId: gymId),
        ],
      ),
    );
  }
}

class _SectorFab extends ConsumerWidget {
  const _SectorFab({required this.gymId});

  final int gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymDetailAsync = ref.watch(gymDetailProvider(gymId));
    return gymDetailAsync.maybeWhen(
      data: (gym) => FloatingActionButton.extended(
        onPressed: () => _openSectorForm(context, ref, gymId, gym.gymType),
        icon: const Icon(Icons.add_rounded),
        label: const Text('새 섹터'),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _LevelFab extends ConsumerWidget {
  const _LevelFab({required this.gymId});

  final int gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _openLevelForm(context, ref, gymId),
      icon: const Icon(Icons.add_rounded),
      label: const Text('새 난이도'),
    );
  }
}

Future<void> _openSectorForm(
  BuildContext context,
  WidgetRef ref,
  int gymId,
  GymType gymType, {
  Sector? editing,
}) async {
  final saved = await context.push<bool>('/gym-manage/sector/write', extra: {
    'gymType': gymType,
    'sector': editing,
  });
  if (saved == true) ref.invalidate(gymDetailProvider(gymId));
}

void _openSectorSettings(BuildContext context, Sector sector) {
  context.push('/gym-manage/sector/${sector.id}');
}

Future<void> _openLevelForm(
  BuildContext context,
  WidgetRef ref,
  int gymId, {
  GymLevel? editing,
}) async {
  final saved = await context.push<bool>('/gym-manage/level/write', extra: editing);
  if (saved == true) ref.invalidate(levelsByGymProvider(gymId));
}

class _SectorTab extends ConsumerWidget {
  const _SectorTab({required this.gymId});

  final int gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final gymDetailAsync = ref.watch(gymDetailProvider(gymId));

    return gymDetailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('암장 정보를 불러오지 못했어요.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => ref.invalidate(gymDetailProvider(gymId)),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (gym) {
        if (gym.sectors.isEmpty) {
          return Center(
            child: Text('등록된 섹터가 아직 없어요. 우측 하단 버튼으로 추가해보세요.', style: theme.textTheme.bodyMedium),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          itemCount: gym.sectors.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final sector = gym.sectors[i];
            return Card(
              child: InkWell(
                onTap: () => _openSectorSettings(context, sector),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sector.name, style: theme.textTheme.titleMedium),
                            if (sector.description != null && sector.description!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                sector.description!,
                                style: theme.textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '문제 ${sector.problemCount}개'
                              '${sector.settingDate != null ? ' · 세팅일 ${sector.settingDate}' : ''}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openSectorForm(context, ref, gymId, gym.gymType, editing: sector),
                        icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                        tooltip: '섹터 정보 수정',
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LevelTab extends ConsumerWidget {
  const _LevelTab({required this.gymId});

  final int gymId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, GymLevel level) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('난이도 삭제'),
        content: Text('"${level.levelName}" 난이도를 삭제할까요? 이 난이도를 쓰는 문제가 있다면 삭제가 실패할 수 있어요.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(gymApiProvider).deleteLevel(level.id);
      ref.invalidate(levelsByGymProvider(gymId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제했습니다.')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('삭제하지 못했어요. 이 난이도를 쓰는 문제가 있는지 확인해주세요.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final levelsAsync = ref.watch(levelsByGymProvider(gymId));

    return levelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('난이도 목록을 불러오지 못했어요.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => ref.invalidate(levelsByGymProvider(gymId)),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (levels) {
        if (levels.isEmpty) {
          return Center(
            child: Text('등록된 난이도가 아직 없어요. 우측 하단 버튼으로 추가해보세요.', style: theme.textTheme.bodyMedium),
          );
        }

        final groups = <String, List<GymLevel>>{};
        for (final level in levels) {
          final key = level.climbType ?? '미지정';
          groups.putIfAbsent(key, () => []).add(level);
        }
        for (final group in groups.values) {
          group.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        }
        final orderedKeys = [
          ...climbTypes.where(groups.containsKey),
          if (groups.containsKey('미지정')) '미지정',
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            for (final key in orderedKeys) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Text(
                  key == '미지정' ? '미지정' : climbTypeLabel(key),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              for (final level in groups[key]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: parseHexColor(level.colorCode) ?? AppColors.textTertiary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(level.levelName, style: theme.textTheme.titleMedium),
                                if (level.description != null && level.description!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    level.description!,
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _openLevelForm(context, ref, gymId, editing: level),
                            icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                            tooltip: '수정',
                          ),
                          IconButton(
                            onPressed: () => _confirmDelete(context, ref, level),
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                            tooltip: '삭제',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
