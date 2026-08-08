import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// 상세 디자인은 추후 별도 설계안으로 교체 예정 — 현재는 자리만 잡아둔 최소 구현.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background,
          title: const Text('더보기'),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          sliver: SliverList.separated(
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => Card(
              child: ListTile(
                leading: Icon(_items[i].icon, color: AppColors.textSecondary),
                title: Text(_items[i].label),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                onTap: () {},
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MoreItem {
  const _MoreItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

const _items = [
  _MoreItem(Icons.settings_outlined, '설정'),
  _MoreItem(Icons.campaign_outlined, '공지사항'),
  _MoreItem(Icons.support_agent_outlined, '문의하기'),
  _MoreItem(Icons.info_outline_rounded, '앱 정보'),
];
