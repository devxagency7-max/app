import 'package:cloud_firestore/cloud_firestore.dart';

import '../../home/domain/case_priority.dart';
import '../../home/domain/social_worker_case.dart';

/// حالة التكليف على مستند الحالة (`assignmentStatus`) — يكتبها تطبيق الويب.
class AssignmentStatus {
  const AssignmentStatus._();

  static const pendingAcceptance = 'pending_acceptance';
  static const accepted = 'accepted';
}

/// حالات الأخصائي من Firestore (مجموعة `الحالات` — نفس مجموعة تطبيق الويب).
///
/// أونلاين بحت: لا كاش محلي.
class CasesRepository {
  CasesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const collectionName = 'الحالات';

  CollectionReference<Map<String, dynamic>> get _cases =>
      _firestore.collection(collectionName);

  /// الحالات المُسندة للأخصائي والمنتظرة قبوله.
  Stream<List<SocialWorkerCase>> watchPendingAcceptance(String uid) =>
      _watch(uid, AssignmentStatus.pendingAcceptance);

  /// الحالات التي قبلها الأخصائي — "كل حالاتي".
  Stream<List<SocialWorkerCase>> watchAccepted(String uid) =>
      _watch(uid, AssignmentStatus.accepted);

  Stream<List<SocialWorkerCase>> _watch(String uid, String assignmentStatus) {
    return _cases
        .where('assignedTo', isEqualTo: uid)
        .where('assignmentStatus', isEqualTo: assignmentStatus)
        .snapshots()
        .map((snapshot) {
          final cases = snapshot.docs.map(_toCase).toList()
            ..sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
          return cases;
        });
  }

  /// قبول واستلام الحالة — تنتقل من "قبول الحالات" إلى "كل حالاتي".
  Future<void> accept(String caseId) {
    return _cases.doc(caseId).update({
      'assignmentStatus': AssignmentStatus.accepted,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  SocialWorkerCase _toCase(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final assignmentStatus = data['assignmentStatus'] as String?;
    final updated =
        _date(data['acceptedAt']) ??
        _date(data['assignedAt']) ??
        _date(data['updatedAt']) ??
        _date(data['createdAt']) ??
        DateTime.now();

    return SocialWorkerCase(
      id: doc.id,
      displayId: '#${doc.id.substring(0, doc.id.length < 6 ? doc.id.length : 6)}',
      personName: data['name'] as String? ?? '',
      village: data['village'] as String?,
      priority: CasePriority.medium,
      status: assignmentStatus == AssignmentStatus.pendingAcceptance
          ? CaseWorkStatus.assigned
          : CaseWorkStatus.inProgress,
      origin: CaseOrigin.dataEntry,
      progress: 0,
      lastUpdatedAt: updated,
    );
  }

  static DateTime? _date(Object? value) =>
      value is Timestamp ? value.toDate() : null;
}
