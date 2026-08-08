import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/app_shell.dart';

void main() {
  runApp(const ClimbingCommunityApp());
}

class ClimbingCommunityApp extends StatelessWidget {
  const ClimbingCommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '클라임로그',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}
