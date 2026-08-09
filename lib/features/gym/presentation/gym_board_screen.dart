import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../../home/domain/notice.dart';
import '../application/gym_providers.dart';
import '../domain/gym_post.dart';

/// 암장 게시판 — 처음 들어오면 전체 글이 보이고, 상단 태그로 필터링할 수 있다.
/// 전체: GET /api/post/gym/{gymId}, 태그 선택 시: GET /api/post/gym/{gymId}/posttype/{postType}
class GymBoardScreen extends ConsumerStatefulWidget {
  const GymBoardScreen({super.key, required this.gymId, required this.accent});

  final int gymId;
  final Color accent;

  @override
  ConsumerState<GymBoardScreen> createState() => _GymBoardScreenState();
}

class _GymBoardScreenState extends ConsumerState<GymBoardScreen> {
  String? _selectedType;
  final List<GymPost> _posts = [];
  int _nextPage = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  void _selectType(String? type) {
    if (type == _selectedType) return;
    setState(() {
      _selectedType = type;
      _posts.clear();
      _nextPage = 0;
      _hasMore = true;
      _errorMessage = null;
    });
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final api = ref.read(gymApiProvider);
      final page = _selectedType == null
          ? await api.fetchGymPosts(widget.gymId, page: _nextPage)
          : await api.fetchGymPostsByType(
              widget.gymId,
              _selectedType!,
              page: _nextPage,
            );
      setState(() {
        _posts.addAll(page.posts);
        _hasMore = !page.isLast;
        _nextPage = page.pageNumber + 1;
      });
    } catch (_) {
      setState(() => _errorMessage = '게시글을 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openPost(GymPost post) {
    final notice = Notice(
      id: post.id.toString(),
      title: post.title,
      subtitle: _formatDate(post.createdAt),
      body: '자세한 내용은 곧 제공될 예정입니다.',
      accent: widget.accent,
    );
    context.push('/notice/${notice.id}', extra: notice);
  }

  String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('게시판')),
      body: MatTextureBackground(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: gymPostTypeFilters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final type = gymPostTypeFilters[i];
                    final selected = type == _selectedType;
                    return ChoiceChip(
                      label: Text(gymPostTypeLabel(type)),
                      selected: selected,
                      onSelected: (_) => _selectType(type),
                      selectedColor: widget.accent.withValues(alpha: 0.22),
                      backgroundColor: AppColors.surfaceElevated,
                      side: BorderSide(
                        color: selected ? widget.accent : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        color: selected
                            ? widget.accent
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      shape: const StadiumBorder(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _posts.isEmpty && _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _posts.isEmpty
                    ? Center(
                        child: Text(
                          _errorMessage ?? '등록된 게시글이 아직 없어요.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: _posts.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          if (i == _posts.length) {
                            if (_errorMessage != null) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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

                          final post = _posts[i];
                          return InkWell(
                            onTap: () => _openPost(post),
                            borderRadius: BorderRadius.circular(12),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        gymPostTypeLabel(post.postType),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            post.title,
                                            style: theme.textTheme.titleMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatDate(post.createdAt),
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textTertiary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
