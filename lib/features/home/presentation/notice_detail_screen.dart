import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../domain/notice.dart';

class NoticeDetailScreen extends StatelessWidget {
  const NoticeDetailScreen({super.key, required this.noticeId, this.notice});

  final String noticeId;

  /// 홈 화면에서 이미 갖고 있는 공지 데이터를 그대로 넘겨받는다 (대부분 이 경로).
  /// extra 없이 직접 링크로 들어온 경우에는 표시할 데이터가 없다.
  final Notice? notice;

  @override
  Widget build(BuildContext context) {
    final resolved = notice;
    final theme = Theme.of(context);

    if (resolved == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('공지사항')),
        body: const Center(child: Text('공지를 찾을 수 없습니다.')),
      );
    }

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
                  decoration: BoxDecoration(
                    color: resolved.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Text(resolved.title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  resolved.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
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
