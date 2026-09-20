import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_background.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final bool isUnread;
  final IconData icon;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isUnread = false,
    required this.icon,
  });
}

const List<AppNotificationItem> _mockNotifications = [
  AppNotificationItem(
    id: 'n1',
    title: 'إرجاع حالة',
    subtitle: 'تم إرجاع حالة فاطمة رمضان من المراجع لمراجعة السكن.',
    time: 'منذ 15 دقيقة',
    isUnread: true,
    icon: Icons.assignment_return_outlined,
  ),
  AppNotificationItem(
    id: 'n2',
    title: 'إسناد حالة جديدة',
    subtitle: 'تم إسناد حالة جديدة إليك: أحمد محمود علي.',
    time: 'منذ ساعة',
    isUnread: true,
    icon: Icons.assignment_ind_outlined,
  ),
  AppNotificationItem(
    id: 'n3',
    title: 'موافقة على الدعم',
    subtitle: 'تمت الموافقة على الدعم المقترح لحالة محمد حسن.',
    time: 'منذ 3 ساعات',
    isUnread: false,
    icon: Icons.check_circle_outline,
  ),
  AppNotificationItem(
    id: 'n4',
    title: 'زيارة ميدانية',
    subtitle: 'موعد الزيارة الميدانية اليوم الساعة 2:00 مساءً.',
    time: 'أمس',
    isUnread: false,
    icon: Icons.calendar_today_outlined,
  ),
  AppNotificationItem(
    id: 'n5',
    title: 'تحديث بيانات',
    subtitle: 'تم حفظ وتحديث بيانات الحالة بنجاح.',
    time: 'منذ يومين',
    isUnread: false,
    icon: Icons.update_outlined,
  ),
];

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<AppNotificationItem> _notifications = List.from(_mockNotifications);

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications.map((n) {
        return AppNotificationItem(
          id: n.id,
          title: n.title,
          subtitle: n.subtitle,
          time: n.time,
          isUnread: false,
          icon: n.icon,
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n.isUnread).length;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('الإشعارات والتنبيهات'),
          elevation: 0,
          actions: [
            if (unreadCount > 0)
              TextButton(
                onPressed: _markAllAsRead,
                child: const Text(
                  'قراءة الكل',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        body: _notifications.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد إشعارات حالياً',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: item.isUnread
                          ? AppColors.primaryLight.withOpacity(0.4)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: item.isUnread
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.isUnread
                                ? AppColors.primary.withOpacity(0.12)
                                : AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            size: 20,
                            color: item.isUnread
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: item.isUnread
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    item.time,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
