import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';
import '../../gym/application/gym_providers.dart';
import '../../gym/domain/gym_level.dart';
import '../../gym/domain/gym_problem.dart';

/// 문제 등록/수정 폼. `problem`이 있으면 수정, 없으면 신규 등록.
/// 난이도(gymLevelId)는 [levelsByGymProvider]로 조회해 종목(problemType)별로
/// 필터링해 고른다 — 등록된 난이도가 없으면 그 자리에서 바로 만들 수 있다.
class ProblemFormScreen extends ConsumerStatefulWidget {
  const ProblemFormScreen({super.key, required this.settingId, this.problem});

  final int settingId;
  final GymProblem? problem;

  @override
  ConsumerState<ProblemFormScreen> createState() => _ProblemFormScreenState();
}

class _ProblemFormScreenState extends ConsumerState<ProblemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.problem?.title ?? '');
  late final _descriptionController = TextEditingController(text: widget.problem?.description ?? '');
  late String _problemType = widget.problem?.problemType ?? climbTypes.first;
  late int? _selectedLevelId = widget.problem?.levelId;
  // levelId가 이미 있으면 이름으로 다시 찾을 필요가 없다 — 응답에 levelId가
  // 없는(구) 데이터에서만 _LevelPicker의 이름 매칭 폴백을 탄다.
  late bool _levelPreselected = widget.problem?.levelId != null;

  bool get _isEditing => widget.problem != null;
  bool _submitting = false;
  String? _errorMessage;

  int? get _gymId {
    final authState = ref.read(authControllerProvider);
    return authState is AuthAuthenticated ? authState.user.managedGymId : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createLevelInline(int gymId) async {
    final created = await showDialog<GymLevel>(
      context: context,
      builder: (context) => _CreateLevelDialog(gymId: gymId, climbType: _problemType),
    );
    if (created == null) return;
    ref.invalidate(levelsByGymProvider(gymId));
    setState(() => _selectedLevelId = created.id);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLevelId == null) {
      setState(() => _errorMessage = '난이도를 선택해주세요.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final api = ref.read(gymApiProvider);
      if (_isEditing) {
        await api.updateProblem(
          problemId: widget.problem!.id,
          settingId: widget.settingId,
          title: _titleController.text.trim(),
          problemType: _problemType,
          gymLevelId: _selectedLevelId!,
          description: _descriptionController.text.trim(),
        );
      } else {
        await api.createProblem(
          settingId: widget.settingId,
          title: _titleController.text.trim(),
          problemType: _problemType,
          gymLevelId: _selectedLevelId!,
          description: _descriptionController.text.trim(),
        );
      }
      if (!mounted) return;
      context.pop(true);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = '저장하지 못했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gymId = _gymId;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '문제 수정' : '새 문제')),
      body: MatTextureBackground(
        child: SafeArea(
          child: gymId == null
              ? const Center(child: Text('관리 중인 암장 정보를 찾을 수 없어요.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _problemType,
                          decoration: const InputDecoration(labelText: '종목'),
                          items: climbTypes
                              .map((type) => DropdownMenuItem(value: type, child: Text(climbTypeLabel(type))))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _problemType = value;
                              _selectedLevelId = null;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: '문제 이름'),
                          validator: (v) => (v?.trim().isEmpty ?? true) ? '문제 이름은 필수입니다.' : null,
                        ),
                        const SizedBox(height: 12),
                        _LevelPicker(
                          gymId: gymId,
                          climbType: _problemType,
                          selectedLevelId: _selectedLevelId,
                          onSelected: (id) => setState(() => _selectedLevelId = id),
                          onCreateNew: () => _createLevelInline(gymId),
                          preselectLevelName: !_levelPreselected ? widget.problem?.gymLevel : null,
                          onPreselected: (id) => setState(() {
                            _selectedLevelId = id;
                            _levelPreselected = true;
                          }),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: '설명 (선택)'),
                          minLines: 2,
                          maxLines: 4,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10120A)),
                                )
                              : Text(_isEditing ? '수정 완료' : '등록 완료'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// 종목(climbType)별 난이도 드롭다운. 등록된 난이도가 없으면 드롭다운 대신
/// "난이도 등록" 버튼을 보여준다.
class _LevelPicker extends ConsumerWidget {
  const _LevelPicker({
    required this.gymId,
    required this.climbType,
    required this.selectedLevelId,
    required this.onSelected,
    required this.onCreateNew,
    this.preselectLevelName,
    this.onPreselected,
  });

  final int gymId;
  final String climbType;
  final int? selectedLevelId;
  final ValueChanged<int> onSelected;
  final VoidCallback onCreateNew;

  /// 수정 모드인데 problem.levelId가 없는(구) 데이터에 한해 쓰는 폴백 —
  /// 이름이 같은 난이도를 목록에서 찾아 자동 선택한다. 못 찾으면 직접 골라야 한다.
  final String? preselectLevelName;
  final ValueChanged<int>? onPreselected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(levelsByGymProvider(gymId));

    return levelsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('난이도 목록을 불러오지 못했어요.', style: TextStyle(color: AppColors.error, fontSize: 13)),
          const SizedBox(height: 6),
          OutlinedButton(
            onPressed: () => ref.invalidate(levelsByGymProvider(gymId)),
            child: const Text('다시 시도'),
          ),
        ],
      ),
      data: (levels) {
        final filtered =
            levels.where((l) => l.climbType == null || l.climbType == climbType).toList()
              ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        if (filtered.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('등록된 난이도가 없어요.', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: onCreateNew,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('난이도 등록하기'),
              ),
            ],
          );
        }

        if (preselectLevelName != null && onPreselected != null) {
          final match = filtered.where((l) => l.levelName == preselectLevelName);
          if (match.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onPreselected!(match.first.id));
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) => onPreselected!(-1));
          }
        }

        return DropdownButtonFormField<int>(
          initialValue: filtered.any((l) => l.id == selectedLevelId) ? selectedLevelId : null,
          decoration: const InputDecoration(labelText: '난이도'),
          items: filtered
              .map(
                (l) => DropdownMenuItem(
                  value: l.id,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: parseHexColor(l.colorCode) ?? AppColors.textTertiary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(l.levelName),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) onSelected(value);
          },
        );
      },
    );
  }
}

class _CreateLevelDialog extends ConsumerStatefulWidget {
  const _CreateLevelDialog({required this.gymId, required this.climbType});

  final int gymId;
  final String climbType;

  @override
  ConsumerState<_CreateLevelDialog> createState() => _CreateLevelDialogState();
}

class _CreateLevelDialogState extends ConsumerState<_CreateLevelDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  final _orderController = TextEditingController(text: '0');
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final level = await ref.read(gymApiProvider).createLevel(
        gymId: widget.gymId,
        levelName: _nameController.text.trim(),
        displayOrder: int.tryParse(_orderController.text.trim()) ?? 0,
        colorCode: _colorController.text.trim(),
        climbType: widget.climbType,
      );
      if (!mounted) return;
      Navigator.of(context).pop(level);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = '난이도를 등록하지 못했어요.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${climbTypeLabel(widget.climbType)} 난이도 등록'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '난이도 이름 (예: V4, 5.11a)'),
              validator: (v) => (v?.trim().isEmpty ?? true) ? '필수입니다.' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(labelText: '색상 코드 (선택, 예: #FF3B7F)'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _orderController,
              decoration: const InputDecoration(labelText: '표시 순서'),
              keyboardType: TextInputType.number,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('등록'),
        ),
      ],
    );
  }
}
