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

/// 난이도(레벨) 생성/수정 폼. `level`이 있으면 수정, 없으면 신규 등록.
class LevelFormScreen extends ConsumerStatefulWidget {
  const LevelFormScreen({super.key, this.level});

  final GymLevel? level;

  @override
  ConsumerState<LevelFormScreen> createState() => _LevelFormScreenState();
}

class _LevelFormScreenState extends ConsumerState<LevelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.level?.levelName ?? '');
  late final _colorController = TextEditingController(text: widget.level?.colorCode ?? '');
  late final _descriptionController = TextEditingController(text: widget.level?.description ?? '');
  late final _orderController = TextEditingController(
    text: (widget.level?.displayOrder ?? 0).toString(),
  );
  late String _climbType = widget.level?.climbType ?? climbTypes.first;

  bool get _isEditing => widget.level != null;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _descriptionController.dispose();
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
      final api = ref.read(gymApiProvider);
      final displayOrder = int.tryParse(_orderController.text.trim()) ?? 0;
      if (_isEditing) {
        await api.updateLevel(
          levelId: widget.level!.id,
          levelName: _nameController.text.trim(),
          displayOrder: displayOrder,
          colorCode: _colorController.text.trim(),
          description: _descriptionController.text.trim(),
          climbType: _climbType,
        );
      } else {
        final authState = ref.read(authControllerProvider);
        final gymId = authState is AuthAuthenticated ? authState.user.managedGymId : null;
        if (gymId == null) {
          setState(() => _errorMessage = '관리 중인 암장 정보를 찾을 수 없어요.');
          return;
        }
        await api.createLevel(
          gymId: gymId,
          levelName: _nameController.text.trim(),
          displayOrder: displayOrder,
          colorCode: _colorController.text.trim(),
          description: _descriptionController.text.trim(),
          climbType: _climbType,
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
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '난이도 수정' : '새 난이도')),
      body: MatTextureBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _climbType,
                    decoration: const InputDecoration(labelText: '종목'),
                    items: climbTypes
                        .map((type) => DropdownMenuItem(value: type, child: Text(climbTypeLabel(type))))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _climbType = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '난이도 이름 (예: V4, 5.11a)'),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? '난이도 이름은 필수입니다.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(labelText: '색상 코드 (선택, 예: #FF3B7F)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _orderController,
                    decoration: const InputDecoration(labelText: '표시 순서'),
                    keyboardType: TextInputType.number,
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
