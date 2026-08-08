import 'package:flutter/material.dart';
import '../../core/widgets/mat_texture_background.dart';

/// 저장된 세션을 복원하는 동안 잠깐 보여주는 화면.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MatTextureBackground(
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
