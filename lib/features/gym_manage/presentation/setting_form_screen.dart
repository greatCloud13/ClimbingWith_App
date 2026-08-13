import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../../gym/application/gym_providers.dart';
import '../../gym/domain/climbing_setting.dart';

/// 세팅 기간 수정 폼. 생성(POST /api/setting)은 sectorId/gymId만 받고 세부
/// 기간이 없어 항상 생성 직후 이 화면으로 이어져 기간을 채운다.
class SettingFormScreen extends ConsumerStatefulWidget {
  const SettingFormScreen({super.key, required this.setting});

  final ClimbingSetting setting;

  @override
  ConsumerState<SettingFormScreen> createState() => _SettingFormScreenState();
}

class _SettingFormScreenState extends ConsumerState<SettingFormScreen> {
  DateTime? _settingDate;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _settingDate = _parseDate(widget.setting.settingDate) ?? DateTime.now();
    _startDate = _parseDate(widget.setting.startDate) ?? DateTime.now();
    _endDate = _parseDate(widget.setting.endDate);
  }

  DateTime? _parseDate(String? value) =>
      (value == null || value.isEmpty) ? null : DateTime.tryParse(value);

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(DateTime? current, void Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  Future<void> _submit() async {
    if (_settingDate == null || _startDate == null) {
      setState(() => _errorMessage = '세팅일과 시작일은 필수입니다.');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(gymApiProvider).updateSetting(
        settingId: widget.setting.id,
        settingDate: _formatDate(_settingDate!),
        startDate: _formatDate(_startDate!),
        endDate: _endDate == null ? null : _formatDate(_endDate!),
      );
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
      appBar: AppBar(title: const Text('세팅 기간 수정')),
      body: MatTextureBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DateField(
                  label: '세팅일',
                  value: _settingDate,
                  formatDate: _formatDate,
                  onTap: () => _pickDate(_settingDate, (d) => _settingDate = d),
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: '시작일',
                  value: _startDate,
                  formatDate: _formatDate,
                  onTap: () => _pickDate(_startDate, (d) => _startDate = d),
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: '종료일 (선택 — 비워두면 진행 중)',
                  value: _endDate,
                  formatDate: _formatDate,
                  onTap: () => _pickDate(_endDate, (d) => _endDate = d),
                  onClear: _endDate == null ? null : () => setState(() => _endDate = null),
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
                      : const Text('저장'),
                ),
              ],
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
    this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: onClear,
                ),
        ),
        child: Text(
          value == null ? '선택 안 함' : formatDate(value!),
          style: TextStyle(color: value == null ? AppColors.textTertiary : AppColors.textPrimary),
        ),
      ),
    );
  }
}
