import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../auth/application/auth_providers.dart';
import '../auth/application/auth_state.dart';
import 'application/record_providers.dart';
import 'domain/recent_clear_record.dart';

/// 이번달 완등/최고 난이도/연속 방문 통계와 이번주 랭킹은 API 없이 목업으로만
/// 있던 부분이라 사용자 확인 하에 숨김 처리(2026-08-18) — "최근 완등 기록"만
/// 남김. `GET /api/clearRecord/user/{userId}` 실연동 완료(2026-08-19).
class RecordScreen extends ConsumerWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final knownUserId = authState is AuthAuthenticated ? authState.user.userId : null;
    final recordsAsync = ref.watch(recentClearRecordsProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background,
          title: const Text('기록'),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('최근 완등 기록', style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              if (knownUserId == null)
                Text(
                  '다시 로그인하면 완등 기록을 볼 수 있어요.',
                  style: theme.textTheme.bodyMedium,
                )
              else
                recordsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, stackTrace) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('완등 기록을 불러오지 못했어요.', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(recentClearRecordsProvider),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                  data: (records) {
                    if (records.isEmpty) {
                      return Text('아직 완등 기록이 없어요.', style: theme.textTheme.bodyMedium);
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < records.length; i++)
                          Padding(
                            padding: EdgeInsets.only(bottom: i == records.length - 1 ? 0 : 8),
                            child: _ClimbRow(record: records[i]),
                          ),
                      ],
                    );
                  },
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ClimbRow extends StatelessWidget {
  const _ClimbRow({required this.record});

  final RecentClearRecord record;

  String _formatDate(DateTime? d) {
    if (d == null) return record.clearDate;
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: () => context.push('/gym/${record.gymId}/sector/${record.sectorId}/problem/${record.problemId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: record.levelColor ?? AppColors.textTertiary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record.level,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.problemName,
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
                '${record.gymName} · ${record.sectorName} · 시도 ${record.tryCount}회',
                style: theme.textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(_formatDate(DateTime.tryParse(record.clearDate)), style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}
