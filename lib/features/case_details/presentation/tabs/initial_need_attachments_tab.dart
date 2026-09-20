import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/sections/initial_need_form.dart';
import '../widgets/add_attachment_sheet.dart';
import '../widgets/section_card.dart';
import '../widgets/tab_progress_bar.dart';

/// تاب المرفقات والمستندات.
///
/// TODO(firebase): بلا مصدر بيانات حاليًا — الرفع والقائمة يُربَطان بـ
/// Firebase Storage/Firestore لاحقًا.
///
/// [initialData]/[onChanged] يحملان بيانات الاحتياج الأولي فقط لأجل
/// [CaseReadiness] (قسم بيانات اختياري لا يمنع الإرسال) — هذا التاب
/// بصريًا مرفقات فقط ولا يقرأ أو يعدّل عليهما.
class InitialNeedAttachmentsTab extends StatefulWidget {
  final String caseId;
  final InitialNeedFormData initialData;
  final ValueChanged<InitialNeedFormData> onChanged;

  const InitialNeedAttachmentsTab({
    super.key,
    required this.caseId,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<InitialNeedAttachmentsTab> createState() =>
      _InitialNeedAttachmentsTabState();
}

class _InitialNeedAttachmentsTabState extends State<InitialNeedAttachmentsTab> {
  static const _capturing = false;

  void _capture() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('رفع المرفقات غير مربوط بعد')));
  }

  Future<void> _handleAddAttachment() async {
    final attachment = await AddAttachmentSheet.show(context);
    if (attachment == null || !mounted) return;
    _capture();
  }

  Future<void> _handleCameraCapture() async {
    final attachment = await AddAttachmentSheet.captureFromCameraAndSelectType(
      context,
    );
    if (attachment == null || !mounted) return;
    _capture();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const TabProgressBar(progress: 0),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  125,
                ),
                children: [
                  Text(
                    'المستندات والمرفقات (0)',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const SectionEmptyState(message: 'لا توجد مرفقات بعد'),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _capturing ? null : _handleAddAttachment,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: const Text('رفع صورة / مستند جديد'),
                  ),
                ],
              ),
            ),
          ],
        ),
        // زر الكاميرا العائم الأزرق أعلى زر الرجوع مباشرة بمسافة مريحة
        PositionedDirectional(
          start: AppSpacing.lg,
          bottom: 40.0,
          child: Tooltip(
            message: 'التقاط صورة بالكاميرا وإضافة مرفق',
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              elevation: 5,
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
              child: InkWell(
                onTap: _capturing ? null : _handleCameraCapture,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 54,
                  height: 54,
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
