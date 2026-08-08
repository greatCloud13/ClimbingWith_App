import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/grade_badge.dart';

class _Climb {
  const _Climb({required this.gym, required this.grade, required this.date, required this.attempts});
  final String gym;
  final String grade;
  final String date;
  final int attempts;
}

class _Ranker {
  const _Ranker({required this.rank, required this.name, required this.points, required this.isMe});
  final int rank;
  final String name;
  final int points;
  final bool isMe;
}

const _recentClimbs = [
  _Climb(gym: '락클라임 성수', grade: 'V5', date: '오늘', attempts: 7),
  _Climb(gym: '그립하우스 홍대', grade: 'V4', date: '어제', attempts: 3),
  _Climb(gym: '볼더베이스 강남', grade: 'V6', date: '3일 전', attempts: 12),
  _Climb(gym: '락클라임 성수', grade: 'V3', date: '5일 전', attempts: 1),
];

const _rankers = [
  _Ranker(rank: 1, name: '태윤', points: 2840, isMe: false),
  _Ranker(rank: 2, name: '서연', points: 2615, isMe: false),
  _Ranker(rank: 3, name: '지환', points: 2400, isMe: true),
  _Ranker(rank: 4, name: '하늘', points: 2180, isMe: false),
  _Ranker(rank: 5, name: '민준', points: 1990, isMe: false),
];

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              Row(
                children: const [
                  Expanded(child: _StatTile(label: '이번달 완등', value: '18', accent: AppColors.holdLime)),
                  SizedBox(width: 10),
                  Expanded(child: _StatTile(label: '최고 난이도', value: 'V6', accent: AppColors.holdMagenta)),
                  SizedBox(width: 10),
                  Expanded(child: _StatTile(label: '연속 방문', value: '5일', accent: AppColors.holdCyan)),
                ],
              ),
              const SizedBox(height: 24),
              Text('최근 완등 기록', style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              ..._recentClimbs.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ClimbRow(climb: c),
                  )),
              const SizedBox(height: 24),
              Text('이번주 랭킹', style: theme.textTheme.titleLarge),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: _rankers.map((r) => _RankRow(ranker: r)).toList(),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.accent});
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: accent, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ClimbRow extends StatelessWidget {
  const _ClimbRow({required this.climb});
  final _Climb climb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            GradeBadge(grade: climb.grade),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(climb.gym, style: theme.textTheme.titleMedium),
                  Text('시도 ${climb.attempts}회', style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            Text(climb.date, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.ranker});
  final _Ranker ranker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medalColor = switch (ranker.rank) {
      1 => AppColors.holdLime,
      2 => AppColors.textPrimary,
      3 => AppColors.holdMagenta,
      _ => AppColors.textTertiary,
    };
    return Container(
      color: ranker.isMe ? AppColors.holdLime.withValues(alpha: 0.06) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text('${ranker.rank}', style: TextStyle(color: medalColor, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ranker.isMe ? '${ranker.name} (나)' : ranker.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: ranker.isMe ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text('${ranker.points}pt', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
