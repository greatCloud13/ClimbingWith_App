import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../../gym/application/gym_providers.dart';
import '../../gym/domain/gym_post.dart';

/// 게시글 작성/수정 폼 — `postId`가 있으면 수정, 없으면 신규 작성.
/// POST /api/post 는 경로에 gymId가 없고 인증된 매니저의 관리 암장으로 서버가 결정한다.
class GymPostFormScreen extends ConsumerStatefulWidget {
  const GymPostFormScreen({super.key, this.postId});

  final int? postId;

  @override
  ConsumerState<GymPostFormScreen> createState() => _GymPostFormScreenState();
}

class _GymPostFormScreenState extends ConsumerState<GymPostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _postType = gymPostTypes.first;

  bool get _isEditing => widget.postId != null;
  bool _loadingDetail = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loadingDetail = true);
    try {
      final detail = await ref.read(gymApiProvider).fetchPostDetail(widget.postId!);
      _titleController.text = detail.title;
      _contentController.text = detail.content;
      setState(() => _postType = detail.postType);
    } catch (_) {
      setState(() => _errorMessage = '게시글을 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final api = ref.read(gymApiProvider);
      if (_isEditing) {
        await api.updatePost(
          widget.postId!,
          title: _titleController.text.trim(),
          postType: _postType,
          content: _contentController.text.trim(),
        );
      } else {
        await api.createPost(
          title: _titleController.text.trim(),
          postType: _postType,
          content: _contentController.text.trim(),
        );
      }
      if (!mounted) return;
      context.pop(true);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = '저장하지 못했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '게시글 수정' : '새 글쓰기')),
      body: MatTextureBackground(
        child: SafeArea(
          child: _loadingDetail
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _postType,
                          decoration: const InputDecoration(labelText: '분류'),
                          items: gymPostTypes
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(gymPostTypeLabel(type)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _postType = value);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: '제목'),
                          validator: (v) => (v?.trim().isEmpty ?? true) ? '제목은 필수입니다.' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _contentController,
                          decoration: const InputDecoration(labelText: '내용'),
                          minLines: 8,
                          maxLines: 16,
                          validator: (v) => (v?.trim().isEmpty ?? true) ? '내용은 필수입니다.' : null,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10120A)),
                                )
                              : Text(_isEditing ? '수정 완료' : '작성 완료'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
