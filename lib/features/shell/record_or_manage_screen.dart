import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/application/auth_providers.dart';
import '../auth/application/auth_state.dart';
import '../gym_manage/gym_manage_screen.dart';
import '../record/record_screen.dart';

const gymManagerRole = 'GYM_MANAGER';

/// 4번째 탭의 내용을 role에 따라 분기한다: 일반 회원은 운동기록,
/// GYM_MANAGER는 암장관리. 경로(`/record`)는 고정하고 화면만 바꾼다.
class RecordOrManageScreen extends ConsumerWidget {
  const RecordOrManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final role = authState is AuthAuthenticated ? authState.user.role : null;
    return role == gymManagerRole ? const GymManageScreen() : const RecordScreen();
  }
}
