import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../../gym/application/gym_providers.dart';
import '../../gym/domain/gym_problem.dart';

/// 세팅에 속한 문제(루트) 목록. 세팅 카드를 탭하면 여기로 들어온다.
/// 난이도는 색상 코드가 있으면 [sector_problems_screen.dart]의 테이프색 원과
/// 같은 방식(원형 스와치)으로 보여주고, 상단 칩으로 난이도별 필터링한다.
class ProblemListScreen extends ConsumerStatefulWidget {
  const ProblemListScreen({super.key, required this.settingId});

  final int settingId;

  @override
  ConsumerState<ProblemListScreen> createState() => _ProblemListScreenState();
}

class _ProblemListScreenState extends ConsumerState<ProblemListScreen> {
  /// null = 전체. 그 외에는 problem.levelId(없으면 gymLevel 이름)로 구분.
  Object? _selectedLevelKey;

  Object _levelKey(GymProblem p) => p.levelId ?? p.gymLevel;

  Future<void> _openForm(GymProblem? editing) async {
    final saved = await context.push<bool>(
      '/gym-manage/setting/${widget.settingId}/problem/write',
      extra: editing,
    );
    if (saved == true) ref.invalidate(problemsBySettingProvider(widget.settingId));
  }

  Future<void> _confirmDelete(GymProblem problem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문제 삭제'),
        content: Text('"${problem.title}" 문제를 삭제할까요?'),
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
      await ref.read(gymApiProvider).deleteProblem(problem.id);
      ref.invalidate(problemsBySettingProvider(widget.settingId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제했습니다.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('삭제하지 못했어요. 다시 시도해주세요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final problemsAsync = ref.watch(problemsBySettingProvider(widget.settingId));

    return Scaffold(
      appBar: AppBar(title: const Text('문제 목록')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('새 문제'),
      ),
      body: MatTextureBackground(
        child: SafeArea(
          child: problemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('문제 목록을 불러오지 못했어요.', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(problemsBySettingProvider(widget.settingId)),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
            data: (problems) {
              if (problems.isEmpty) {
                return Center(
                  child: Text('등록된 문제가 아직 없어요. 우측 하단 버튼으로 추가해보세요.', style: theme.textTheme.bodyMedium),
                );
              }

              final levels = <Object, ({String label, Color? color})>{};
              for (final p in problems) {
                levels.putIfAbsent(_levelKey(p), () => (label: p.gymLevel, color: p.levelColor));
              }
              final filtered = _selectedLevelKey == null
                  ? problems
                  : problems.where((p) => _levelKey(p) == _selectedLevelKey).toList();

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
                          selected: _selectedLevelKey == null,
                          onSelected: () => setState(() => _selectedLevelKey = null),
                        ),
                        for (final entry in levels.entries) ...[
                          const SizedBox(width: 8),
                          _LevelFilterChip(
                            label: entry.value.label,
                            color: entry.value.color,
                            selected: _selectedLevelKey == entry.key,
                            onSelected: () => setState(() => _selectedLevelKey = entry.key),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text('해당 난이도의 문제가 없어요.', style: theme.textTheme.bodyMedium),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final problem = filtered[i];
                              return Card(
                                child: InkWell(
                                  onTap: () => _openForm(problem),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
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
                                        IconButton(
                                          onPressed: () => _confirmDelete(problem),
                                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                          tooltip: '삭제',
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
          ),
        ),
      ),
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
      avatar: color == null
          ? null
          : CircleAvatar(backgroundColor: color, radius: 6),
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
