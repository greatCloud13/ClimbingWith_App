import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';
import '../../gym/application/gym_providers.dart';
import '../../gym/domain/gym_post.dart';

/// GYM_MANAGER 전용 게시판 관리 — 목록 + 작성/수정/삭제 진입점.
/// 조회는 공개 게시판(GymBoardScreen)과 같은 API를 쓰되(GET /api/post/gym/{gymId}),
/// 여기서는 자신이 관리하는 암장(managedGymId) 글만 대상으로 하고 쓰기 액션이 붙는다.
class GymManagerBoardScreen extends ConsumerStatefulWidget {
  const GymManagerBoardScreen({super.key});

  @override
  ConsumerState<GymManagerBoardScreen> createState() =>
      _GymManagerBoardScreenState();
}

class _GymManagerBoardScreenState
    extends ConsumerState<GymManagerBoardScreen> {
  String? _selectedType;
  final List<GymPost> _posts = [];
  int _nextPage = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _errorMessage;

  int? get _gymId {
    final authState = ref.read(authControllerProvider);
    return authState is AuthAuthenticated ? authState.user.managedGymId : null;
  }

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
    final gymId = _gymId;
    if (_loading || !_hasMore || gymId == null) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final api = ref.read(gymApiProvider);
      final page = _selectedType == null
          ? await api.fetchGymPosts(gymId, page: _nextPage)
          : await api.fetchGymPostsByType(gymId, _selectedType!, page: _nextPage);
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

  Future<void> _openWriteForm({GymPost? editing}) async {
    final saved = await context.push<bool>(
      '/gym-manage/board/write',
      extra: editing?.id,
    );
    if (saved == true) {
      setState(() {
        _posts.clear();
        _nextPage = 0;
        _hasMore = true;
      });
      _loadMore();
    }
  }

  Future<void> _confirmDelete(GymPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: Text('"${post.title}" 게시글을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(gymApiProvider).deletePost(post.id);
      setState(() => _posts.removeWhere((p) => p.id == post.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('삭제했습니다.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('삭제하지 못했어요. 다시 시도해주세요.')));
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gymId = _gymId;

    return Scaffold(
      appBar: AppBar(title: const Text('게시판 관리')),
      floatingActionButton: gymId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openWriteForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('새 글쓰기'),
            ),
      body: MatTextureBackground(
        child: SafeArea(
          child: gymId == null
              ? Center(
                  child: Text('관리 중인 암장 정보를 찾을 수 없어요.', style: theme.textTheme.bodyMedium),
                )
              : Column(
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
                            selectedColor: AppColors.holdLime.withValues(alpha: 0.22),
                            backgroundColor: AppColors.surfaceElevated,
                            side: BorderSide(
                              color: selected ? AppColors.holdLime : AppColors.border,
                            ),
                            labelStyle: TextStyle(
                              color: selected ? AppColors.holdLime : AppColors.textSecondary,
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
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                              itemCount: _posts.length + 1,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                if (i == _posts.length) {
                                  if (_errorMessage != null) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      child: Column(
                                        children: [
                                          Text(_errorMessage!, style: theme.textTheme.bodyMedium),
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

                                final post = _posts[i];
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceElevated,
                                            borderRadius: BorderRadius.circular(999),
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                post.title,
                                                style: theme.textTheme.titleMedium,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(_formatDate(post.createdAt), style: theme.textTheme.bodyMedium),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _openWriteForm(editing: post),
                                          icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                                          tooltip: '수정',
                                        ),
                                        IconButton(
                                          onPressed: () => _confirmDelete(post),
                                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                          tooltip: '삭제',
                                        ),
                                      ],
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
