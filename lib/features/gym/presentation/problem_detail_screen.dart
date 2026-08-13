import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../application/gym_providers.dart';
import '../application/problem_try_providers.dart';
import '../data/problem_try_mock_data.dart';
import '../domain/gym_problem.dart';
import '../domain/gym_problem_detail.dart';
import '../domain/problem_try_log.dart';
import '../domain/problem_try_state.dart';

const _sectionSize = 10;

bool _isLead(String problemType) => problemType.toUpperCase() == 'LEAD';

/// 문제 상세조회. 볼더/리드 모두 같은 방향성(홀드 갯수, 내 진행/트라이 기록,
/// 낙하 지점 분포, 클리어 인원)으로 구성 — 볼더 전용 스펙이 아직 없어 우선
/// 리드와 동일한 구성을 쓴다. 리드는 루트가 길어질 수 있어 루트 토포를
/// 좌→우 가로 스크롤로, 볼더는 하→상 세로로 그린다. 홀드 갯수/내 트라이 횟수/
/// 내 최고 도달 지점/클리어 인원은 `GET /api/problem/{id}/detail`, 커뮤니티
/// 낙하 지점 분포(히트맵)는 `GET /api/problem/{id}/dropPointStats` 실데이터다
/// (게스트 체험 모드에서는 holdCount 자체가 목업이라 이 히트맵도 문제 id 기준
/// 목업[problem_try_mock_data.dart]을 대신 쓴다). 점장님의 팁은 아직 API가
/// 없어 계속 목업이다. '트라이 시작'/'여기서 떨어짐'은 로그인 사용자라면
/// `POST /api/problemTryLog`로 실제 기록되지만, 문제 단위 과거 기록 조회
/// API가 아직 없어 화면에는 이번 세션에 새로 기록한 것만 보인다
/// (reports/2026-08-10_problem-detail-stats-api-request.md 참고). **`/detail`
/// API는 비로그인 요청에 403을 내려줘서**, 게스트는 공개 정보로 구성한
/// "체험 모드"로 화면을 보고 트라이도 남길 수 있지만 전부 세션 로컬에만
/// 남고 서버에 저장되지 않는다.
class ProblemDetailScreen extends ConsumerWidget {
  const ProblemDetailScreen({super.key, required this.problemId});

  final int problemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final detailAsync = ref.watch(gymProblemDetailProvider(problemId));
    return detailAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('문제 정보를 불러오지 못했어요.', style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => ref.invalidate(gymProblemDetailProvider(problemId)),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (detail) => _ProblemDetailBody(detail: detail),
    );
  }
}

class _ProblemDetailBody extends ConsumerWidget {
  const _ProblemDetailBody({required this.detail});

  final GymProblemDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(problemTryProvider(detail.id));
    final notifier = ref.read(problemTryProvider(detail.id).notifier);
    final isLead = _isLead(detail.problemType);
    // 게스트 체험 모드는 holdCount 자체가 목업이라 실제 낙하 지점 분포와
    // 어긋날 수 있어 계속 목업 히트맵을 쓴다. 로그인 사용자는 실데이터를
    // 쓰되, 아직 불러오는 중/실패했을 때는 목업으로 잠깐 대체해 화면이
    // 끊기지 않게 한다.
    final dropStats = detail.isGuestPreview
        ? null
        : ref.watch(dropPointStatsProvider(detail.id)).valueOrNull;
    final communityFallCounts = dropStats?.distribution ?? mockCommunityFallCounts(detail.id, detail.holdCount);
    final managerTips = mockManagerTips(detail.id, detail.holdCount);
    // 게스트 체험 모드는 서버 기준 내 기록이 없어(myBestDropPoint/myTryCount 항상 0)
    // 이번 세션에 로컬로 남긴 기록으로 대신 계산한다.
    final sessionBest = state.sessionHistory.isEmpty
        ? null
        : state.sessionHistory.map((l) => l.dropPoint).reduce((a, b) => a > b ? a : b);
    final bestHoldIndex = detail.isGuestPreview ? (sessionBest ?? 0) : (detail.myBestDropPoint ?? 0);
    final myTryCountDisplay = detail.isGuestPreview ? state.sessionHistory.length : detail.myTryCount;
    final lastFallHoldIndex = state.lastSessionFallHoldIndex;

