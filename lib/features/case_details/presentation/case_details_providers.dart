import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_case_details_repository.dart';
import '../domain/case_details_repository.dart';
import '../domain/case_full_details.dart';

final caseDetailsRepositoryProvider = Provider<CaseDetailsRepository>((ref) {
  return MockCaseDetailsRepository();
});

final caseDetailsProvider = FutureProvider.autoDispose
    .family<CaseFullDetails, String>((ref, caseId) async {
      final repository = ref.watch(caseDetailsRepositoryProvider);
      return repository.getCaseDetails(caseId);
    });
