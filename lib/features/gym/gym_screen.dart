import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class _Gym {
  const _Gym({
    required this.name,
    required this.area,
    required this.tags,
    required this.crowd,
    required this.crowdLabel,
    required this.accent,
    required this.difficultyMix,
  });

  final String name;
  final String area;
  final List<String> tags;
  final double crowd; // 0.0 ~ 1.0
  final String crowdLabel;
  final Color accent;
  final List<double> difficultyMix; // easy, mid, hard, extreme 비율
}

const _gyms = [
  _Gym(
    name: '락클라임 성수',
    area: '성수동 · 도보 5분',
    tags: ['볼더링', '초보환영'],
    crowd: 0.35,
    crowdLabel: '여유',
    accent: AppColors.holdLime,
    difficultyMix: [0.3, 0.4, 0.2, 0.1],
  ),
  _Gym(
    name: '그립하우스 홍대',
    area: '홍대입구 · 도보 8분',
    tags: ['볼더링', '리드', '신규셋팅'],
    crowd: 0.82,
    crowdLabel: '혼잡',
    accent: AppColors.holdMagenta,
    difficultyMix: [0.15, 0.35, 0.35, 0.15],
  ),
  _Gym(
    name: '볼더베이스 강남',
    area: '강남역 · 도보 3분',
    tags: ['볼더링', '24시간'],
    crowd: 0.6,
    crowdLabel: '보통',
    accent: AppColors.holdCyan,
    difficultyMix: [0.2, 0.3, 0.3, 0.2],
  ),
];

class GymScreen extends StatelessWidget {
  const GymScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background,
          title: const Text('클라이밍장'),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.separated(
            itemCount: _gyms.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _GymCard(gym: _gyms[i]),
          ),
        ),
      ],
    );
  }
}

class _GymCard extends StatelessWidget {
  const _GymCard({required this.gym});

  final _Gym gym;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(gym.name, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(gym.area, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                _CrowdPill(crowd: gym.crowd, label: gym.crowdLabel, accent: gym.accent),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: gym.tags.map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact)).toList(),
            ),
            const SizedBox(height: 12),
            Text('난이도 분포', style: theme.textTheme.labelSmall),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Expanded(flex: (gym.difficultyMix[0] * 100).round(), child: Container(color: AppColors.gradeEasy)),
                    Expanded(flex: (gym.difficultyMix[1] * 100).round(), child: Container(color: AppColors.gradeMid)),
                    Expanded(flex: (gym.difficultyMix[2] * 100).round(), child: Container(color: AppColors.gradeHard)),
                    Expanded(flex: (gym.difficultyMix[3] * 100).round(), child: Container(color: AppColors.gradeExtreme)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrowdPill extends StatelessWidget {
  const _CrowdPill({required this.crowd, required this.label, required this.accent});

  final double crowd;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