    return Scaffold(
      appBar: AppBar(title: Text(detail.title)),
      body: MatTextureBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              if (detail.isGuestPreview) ...[
                const _GuestPreviewBanner(),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: detail.levelColor ?? AppColors.textTertiary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    detail.gymLevel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Tag(label: climbTypeLabel(detail.problemType)),
                  const Spacer(),
                  Text('완등 ${detail.clearCount}명', style: theme.textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 10),
              Text(detail.title, style: theme.textTheme.headlineMedium),
              if (detail.description != null && detail.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(detail.description!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 28),
              Text('루트 토포', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                isLead
                    ? '왼쪽이 시작, 오른쪽이 완등 지점이에요. 홀드 $_sectionSize개 단위로 구간이 나뉘어요.'
                    : '아래가 시작, 위가 완등 지점이에요. 홀드 색이 진할수록 그 지점에서 떨어진 사람이 많다는 뜻이에요.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _RouteTopo(
                holdCount: detail.holdCount,
                communityFallCounts: communityFallCounts,
                bestHoldIndex: bestHoldIndex,
                lastFallHoldIndex: lastFallHoldIndex,
                pendingHoldIndex: state.pendingHoldIndex,
                axis: isLead ? Axis.horizontal : Axis.vertical,
                onTapHold: (holdIndex) {
                  if (!state.isTryActive) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('먼저 "트라이 시작"을 눌러주세요.')),
                    );
                    return;
                  }
                  notifier.selectHold(holdIndex);
                },
              ),
              const SizedBox(height: 14),
              const _TopoLegend(),
              const SizedBox(height: 20),
              _TryActionBar(
                state: state,
                notifier: notifier,
                holdCount: detail.holdCount,
                managerTips: managerTips,
              ),
              const SizedBox(height: 28),
              _StatGrid(detail: detail, myTryCountDisplay: myTryCountDisplay, bestHoldIndex: bestHoldIndex),
              const SizedBox(height: 28),
              Text('트라이 기록', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                detail.isGuestPreview
                    ? '게스트 체험 모드라 트라이 기록이 저장되지 않아요. 이 화면을 나가면 사라져요.'
                    : '이번 세션에 새로 기록한 트라이만 보여요. 이전 기록 조회는 준비 중이에요.',
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 10),
              _TryHistoryList(history: state.sessionHistory, holdCount: detail.holdCount),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestPreviewBanner extends StatelessWidget {
  const _GuestPreviewBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.holdCyan.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.holdCyan),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '게스트 체험 모드예요. 일부 정보는 예시이고, 트라이 기록은 이 화면을 나가면 사라져요. 로그인하면 저장돼요.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// 구간 경계(10개 단위)를 잇는 연결선은 생략한다 — 구간 라벨과 함께 구간감을 준다.
List<bool> _connectToNextList(int holdCount) => [
  for (var i = 0; i < holdCount - 1; i++) (i + 1) % _sectionSize != 0,
];

/// 각 구간의 첫 홀드(0-based index) → "1~10" 같은 라벨 텍스트.
Map<int, String> _groupLabels(int holdCount) => {
  for (var i = 0; i < holdCount; i += _sectionSize)
    i: '${i + 1}~${(i + _sectionSize <= holdCount) ? i + _sectionSize : holdCount}',
};

class _RouteTopo extends StatelessWidget {
  const _RouteTopo({
    required this.holdCount,
    required this.communityFallCounts,
    required this.bestHoldIndex,
    required this.lastFallHoldIndex,
    required this.pendingHoldIndex,
    required this.axis,
    required this.onTapHold,
  });

  final int holdCount;
  final Map<int, int> communityFallCounts;
  final int bestHoldIndex;
  final int? lastFallHoldIndex;
  final int? pendingHoldIndex;
  final Axis axis;
  final ValueChanged<int> onTapHold;

  static const _holdSpacingVertical = 34.0;
  static const _dividerGap = 30.0;
  static const _rowSpacingHorizontal = 64.0;
  static const _pad = 34.0;
  static const _verticalThickness = 150.0;

