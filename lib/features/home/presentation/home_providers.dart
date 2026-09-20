import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../cases/data/cases_providers.dart';
import '../domain/home_summary.dart';
import '../domain/social_worker_case.dart';

/// بيانات الشاشة الرئيسية — من الحالات التي قبلها الأخصائي.
final homeDataProvider = StreamProvider.autoDispose<HomeData>((ref) {
  final user = ref.watch(currentUserProvider);
  final repository = ref.watch(casesRepositoryProvider);
  if (user == null) return const Stream.empty();

  return repository.watchAccepted(user.id).map((cases) {
    final active = <SocialWorkerCase>[];
    final submitted = <SocialWorkerCase>[];
    var returned = 0;

    for (final item in cases) {
      switch (item.status) {
        case CaseWorkStatus.submittedForReview:
          submitted.add(item);
        case CaseWorkStatus.returnedFromReview ||
            CaseWorkStatus.returnedFromManager:
          returned++;
          active.add(item);
        default:
          active.add(item);
      }
    }

    return HomeData(
      socialWorkerName: user.fullName,
      unreadNotifications: 0,
      counters: HomeCounters(
        allCases: cases.length,
        savedCases: 0,
        returnedCases: returned,
      ),
      priorityTasks: active,
      submittedCases: submitted,
    );
  });
});
