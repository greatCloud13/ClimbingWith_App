import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/grade_badge.dart';

class _Post {
  const _Post({
    required this.author,
    required this.gym,
    required this.timeAgo,
    required this.content,
    required this.grade,
    required this.accent,
    required this.likes,
    required this.comments,
  });

  final String author;
  final String gym;
  final String timeAgo;
  final String content;
  final String? grade;
  final Color accent;
  final int likes;
  final int comments;
}

const _posts = [
  _Post(
    author: '지환',
    gym: '락클라임 성수',
    timeAgo: '12분 전',
    content: '드디어 오늘 V5 다이노 완등했다 🎉 3주 프로젝트였는데 어제 밤에 무브 하나 바꾸니까 바로 되네',
    grade: 'V5',
    accent: AppColors.holdMagenta,
    likes: 24,
    comments: 6,
  ),
  _Post(
    author: '수아',
    gym: '그립하우스 홍대',
    timeAgo: '38분 전',
    content: '홍대점 신규 셋팅 떴어요! 색깔별로 난이도 다른데 노랑 라인 은근 빡셈니다... 손끝 남아나질 않네요',
    grade: null,
    accent: AppColors.holdLime,
    likes: 41,
    comments: 13,
  ),
  _Post(
    author: '민준',
    gym: '아웃도어 · 인수봉',
    timeAgo: '2시간 전',
    content: '오랜만에 아웃도어 나갔다 옴. 슬랩 구간에서 손끝 나갈 뻔했는데 그래도 완등은 함',
    grade: 'V3',
    accent: AppColors.holdCyan,
    likes: 18,
    comments: 4,
  ),
  _Post(
    author: '하늘',
    gym: '볼더베이스 강남',
    timeAgo: '5시간 전',
    content: '이번 주 목표였던 파랑 라인 실패... 다음 주에 다시 도전. 같이 붙어보실 분?',
    grade: 'V6',
    accent: AppColors.holdMagenta,
    likes: 9,
    comments: 21,
  ),
];

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background,
          title: const Text('클라임로그'),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.separated(
            itemCount: _posts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _PostCard(post: _posts[i]),
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final _Post post;

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
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: post.accent.withValues(alpha: 0.18),
                  child: Text(
                    post.author.characters.first,
                    style: TextStyle(color: post.accent, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.author, style: theme.textTheme.titleMedium),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 2),
                          Text(post.gym, style: theme.textTheme.labelSmall),
                          const SizedBox(width: 6),
                          Text('· ${post.timeAgo}', style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ],
                  ),
                ),
                if (post.grade != null) GradeBadge(grade: post.grade!),
              ],
            ),
            const SizedBox(height: 10),
            Text(post.content, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      post.accent.withValues(alpha: 0.22),
                      AppColors.surfaceElevated,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(Icons.image_outlined, color: post.accent.withValues(alpha: 0.6), size: 32),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _ActionIcon(icon: Icons.favorite_border_rounded, label: '${post.likes}'),
                const SizedBox(width: 16),
                _ActionIcon(icon: Icons.mode_comment_outlined, label: '${post.comments}'),
                const Spacer(),
                Icon(Icons.bookmark_border_rounded, size: 18, color: AppColors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
