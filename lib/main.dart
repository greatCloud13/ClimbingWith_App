import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/application/auth_state.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/shell/app_shell.dart';

void main() {
  runApp(const ProviderScope(child: ClimbingCommunityApp()));
}

class ClimbingCommunityApp extends StatelessWidget {
  const ClimbingCommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClimbingWith',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AuthGate(),
    );
  }
}

/// 저장된 세션 복원 여부에 따라 로그인 화면과 메인 화면을 전환한다.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    return switch (authState) {
      AuthChecking() => const Scaffold(body: Center(child: CircularProgressIndicator())),
      AuthUnauthenticated() => const LoginScreen(),
      AuthAuthenticated() => const AppShell(),
    };
  }
}
