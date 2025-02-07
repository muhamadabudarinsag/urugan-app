// lib/screens/base_page.dart

import 'package:flutter/material.dart';
import '../models/user_role.dart'; // Import the user role enum

abstract class BasePage extends StatelessWidget {
  const BasePage({super.key});

  String get title; // Title of the page

  // Check if the user role can access this page
  bool canAccess(UserRole role);
}
