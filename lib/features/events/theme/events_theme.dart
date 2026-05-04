import 'package:flutter/material.dart';

class EventsTheme {
  // Vibrant Rose
  static const Color primary = Color(0xFFE11D48);
  static const Color onPrimary = Color(0xFFFFFFFF);
  // Engagement Blue
  static const Color accent = Color(0xFF2563EB);
  
  static const Color destructive = Color(0xFFDC2626);

  // Dark Mode specific colors (inspired by Whop screenshot)
  static const Color darkBackground = Color(0xFF121212); // Deep dark
  static const Color darkCardBackground = Color(0xFF1E1E1E); // Elevated dark
  static const Color darkCardStroke = Color(0xFF333333); // Border
  static const Color darkForeground = Color(0xFFFAFAFA);
  static const Color darkMuted = Color(0xFFA0A0A0);

  // Typography
  static const String headingFont = 'Barlow Condensed';
  static const String bodyFont = 'Barlow';
  
  // Gradients
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF8C00), Color(0xFFFF5F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
