import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/location_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../case_details/presentation/widgets/section_card.dart';

/// نموذج تسجيل زيارة ميدانية واحدة.
///
/// TODO(firebase): الحفظ ورفع الصور يُربَطان بـ Firebase لاحقًا.
class FieldVisitFormScreen extends StatefulWidget {
  final String caseId;

  const FieldVisitFormScreen({super.key, required this.caseId});

  @override
  State<FieldVisitFormScreen> createState() => _FieldVisitFormScreenState();
}

class _FieldVisitFormScreenState extends State<FieldVisitFormScreen> {
  late DateTime _visitDate;
  final _outcomeController = TextEditingController();
  final _notesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationDescController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _locating = false;
  String? _locationError;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _visitDate = DateTime.now();
    // الالتقاط التلقائي عند فتح نموذج زيارة جديدة — بلا أثر لو رفض الصلاحية
    // (§15.10: الموقع اختياري بالكامل).
    unawaited(_captureLocation());
  }

  @override
  void dispose() {
    _outcomeController.dispose();
    _notesController.dispose();
    _descriptionController.dispose();
    _locationDescController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });

    final result = await const LocationService().capture();
    if (!mounted) return;

    setState(() {
      _locating = false;
      switch (result) {
        case LocationCaptured(:final latitude, :final longitude):
          _latitude = latitude;
          _longitude = longitude;
        case LocationUnavailable(:final message):
          _locationError = message;
      }
    });
  }

  void _clearLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
      _locationError = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      // §20.9: لا يجوز تاريخ في المستقبل (بتسامح يوم واحد لفارق التوقيت).
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  bool get _isValid => _outcomeController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('نتيجة الزيارة حقل إلزامي.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // TODO(firebase): حفظ الزيارة في Firestore.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('حفظ الزيارة غير مربوط بعد')),
    );
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMMM yyyy', 'ar');

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'زيارة ميدانية جديدة',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            120,
          ),
          children: [
            SectionCard(
              title: 'موعد الزيارة',
              child: InkWell(
                onTap: _pickDate,
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      df.format(_visitDate),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'نتيجة الزيارة *',
              child: TextField(
                controller: _outcomeController,
                maxLines: 3,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText: 'اكتب ملخّص نتيجة الزيارة الميدانية...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'وصف ما تم أثناء الزيارة',
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText: 'اختياري...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: 'ملاحظات',
              child: TextField(
                controller: _notesController,
                maxLines: 2,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText: 'اختياري...',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _LocationCard(
              latitude: _latitude,
              longitude: _longitude,
              locating: _locating,
              error: _locationError,
              descriptionController: _locationDescController,
              onRetry: _captureLocation,
              onClear: _clearLocation,
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'حفظ الزيارة',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final bool locating;
  final String? error;
  final TextEditingController descriptionController;
  final VoidCallback onRetry;
  final VoidCallback onClear;

  const _LocationCard({
    required this.latitude,
    required this.longitude,
    required this.locating,
    required this.error,
    required this.descriptionController,
    required this.onRetry,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null;

    return SectionCard(
      title: 'الموقع (GPS)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (locating)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'جارٍ تحديد الموقع...',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            )
          else if (hasLocation)
            Row(
              children: [
                const Icon(Icons.my_location, size: 16, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  child: const Text('إزالة', style: TextStyle(fontSize: 12)),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (error != null) ...[
                  Text(
                    error!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.my_location, size: 16),
                  label: const Text('تحديد الموقع الحالي'),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: descriptionController,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'وصف نصي للموقع (اختياري)، مثال: بجوار المسجد',
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
