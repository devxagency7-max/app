/// رأي الأخصائي — الكارت الوحيد القابل للتعديل من الأخصائي في تاب
/// "التقييمات". رأي المراجع ورأي مدير التنمية View-only (يُملأن من
/// الأدوار المعنية عبر شاشاتهم الخاصة، لا من تطبيق الأخصائي).
class SocialWorkerOpinionCardData {
  String? briefOpinion; // الرأي المختصر: موافق / غير موافق
  String? detailedReport;

  SocialWorkerOpinionCardData({
    this.briefOpinion = 'لم يتم البدء',
    this.detailedReport,
  });

  bool get isFilled =>
      (briefOpinion ?? '').trim().isNotEmpty &&
      (detailedReport ?? '').trim().isNotEmpty;
}

/// رأي المراجع — View-only، يُعرض بعد أن يملأه المراجع من شاشته الخاصة.
class ReviewerOpinionCardData {
  final String? briefOpinion;
  final String? notes;

  const ReviewerOpinionCardData({this.briefOpinion, this.notes});
}

/// رأي مدير التنمية — View-only، القرار النهائي (اعتماد/رفض) يُتخذ من
/// شاشة المدير الخاصة، ليس من تطبيق الأخصائي.
class DirectorDecisionCardData {
  final String? finalDecision;
  final String? approvalOrRejectionNote;

  const DirectorDecisionCardData({
    this.finalDecision,
    this.approvalOrRejectionNote,
  });
}

class OpinionsFormData {
  SocialWorkerOpinionCardData socialWorker;
  ReviewerOpinionCardData? reviewer;
  DirectorDecisionCardData? director;

  OpinionsFormData({
    SocialWorkerOpinionCardData? socialWorker,
    this.reviewer,
    this.director,
  }) : socialWorker = socialWorker ?? SocialWorkerOpinionCardData();

  double get progress => socialWorker.isFilled ? 1.0 : 0.0;
}
