import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../case_details/presentation/open_case_details.dart';
import '../../home/domain/home_summary.dart';
import '../../home/domain/social_worker_case.dart';
import '../../home/presentation/widgets/case_card.dart';
import 'case_list_filter.dart';

/// صفحة الحالات المفلترة — تُفتح من كروت الأرقام السريعة في الـ Home،
/// كل كارت (زيارات اليوم / متأخرة / مرتجعة) يفتحها على التاب المطابق.
class CaseListScreen extends StatefulWidget {
  final HomeData data;
  final CaseListFilter initialFilter;

  const CaseListScreen({
    super.key,
    required this.data,
    required this.initialFilter,
  });

  @override
  State<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends State<CaseListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  late final List<SocialWorkerCase> _allCases = [
    ...widget.data.priorityTasks,
    ...widget.data.submittedCases,
  ];

  bool _isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  List<SocialWorkerCase> _casesFor(CaseListFilter filter) {
    switch (filter) {
      case CaseListFilter.allCases:
        return _allCases;
      case CaseListFilter.saved:
        return _allCases
            .where((c) =>
                c.status == CaseWorkStatus.inProgress ||
                c.status == CaseWorkStatus.readyForReview)
            .toList();
      case CaseListFilter.returned:
        return _allCases
            .where((c) => c.status == CaseWorkStatus.returnedFromReview)
            .toList();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: CaseListFilter.values.length,
      vsync: this,
      initialIndex: widget.initialFilter.index,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('الحالات'),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
            tabs: [
              for (final filter in CaseListFilter.values)
                Tab(text: filter.label),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            for (final filter in CaseListFilter.values)
              _CaseListTab(cases: _casesFor(filter)),
          ],
        ),
      ),
    );
  }
}

class _CaseListTab extends StatelessWidget {
  final List<SocialWorkerCase> cases;

  const _CaseListTab({required this.cases});

  @override
  Widget build(BuildContext context) {
    if (cases.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد حالات في هذا القسم حاليًا',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: cases.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final item = cases[index];
        return CaseCard(caseItem: item, onTap: () => item.openDetails(context));
      },
    );
  }
}
