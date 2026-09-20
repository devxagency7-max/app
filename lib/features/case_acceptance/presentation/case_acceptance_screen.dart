import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../cases/data/cases_providers.dart';
import '../../home/domain/social_worker_case.dart';

/// شاشة "قبول الحالات" — الحالات التي كلّفك بها موظف الإدخال من الويب
/// وتنتظر تأكيد استلامك. بعد القبول تنتقل إلى "كل حالاتي".
class CaseAcceptanceScreen extends ConsumerWidget {
  const CaseAcceptanceScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CaseAcceptanceScreen()),
    );
  }

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    SocialWorkerCase item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(casesRepositoryProvider).accept(item.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'تم قبول واستلام حالة (${item.personName}) وإضافتها لقائمة مهامك',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تعذّر قبول الحالة — تحقق من الاتصال وحاول مرة أخرى'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingAcceptanceProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('قبول واستلام الحالات'),
          elevation: 0,
        ),
        body: pending.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xxl),
              child: Text(
                'تعذّر تحميل الحالات — تحقق من الاتصال بالإنترنت',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          data: (cases) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (cases.isEmpty)
                const _EmptyState()
              else
                for (final item in cases) ...[
                  _PendingCaseCard(
                    item: item,
                    onAccept: () => _accept(context, ref, item),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingCaseCard extends StatefulWidget {
  final SocialWorkerCase item;
  final Future<void> Function() onAccept;

  const _PendingCaseCard({required this.item, required this.onAccept});

  @override
  State<_PendingCaseCard> createState() => _PendingCaseCardState();
}

class _PendingCaseCardState extends State<_PendingCaseCard> {
  bool _accepting = false;

  Future<void> _handleAccept() async {
    setState(() => _accepting = true);
    await widget.onAccept();
    if (mounted) setState(() => _accepting = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final at = item.lastUpdatedAt;
    final now = DateTime.now();
    final isToday =
        at.year == now.year && at.month == now.month && at.day == now.day;
    final time = DateFormat('h:mm a', 'ar').format(at);
    final assigned = isToday
        ? 'اليوم، $time'
        : DateFormat('d/M، h:mm a', 'ar').format(at);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.personName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                item.displayId,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          if (item.village != null && item.village!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  item.village!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'أُسندت: $assigned',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _accepting ? null : _handleAccept,
              icon: _accepting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('قبول واستلام الحالة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          children: [
            _EmptyIcon(),
            SizedBox(height: AppSpacing.lg),
            Text(
              'تم قبول جميع الحالات المسندة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'لا توجد حالات جديدة معلقة للإسناد حالياً',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyIcon extends StatelessWidget {
  const _EmptyIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle_outline,
        size: 48,
        color: AppColors.success,
      ),
    );
  }
}
