import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../data/home_mock_data.dart';
import '../domain/notice.dart';

class NoticeDetailScreen extends StatelessWidget {
  const NoticeDetailScreen({super.key, required this.noticeId, this.notice});

  final String noticeId;
  final Notice? notice;

  @override
  Widget build(BuildContext context) {
    final resolved = notice ?? mockNotices.firstWhere(
      (n) => n.id == noticeId,
      orElse: () => mockNotices.first,
    );
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('공지사항')),
      body: MatTextureBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(color: resolved.accent, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 16),
                Text(resolved.title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(resolved.subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                Text(resolved.body, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
