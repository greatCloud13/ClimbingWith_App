import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/mat_texture_background.dart';
import '../data/gym_detail_mock_data.dart';
import '../domain/gym_detail.dart';
import '../domain/sector.dart';

class SectorProblemsScreen extends StatelessWidget {
  const SectorProblemsScreen({
    super.key,
    required this.gymId,
    required this.sectorId,
    this.gym,
    this.sector,
  });

  final String gymId;
  final String sectorId;
  final GymDetail? gym;
  final Sector? sector;

  @override
  Widget build(BuildContext context) {
    final resolvedGym = gym ?? mockGymDetails[gymId];
    final resolvedSector =
        sector ?? resolvedGym?.sectors.firstWhere((s) => s.id == sectorId);
    final theme = Theme.of(context);

    if (resolvedGym == null || resolvedSector == null) {
      return const Scaffold(body: Center(child: Text('섹터 정보를 찾을 수 없습니다.')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(resolvedSector.name)),
      body: MatTextureBackground(
        child: SafeArea(
          child: resolvedSector.problems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      resolvedSector.problemCount > 0
                          ? '문제 목록은 아직 준비 중입니다. (총 ${resolvedSector.problemCount}개)'
                          : '등록된 문제가 아직 없어요.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: resolvedSector.problems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final problem = resolvedSector.problems[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: problem.tapeColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    problem.grade,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${problem.setter} 셋팅 · ${problem.setDate}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
