// lib/screens/notifications_page.dart

import 'package:flutter/material.dart';
import 'base_page.dart';
import '../models/user_role.dart'; // Import the user role enum

class NotificationsPage extends BasePage {
  const NotificationsPage({super.key});

  @override
  String get title => 'Notifications';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  @override
  bool canAccess(UserRole role) {
    return true; // All roles can access this page
  }
}