  int _nearestHold(Offset tapPos, List<Offset> positions) {
    var nearestIndex = 0;
    var nearestDist = double.infinity;
    for (var i = 0; i < positions.length; i++) {
      final d = (positions[i] - tapPos).distanceSquared;
      if (d < nearestDist) {
        nearestDist = d;
        nearestIndex = i;
      }
    }
    return nearestIndex + 1; // 1-based 홀드 순번
  }

  /// 볼더(세로 단일 컬럼) 배치 — 아래(시작)에서 위(완등)로.
  Widget _buildVertical() {
    final offsets = <double>[];
    var pos = 0.0;
    for (var i = 0; i < holdCount; i++) {
      if (i > 0) pos += (i % _sectionSize == 0) ? _dividerGap : _holdSpacingVertical;
      offsets.add(pos);
    }
    final extent = offsets.last + _pad * 2;
    final size = Size(_verticalThickness, extent);
    final positions = [
      for (var i = 0; i < holdCount; i++) Offset(_verticalThickness / 2, extent - _pad - offsets[i]),
    ];

    return Center(
      child: GestureDetector(
        onTapDown: (details) => onTapHold(_nearestHold(details.localPosition, positions)),
        child: CustomPaint(
          size: size,
          painter: _RouteTopoPainter(
            holdCount: holdCount,
            communityFallCounts: communityFallCounts,
            bestHoldIndex: bestHoldIndex,
            lastFallHoldIndex: lastFallHoldIndex,
            pendingHoldIndex: pendingHoldIndex,
            positions: positions,
            connectToNext: _connectToNextList(holdCount),
            groupLabels: _groupLabels(holdCount),
            labelAboveRow: false,
          ),
        ),
      ),
    );
  }

  /// 리드(가로, 10개 단위 구간을 줄바꿈) 배치 — 매번 왼쪽(시작)에서
  /// 오른쪽(완등)으로 읽되, 한 줄에 10홀드씩만 놓고 다음 구간은 아랫줄로.
  Widget _buildHorizontalWrapped() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = holdCount < _sectionSize ? holdCount : _sectionSize;
        final availableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
        final holdSpacing = columns > 1
            ? ((availableWidth - _pad * 2) / (columns - 1)).clamp(24.0, 40.0)
            : 0.0;
        final rows = (holdCount / _sectionSize).ceil();
        final positions = [
          for (var i = 0; i < holdCount; i++)
            Offset(_pad + (i % _sectionSize) * holdSpacing, _pad + (i ~/ _sectionSize) * _rowSpacingHorizontal),
        ];
        final size = Size(availableWidth, _pad * 2 + (rows - 1) * _rowSpacingHorizontal);

