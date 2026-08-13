import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';
import '../../gym/application/gym_providers.dart';
import '../../gym/domain/climbing_discipline.dart';
import '../../gym/domain/gym_type.dart';
import '../../gym/domain/sector.dart';

/// 섹터 생성/수정 폼. `sector`가 있으면 수정, 없으면 신규 생성.
/// 생성(POST /api/sector)은 이름·설명만 받고, 수정(PUT /api/sector/{id})은
/// 세팅일/다음 세팅 예정일도 함께 받는다 — API 스펙 차이라 폼에 그대로 반영.
class SectorFormScreen extends ConsumerStatefulWidget {
  const SectorFormScreen({super.key, required this.gymType, this.sector});

  final GymType gymType;
  final Sector? sector;

  @override
  ConsumerState<SectorFormScreen> createState() => _SectorFormScreenState();
}

class _SectorFormScreenState extends ConsumerState<SectorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.sector?.name ?? '');
  late final _descriptionController = TextEditingController(text: widget.sector?.description ?? '');
  DateTime? _settingDate;
  DateTime? _nextSettingDate;

  bool get _isEditing => widget.sector != null;
  bool _submitting = false;
  String? _errorMessage;

  ClimbingDiscipline get _discipline => switch (widget.gymType) {
    GymType.lead => ClimbingDiscipline.lead,
    GymType.boulder || GymType.both => ClimbingDiscipline.boulder,
  };

  @override
  void initState() {
    super.initState();
    _settingDate = _parseDate(widget.sector?.settingDate);
    _nextSettingDate = _parseDate(widget.sector?.nextSettingDate);
  }

  DateTime? _parseDate(String? value) => value == null ? null : DateTime.tryParse(value);

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isNextSetting}) async {
    final initial = (isNextSetting ? _nextSettingDate : _settingDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isNextSetting) {
        _nextSettingDate = picked;
      } else {
        _settingDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final api = ref.read(gymApiProvider);
      if (_isEditing) {
        await api.updateSector(
          sectorId: int.parse(widget.sector!.id),
          sectorName: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          settingDate: _settingDate == null ? null : _formatDate(_settingDate!),
          nextSettingDate: _nextSettingDate == null ? null : _formatDate(_nextSettingDate!),
          discipline: _discipline,
        );
      } else {
        final authState = ref.read(authControllerProvider);
        final gymId = authState is AuthAuthenticated ? authState.user.managedGymId : null;
        if (gymId == null) {
          setState(() => _errorMessage = '관리 중인 암장 정보를 찾을 수 없어요.');
          return;
        }
        await api.createSector(
          gymId: gymId,
          sectorName: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          discipline: _discipline,
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
      appBar: AppBar(title: Text(_isEditing ? '섹터 수정' : '새 섹터')),
      body: MatTextureBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '섹터 이름'),
                    validator: (v) => (v?.trim().isEmpty ?? true) ? '섹터 이름은 필수입니다.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: '설명 (선택)'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 12),
                    _DateField(
                      label: '세팅일',
                      value: _settingDate,
                      onTap: () => _pickDate(isNextSetting: false),
                      formatDate: _formatDate,
                    ),
                    const SizedBox(height: 12),
                    _DateField(
                      label: '다음 세팅 예정일',
                      value: _nextSettingDate,
                      onTap: () => _pickDate(isNextSetting: true),
                      formatDate: _formatDate,
                    ),
                  ],
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
                        : Text(_isEditing ? '수정 완료' : '생성 완료'),
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.formatDate,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value == null ? '선택 안 함' : formatDate(value!),
          style: TextStyle(color: value == null ? AppColors.textTertiary : AppColors.textPrimary),
        ),
      ),
    );
  }
}
