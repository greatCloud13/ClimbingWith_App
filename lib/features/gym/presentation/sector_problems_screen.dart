import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../application/gym_providers.dart';
import '../data/gym_detail_mock_data.dart';
import '../domain/climbing_setting.dart';
import '../domain/gym_detail.dart';
import '../domain/gym_problem.dart';
import '../domain/sector.dart';

/// 섹터를 탭하면 나오는 문제 목록(조회 전용). 실제 암장(정수 sectorId)은
/// GET /api/sector/{id}로 진행 중인 세팅을 찾은 뒤 그 세팅의 문제 목록
/// (GET /api/problem/setting/{id})을 보여준다 — 목록 레이아웃은 매니저의
/// 문제관리 화면([problem_list_screen.dart])과 같은 형태(난이도 필터 칩 +
/// 색상 스와치)를 쓰되 등록/수정/삭제는 없다. 목업 암장(문자열 sectorId)은
/// 기존 Sector.problems 목업 데이터를 그대로 보여준다.
class SectorProblemsScreen extends ConsumerStatefulWidget {
  const SectorProblemsScreen({
    super.key,
    required this.gymId,
    required this.sectorId,
    this.gym,
    this.sector,
  });

  final String gymId;
  final String sectorId;
  final GymDetail? gym;
  final Sector? sector;

  @override
  ConsumerState<SectorProblemsScreen> createState() => _SectorProblemsScreenState();
}

class _SectorProblemsScreenState extends ConsumerState<SectorProblemsScreen> {
  /// null = 전체. 그 외에는 problem.levelId(없으면 gymLevel 이름)로 구분.
  Object? _selectedLevelKey;

  Object _levelKey(GymProblem p) => p.levelId ?? p.gymLevel;

  @override
  Widget build(BuildContext context) {
    final sectorIdInt = int.tryParse(widget.sectorId);
    return sectorIdInt != null ? _buildReal(context, sectorIdInt) : _buildMock(context);
  }

  Widget _buildReal(BuildContext context, int sectorId) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(sectorDetailProvider(sectorId));

    return Scaffold(
      appBar: AppBar(title: Text(detailAsync.valueOrNull?.sectorName ?? widget.sector?.name ?? '문제 목록')),
      body: MatTextureBackground(
        child: SafeArea(
          child: detailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('섹터 정보를 불러오지 못했어요.', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(sectorDetailProvider(sectorId)),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
            data: (detail) {
              ClimbingSetting? activeSetting;
              for (final s in detail.settingList) {
                if (s.active) {
                  activeSetting = s;
                  break;
                }
              }
              if (activeSetting == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('현재 진행 중인 세팅이 없어요.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
                  ),
                );
              }
              return _ProblemsBySetting(
                gymId: widget.gymId,
                sectorId: sectorId,
                settingId: activeSetting.id,
                selectedLevelKey: _selectedLevelKey,
                levelKey: _levelKey,
                onLevelSelected: (key) => setState(() => _selectedLevelKey = key),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMock(BuildContext context) {
    final resolvedGym = widget.gym ?? mockGymDetails[widget.gymId];
    final resolvedSector =
        widget.sector ?? resolvedGym?.sectors.firstWhere((s) => s.id == widget.sectorId);
    final theme = Theme.of(context);

    if (resolvedGym == null || resolvedSector == null) {
      return const Scaffold(body: Center(child: Text('섹터 정보를 찾을 수 없습니다.')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(resolvedSector.name)),
      body: MatTextureBackground(
        child: SafeArea(
          child: resolvedSector.problems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      resolvedSector.problemCount > 0
                          ? '문제 목록은 아직 준비 중입니다. (총 ${resolvedSector.problemCount}개)'
                          : '등록된 문제가 아직 없어요.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: resolvedSector.problems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final problem = resolvedSector.problems[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: problem.tapeColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    problem.grade,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${problem.setter} 셋팅 · ${problem.setDate}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// 세팅의 문제 목록 + 난이도 필터 칩. 매니저 문제관리 화면과 같은 카드 레이아웃을
/// 쓰되 조회 전용(등록/수정/삭제 없음).
class _ProblemsBySetting extends ConsumerWidget {
  const _ProblemsBySetting({
    required this.gymId,
    required this.sectorId,
    required this.settingId,
    required this.selectedLevelKey,
    required this.levelKey,
    required this.onLevelSelected,
  });

  final String gymId;
  final int sectorId;
  final int settingId;
  final Object? selectedLevelKey;
  final Object Function(GymProblem) levelKey;
  final ValueChanged<Object?> onLevelSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final problemsAsync = ref.watch(problemsBySettingProvider(settingId));

    return problemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('문제 목록을 불러오지 못했어요.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => ref.invalidate(problemsBySettingProvider(settingId)),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (problems) {
        if (problems.isEmpty) {
          return Center(child: Text('등록된 문제가 아직 없어요.', style: theme.textTheme.bodyMedium));
        }

        final levels = <Object, ({String label, Color? color})>{};
        for (final p in problems) {
          levels.putIfAbsent(levelKey(p), () => (label: p.gymLevel, color: p.levelColor));
        }
        final filtered = selectedLevelKey == null
            ? problems
            : problems.where((p) => levelKey(p) == selectedLevelKey).toList();

        return Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _LevelFilterChip(
                    label: '전체',
                    selected: selectedLevelKey == null,
                    onSelected: () => onLevelSelected(null),
                  ),
                  for (final entry in levels.entries) ...[
                    const SizedBox(width: 8),
                    _LevelFilterChip(
                      label: entry.value.label,
                      color: entry.value.color,
                      selected: selectedLevelKey == entry.key,
                      onSelected: () => onLevelSelected(entry.key),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('해당 난이도의 문제가 없어요.', style: theme.textTheme.bodyMedium))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final problem = filtered[i];
                        return Card(
                          child: InkWell(
                            onTap: () => context.push(
                              '/gym/$gymId/sector/$sectorId/problem/${problem.id}',
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: problem.levelColor ?? AppColors.textTertiary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.border),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        problem.gymLevel,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          problem.title,
                                          style: theme.textTheme.titleMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${climbTypeLabel(problem.problemType)} · 완등 ${problem.clearUserCount}명',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _LevelFilterChip extends StatelessWidget {
  const _LevelFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      avatar: color == null ? null : CircleAvatar(backgroundColor: color, radius: 6),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.holdLime.withValues(alpha: 0.22),
      backgroundColor: AppColors.surfaceElevated,
      side: BorderSide(color: selected ? AppColors.holdLime : AppColors.border),
      labelStyle: TextStyle(
        color: selected ? AppColors.holdLime : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      shape: const StadiumBorder(),
    );
  }
}
