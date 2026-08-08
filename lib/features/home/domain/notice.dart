import 'package:flutter/material.dart';

class Notice {
  const Notice({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.accent,
  });

  final String id;
  final String title;
  final String subtitle;
  final String body;
  final Color accent;
}
