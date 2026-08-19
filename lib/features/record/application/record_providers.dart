import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/application/auth_state.dart';
import '../data/record_api.dart';
import '../domain/recent_clear_record.dart';

final Provider<RecordApi> recordApiProvider = Provider<RecordApi>(
  (ref) => RecordApi(ref.watch(dioClientProvider).dio),
);

/// "최근 완등 기록" 목록 — `/record`는 로그인 필요 라우트라 항상 userId가 있다.
final recentClearRecordsProvider = FutureProvider<List<RecentClearRecord>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  if (authState is! AuthAuthenticated) return const [];
  final userId = authState.user.userId;
  if (userId == null) return const [];
  final page = await ref.watch(recordApiProvider).fetchRecentClearRecords(userId, size: 10);
  return page.records;
});
