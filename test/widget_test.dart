import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nahda/features/auth/domain/auth_user.dart';
import 'package:nahda/features/auth/presentation/auth_controller.dart';
import 'package:nahda/features/auth/presentation/login_screen.dart';
import 'package:nahda/features/home/domain/home_summary.dart';
import 'package:nahda/features/home/presentation/home_providers.dart';
import 'package:nahda/main.dart';

/// اختبارات جذر التطبيق وشاشة الدخول.
///
/// ملاحظة: الدخول الوهمي القديم (ضغطة زر ← الصفحة الرئيسية) لم يعد موجودًا —
/// الاختبار يحقن وحدة تحكّم مزيّفة بحالة ثابتة.
void main() {
  testWidgets('شاشة الدخول تظهر حين لا توجد جلسة', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _FakeAuthController(const AuthSignedOut()),
          ),
        ],
        child: const NahdaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('منظومة النهضة'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
  });

  testWidgets('حقل البريد يرفض صيغة غير صحيحة', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _FakeAuthController(const AuthSignedOut()),
          ),
        ],
        child: const NahdaApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'ليس بريدًا');
    await tester.tap(find.text('تسجيل الدخول').last);
    await tester.pumpAndSettle();

    expect(find.text('صيغة البريد الإلكتروني غير صحيحة'), findsOneWidget);
  });

  testWidgets('الصفحة الرئيسية تظهر عند وجود جلسة', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _FakeAuthController(
              const AuthSignedIn(
                AuthUser(
                  id: 'u1',
                  fullName: 'محمد أحمد',
                  email: 'worker@nahda.org',
                  role: 'social_worker',
                  permissions: ['view_cases', 'edit_case'],
                ),
              ),
            ),
          ),
          homeDataProvider.overrideWith(
            (ref) => Stream.value(
              const HomeData(
                socialWorkerName: 'محمد أحمد',
                unreadNotifications: 0,
                counters: HomeCounters(
                  allCases: 0,
                  savedCases: 0,
                  returnedCases: 0,
                ),
                priorityTasks: [],
                submittedCases: [],
              ),
            ),
          ),
        ],
        child: const NahdaApp(),
      ),
    );

    // لا pumpAndSettle: الشاشة تحوي عناصر متحركة مستمرة بالتصميم.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // شاشة الدخول غادرت — وهذا ما يثبت أن الجلسة فُعِّلت.
    // محتوى الرئيسية نفسه يُغذّى من قاعدة فارغة هنا، فلا نؤكّد عليه.
    expect(find.text('البريد الإلكتروني'), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);
  });
}

/// وحدة تحكّم مصادقة بحالة ثابتة — بحالة ثابتة.
class _FakeAuthController extends AuthController {
  _FakeAuthController(AuthState initial) : super() {
    state = initial;
  }

  @override
  Future<void> restore() async {
    // لا شيء — الحالة مضبوطة مسبقًا.
  }

  @override
  Future<String?> login({
    required String email,
    required String password,
  }) async => null;
}