        return GestureDetector(
          onTapDown: (details) => onTapHold(_nearestHold(details.localPosition, positions)),
          child: CustomPaint(
            size: size,
            painter: _RouteTopoPainter(
              holdCount: holdCount,
              communityFallCounts: communityFallCounts,
              bestHoldIndex: bestHoldIndex,
              lastFallHoldIndex: lastFallHoldIndex,
              pendingHoldIndex: pendingHoldIndex,
              positions: positions,
              connectToNext: _connectToNextList(holdCount),
              groupLabels: _groupLabels(holdCount),
              labelAboveRow: true,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (holdCount <= 0) return const SizedBox.shrink();
    return axis == Axis.horizontal ? _buildHorizontalWrapped() : _buildVertical();
  }
}

class _RouteTopoPainter extends CustomPainter {
  _RouteTopoPainter({
    required this.holdCount,
    required this.communityFallCounts,
    required this.bestHoldIndex,
    required this.lastFallHoldIndex,
    required this.pendingHoldIndex,
    required this.positions,
    required this.connectToNext,
    required this.groupLabels,
    required this.labelAboveRow,
  });

  final int holdCount;
  final Map<int, int> communityFallCounts;
  final int bestHoldIndex;
  final int? lastFallHoldIndex;
  final int? pendingHoldIndex;

  /// 홀드(0-based index)의 중심 좌표 — 볼더/리드 배치 계산 결과를 그대로 받는다.
  final List<Offset> positions;

  /// positions[i] → positions[i+1] 연결선을 그릴지(구간 경계면 false).
  final List<bool> connectToNext;

  /// 구간 시작 인덱스(0-based) → 라벨 텍스트.
  final Map<int, String> groupLabels;

  /// true면 라벨을 홀드 위쪽에(가로 줄바꿈 배치), false면 오른쪽에(세로 배치) 그린다.
  final bool labelAboveRow;

  @override
  void paint(Canvas canvas, Size size) {
    if (holdCount <= 0) return;
    final maxFall = communityFallCounts.values.isEmpty
        ? 0
        : communityFallCounts.values.reduce((a, b) => a > b ? a : b);

    final linePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 3;

    for (var i = 0; i < connectToNext.length; i++) {
      if (!connectToNext[i]) continue;
      canvas.drawLine(positions[i], positions[i + 1], linePaint);
    }

    for (var index0 = 0; index0 < holdCount; index0++) {
      final holdNumber = index0 + 1;
      final center = positions[index0];
      final fallCount = communityFallCounts[holdNumber] ?? 0;
      final ratio = maxFall == 0 ? 0.0 : fallCount / maxFall;
      final fillColor = Color.lerp(AppColors.surfaceElevated, AppColors.holdMagenta, ratio)!;

      canvas.drawCircle(center, 9, Paint()..color = fillColor);
      canvas.drawCircle(
        center,
        9,
        Paint()
          ..color = AppColors.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      if (lastFallHoldIndex != null && holdNumber == lastFallHoldIndex) {
        canvas.drawCircle(
          center,
          14,
          Paint()
            ..color = AppColors.holdCyan
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
      if (bestHoldIndex > 0 && holdNumber == bestHoldIndex) {
        canvas.drawCircle(
          center,
          18,
          Paint()
            ..color = AppColors.holdLime
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
      if (holdNumber == pendingHoldIndex) {
        canvas.drawCircle(
          center,
          22,
          Paint()
            ..color = AppColors.textPrimary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      final label = groupLabels[index0];
      if (label != null) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, fontWeight: FontWeight.w700),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final labelOffset = labelAboveRow
            ? Offset(center.dx - textPainter.width / 2, center.dy - 28)
            : Offset(center.dx + 26, center.dy - textPainter.height / 2);
        textPainter.paint(canvas, labelOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RouteTopoPainter oldDelegate) {
    return oldDelegate.holdCount != holdCount ||
        oldDelegate.bestHoldIndex != bestHoldIndex ||
        oldDelegate.lastFallHoldIndex != lastFallHoldIndex ||
        oldDelegate.pendingHoldIndex != pendingHoldIndex ||
        oldDelegate.labelAboveRow != labelAboveRow ||
        !listEquals(oldDelegate.positions, positions) ||
        !mapEquals(oldDelegate.communityFallCounts, communityFallCounts);
  }
}

class _TopoLegend extends StatelessWidget {
  const _TopoLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget item(Widget marker, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [marker, const SizedBox(width: 6), Text(label, style: theme.textTheme.bodyMedium)],
    );
    Widget ring(Color color, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
    );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        item(ring(AppColors.holdLime, 14), '내 최고 도달'),
        item(ring(AppColors.holdCyan, 12), '내 최근 낙하'),
        item(ring(AppColors.textPrimary, 12), '선택 중인 지점'),
        item(
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.holdMagenta),
          ),
          '많이 떨어진 홀드',
        ),
      ],
    );
  }
}

class _TryActionBar extends StatelessWidget {
  const _TryActionBar({
    required this.state,
    required this.notifier,
    required this.holdCount,
    required this.managerTips,
  });

  final ProblemTryState state;
  final ProblemTryNotifier notifier;
  final int holdCount;
  final Map<int, String> managerTips;

  @override
  Widget build(BuildContext context) {
    if (!state.isTryActive) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: notifier.startTry,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('트라이 시작'),
        ),
      );
    }

    final pending = state.pendingHoldIndex;
    final isTopHold = pending == holdCount;
    return Column(
      children: [
        Text(
          pending == null ? '루트에서 도달한 지점을 탭해주세요.' : '$pending번째 홀드를 선택했어요.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: notifier.cancelTry, child: const Text('취소')),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: pending == null
                    ? null
                    : () => _showFallMemoSheet(
                        context,
                        isTopHold: isTopHold,
                        holdIndex: pending,
                        managerTip: managerTips[pending],
                        onConfirm: (memo) => notifier.fellHere(memo: memo),
                      ),
                child: Text(isTopHold ? '완등으로 기록' : '여기서 떨어짐'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// '여기서 떨어짐'/'완등으로 기록'을 누르면 뜨는 확인 모달 — "어떤 홀드였나요?"
/// 메모(선택 입력)와 그 홀드에 등록된 점장님의 팁을 함께 보여준 뒤 실제로
/// POST /api/problemTryLog를 호출해 기록을 확정한다.
Future<void> _showFallMemoSheet(
  BuildContext context, {
  required bool isTopHold,
  required int holdIndex,
  required String? managerTip,
  required Future<bool> Function(String? memo) onConfirm,
}) {
  final controller = TextEditingController();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      var submitting = false;
      return StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTopHold ? '완등을 기록할까요?' : '$holdIndex번째 홀드에서 떨어졌어요',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  Text('어떤 홀드였나요?', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    enabled: !submitting,
                    maxLines: 3,
                    maxLength: 100,
                    decoration: const InputDecoration(hintText: '예: 왼손 크림프가 미끄러웠어요 (선택 입력)'),
                  ),
                  const SizedBox(height: 4),
                  _ManagerTipCard(tip: managerTip),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: submitting ? null : () => Navigator.of(context).pop(),
                          child: const Text('취소'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: submitting
                              ? null
                              : () async {
                                  setModalState(() => submitting = true);
                                  final memo = controller.text.trim();
                                  final ok = await onConfirm(memo.isEmpty ? null : memo);
                                  if (!context.mounted) return;
                                  if (ok) {
                                    Navigator.of(context).pop();
                                  } else {
                                    setModalState(() => submitting = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('기록하지 못했어요. 다시 시도해주세요.')),
                                    );
                                  }
                                },
                          child: submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10120A)),
                                )
                              : Text(isTopHold ? '완등으로 기록' : '기록하기'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _ManagerTipCard extends StatelessWidget {
  const _ManagerTipCard({required this.tip});

  final String? tip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_objects_outlined, size: 16, color: AppColors.holdCyan),
              SizedBox(width: 6),
              Text(
                '점장님의 팁',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.holdCyan),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(tip ?? '이 홀드에 등록된 팁이 아직 없어요.', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.detail, required this.myTryCountDisplay, required this.bestHoldIndex});

  final GymProblemDetail detail;
  final int myTryCountDisplay;
  final int bestHoldIndex;

  @override
  Widget build(BuildContext context) {
    final bestLabel = bestHoldIndex <= 0
        ? '-'
        : (bestHoldIndex >= detail.holdCount ? '완등' : '$bestHoldIndex번째');
    return Row(
      children: [
        Expanded(child: _StatTile(label: '홀드 갯수', value: '${detail.holdCount}개')),
        const SizedBox(width: 8),
        Expanded(child: _StatTile(label: '내 트라이', value: '$myTryCountDisplay회')),
        const SizedBox(width: 8),
        Expanded(child: _StatTile(label: '내 최고 도달', value: bestLabel)),
        const SizedBox(width: 8),
        Expanded(child: _StatTile(label: '클리어 인원', value: '${detail.clearCount}명')),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

class _TryHistoryList extends StatelessWidget {
  const _TryHistoryList({required this.history, required this.holdCount});

  final List<ProblemTryLog> history;
  final int holdCount;

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (history.isEmpty) {
      return Text('아직 기록된 트라이가 없어요. "트라이 시작"으로 첫 기록을 남겨보세요.', style: theme.textTheme.bodyMedium);
    }

    return Column(
      children: [
        for (var i = 0; i < history.length; i++) ...[
          _TryHistoryRow(log: history[i], holdCount: holdCount, formatDate: _formatDate),
          if (i != history.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TryHistoryRow extends StatelessWidget {
  const _TryHistoryRow({required this.log, required this.holdCount, required this.formatDate});

  final ProblemTryLog log;
  final int holdCount;
  final String Function(DateTime?) formatDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cleared = log.dropPoint >= holdCount;
    final dotColor = cleared ? AppColors.holdLime : AppColors.holdMagenta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cleared ? '완등! (${log.dropPoint}번째 홀드)' : '${log.dropPoint}번째 홀드에서 낙하',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Text(formatDate(log.tryDateTime), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
          if (log.memo != null && log.memo!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Text(
                '"${log.memo}"',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
      ),
    );
  }
}
