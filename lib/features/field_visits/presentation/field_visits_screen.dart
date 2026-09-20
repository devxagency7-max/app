import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import 'field_visit_form_screen.dart';

/// قائمة الزيارات الميدانية لحالة معيّنة.
///
/// TODO(firebase): بلا مصدر بيانات حاليًا — تُربَط بـ Firestore لاحقًا.
class FieldVisitsScreen extends StatelessWidget {
  final String caseId;
  final String personName;

  const FieldVisitsScreen({
    super.key,
    required this.caseId,
    required this.personName,
  });

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الزيارات الميدانية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Text(
                personName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FieldVisitFormScreen(caseId: caseId),
            ),
          ),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('زيارة جديدة'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: Text(
              'لا توجد زيارات مسجَّلة بعد.\nاضغط "زيارة جديدة" لتسجيل أول زيارة ميدانية.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
