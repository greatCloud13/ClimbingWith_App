import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'application/gym_providers.dart';
import 'domain/gym_search_result.dart';
import 'domain/gym_type.dart';

/// GET /api/gym/search 연동 — 상단 입력창 + 바로 아래 검색 결과 리스트.
class GymScreen extends ConsumerStatefulWidget {
  const GymScreen({super.key});

  @override
  ConsumerState<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends ConsumerState<GymScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  final List<GymSearchResult> _gyms = [];
  int _nextPage = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _errorMessage;
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onKeywordChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _keyword = value.trim();
        _gyms.clear();
        _nextPage = 0;
        _hasMore = true;
        _errorMessage = null;
      });
      _loadMore();
    });
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final page = await ref
          .read(gymApiProvider)
          .searchGyms(
            keyword: _keyword.isEmpty ? null : _keyword,
            page: _nextPage,
          );
      setState(() {
        _gyms.addAll(page.results);
        _hasMore = !page.isLast;
        _nextPage = page.pageNumber + 1;
      });
    } catch (_) {
      setState(() => _errorMessage = '암장 목록을 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('클라이밍장', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: _onKeywordChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: '암장 이름 또는 주소로 검색',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _gyms.isEmpty && _loading
                ? const Center(child: CircularProgressIndicator())
                : _gyms.isEmpty
                ? Center(
                    child: Text(
                      _errorMessage ??
                          (_keyword.isEmpty
                              ? '등록된 암장이 아직 없어요.'
                              : '검색 결과가 없어요.'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: _gyms.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      if (i == _gyms.length) {
                        if (_errorMessage != null) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              children: [
                                Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: _loadMore,
                                  child: const Text('다시 시도'),
                                ),
                              ],
                            ),
                          );
                        }
                        if (_hasMore) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: _loading
                                  ? const CircularProgressIndicator()
                                  : OutlinedButton(
                                      onPressed: _loadMore,
                                      child: const Text('더 보기'),
                                    ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      return _GymCard(gym: _gyms[i]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GymCard extends StatelessWidget {
  const _GymCard({required this.gym});

  final GymSearchResult gym;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/gym/${gym.id}'),
      child: Card(
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
                        Text(gym.gymName, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(gym.address, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  _GymTypeTag(gymType: gym.gymType),
                ],
              ),
              if (!gym.isActive) ...[
                const SizedBox(height: 10),
                const _InactiveTag(),
              ],
              if (gym.openAt != null && gym.closeAt != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '평일 ${gym.openAt}~${gym.closeAt}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (gym.weekendOpenAt != null &&
                        gym.weekendCloseAt != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        '주말 ${gym.weekendOpenAt}~${gym.weekendCloseAt}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GymTypeTag extends StatelessWidget {
  const _GymTypeTag({required this.gymType});

  final GymType gymType;

  @override
  Widget build(BuildContext context) {
    final label = switch (gymType) {
      GymType.boulder => '볼더',
      GymType.lead => '리드',
      GymType.both => '볼더+리드',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.holdLime.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.holdLime,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InactiveTag extends StatelessWidget {
  const _InactiveTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.holdMagenta.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        '휴무 중',
        style: TextStyle(
          color: AppColors.holdMagenta,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
