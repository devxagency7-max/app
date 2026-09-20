import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../home/domain/social_worker_case.dart';
import 'cases_repository.dart';

final casesRepositoryProvider = Provider<CasesRepository>(
  (ref) => CasesRepository(),
);

/// الحالات المنتظرة قبول الأخصائي الحالي.
final pendingAcceptanceProvider =
    StreamProvider.autoDispose<List<SocialWorkerCase>>((ref) {
      final user = ref.watch(currentUserProvider);
      if (user == null) return Stream.value(const []);
      return ref.watch(casesRepositoryProvider).watchPendingAcceptance(user.id);
    });

/// الحالات التي قبلها الأخصائي الحالي — "كل حالاتي".
final acceptedCasesProvider =
    StreamProvider.autoDispose<List<SocialWorkerCase>>((ref) {
      final user = ref.watch(currentUserProvider);
      if (user == null) return Stream.value(const []);
      return ref.watch(casesRepositoryProvider).watchAccepted(user.id);
    });
