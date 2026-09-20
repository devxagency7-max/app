import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_user.dart';

/// حالة المصادقة.
sealed class AuthState {
  const AuthState();
}

/// جارٍ استعادة الجلسة عند الإقلاع.
class AuthRestoring extends AuthState {
  const AuthRestoring();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.reason});

  /// سبب الخروج — يُعرَض في شاشة الدخول.
  final String? reason;
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);

  final AuthUser user;
}

/// TODO(firebase): مؤقت بلا أي تحقق — يُستبدَل بـ Firebase Auth.
class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthRestoring());

  /// يُستدعى مرة عند إقلاع التطبيق.
  Future<void> restore() async {
    if (!mounted) return;
    state = const AuthSignedOut();
  }

  /// يرجع `null` عند النجاح، أو رسالة الخطأ لعرضها في الشاشة.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    state = AuthSignedIn(
      AuthUser(
        id: '',
        fullName: '',
        email: email.trim(),
        role: 'social_worker',
        permissions: const [],
      ),
    );
    return null;
  }

  Future<void> logout() async {
    if (mounted) state = const AuthSignedOut();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
      return AuthController();
    });

/// المستخدم الحالي — `null` حين لا توجد جلسة.
final currentUserProvider = Provider<AuthUser?>((ref) {
  final state = ref.watch(authControllerProvider);
  return state is AuthSignedIn ? state.user : null;
});
