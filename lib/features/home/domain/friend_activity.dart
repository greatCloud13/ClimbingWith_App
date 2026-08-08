import 'package:flutter/material.dart';

class FriendActivity {
  const FriendActivity({
    required this.friendNickname,
    required this.gymName,
    required this.grade,
    required this.timeAgo,
    required this.accent,
  });

  final String friendNickname;
  final String gymName;
  final String grade;
  final String timeAgo;
  final Color accent;
}
