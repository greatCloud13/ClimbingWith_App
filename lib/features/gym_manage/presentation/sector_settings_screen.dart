import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';
import '../../gym/application/gym_providers.dart';
import '../../gym/domain/climbing_setting.dart';

/// 섹터를 탭하면 나오는 세팅 기록 화면 + CRUD. 세팅은 섹터의 '설정'이 아니라,
/// 한 섹터에서 여러 루트(문제)가 유지되는 기간을 뜻한다 — GET /api/sector/{id}
/// 의 settingList. 문제 depth는 아직 미착수.
class SectorSettingsScreen extends ConsumerStatefulWidget {
  const SectorSettingsScreen({super.key, required this.sectorId});

  final int sectorId;

  @override
  ConsumerState<SectorSettingsScreen> createState() => _SectorSettingsScreenState();
}

class _SectorSettingsScreenState extends ConsumerState<SectorSettingsScreen> {
  bool _creating = false;

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  void _refresh() => ref.invalidate(sectorDetailProvider(widget.sectorId));

  Future<void> _openEditForm(ClimbingSetting setting) async {
    final saved = await context.push<bool>('/gym-manage/setting/write', extra: setting);
    if (saved == true) _refresh();
  }

  Future<void> _createSetting() async {
    final authState = ref.read(authControllerProvider);
    final gymId = authState is AuthAuthenticated ? authState.user.managedGymId : null;
    if (gymId == null) return;

    setState(() => _creating = true);
    try {
      final created = await ref
          .read(gymApiProvider)
          .createSetting(sectorId: widget.sectorId, gymId: gymId);
      _refresh();
      if (!mounted) return;
      await _openEditForm(created);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('세팅을 생성하지 못했어요. 다시 시도해주세요.')));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _confirmDelete(ClimbingSetting setting) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('세팅 삭제'),
        content: Text(
          '${_formatDate(setting.startDate)} ~ ${setting.endDate == null ? '진행 중' : _formatDate(setting.endDate)} 세팅을 삭제할까요?',
        ),
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
      await ref.read(gymApiProvider).deleteSetting(setting.id);
      _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제했습니다.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제하지 못했어요. 등록된 문제가 있다면 문제를 먼저 삭제해주세요.')),
      );
    }
  }

  Future<void> _toggleActive(ClimbingSetting setting) async {
    try {
      final api = ref.read(gymApiProvider);
      if (setting.active) {
        await api.disableSetting(setting.id);
      } else {
        await api.activateSetting(setting.id);
      }
      _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(setting.active ? '비활성화하지 못했어요. 다시 시도해주세요.' : '활성화하지 못했어요. 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(sectorDetailProvider(widget.sectorId));

    return Scaffold(
      appBar: AppBar(
        title: Text(detailAsync.valueOrNull?.sectorName ?? '세팅 기록'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creating ? null : _createSetting,
        icon: _creating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10120A)),
              )
            : const Icon(Icons.add_rounded),
        label: const Text('새 세팅 시작'),
      ),
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
                  OutlinedButton(onPressed: _refresh, child: const Text('다시 시도')),
                ],
              ),
            ),
            data: (detail) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                if (detail.description != null && detail.description!.isNotEmpty) ...[
                  Text(detail.description!, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                ],
                Text(
                  '문제 ${detail.problemCount}개'
                  '${detail.nextSettingDate != null ? ' · 다음 세팅 예정 ${_formatDate(detail.nextSettingDate)}' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 20),
                Text('세팅 기록', style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                if (detail.settingList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('등록된 세팅 기록이 아직 없어요. 우측 하단 버튼으로 시작해보세요.', style: theme.textTheme.bodyMedium),
                    ),
                  )
                else
                  ...detail.settingList.map(
                    (setting) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SettingCard(
                        setting: setting,
                        formatDate: _formatDate,
                        onOpenProblems: () => context.push('/gym-manage/setting/${setting.id}/problem'),
                        onEdit: () => _openEditForm(setting),
                        onToggleActive: () => _toggleActive(setting),
                        onDelete: () => _confirmDelete(setting),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.setting,
    required this.formatDate,
    required this.onOpenProblems,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final ClimbingSetting setting;
  final String Function(String?) formatDate;
  final VoidCallback onOpenProblems;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = setting.active ? AppColors.holdLime : AppColors.textTertiary;
    return Card(
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onOpenProblems,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${formatDate(setting.startDate)} ~ ${setting.endDate == null ? '진행 중' : formatDate(setting.endDate)}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            setting.active ? '진행 중' : '종료',
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('세팅일 ${formatDate(setting.settingDate)}', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary), tooltip: '세팅 기간 수정'),
          IconButton(
            onPressed: onToggleActive,
            icon: Icon(
              setting.active ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: setting.active ? '비활성화' : '활성화',
          ),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error), tooltip: '삭제'),
        ],
      ),
    );
  }
}
