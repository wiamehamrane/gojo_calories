import 'package:flutter/material.dart';

class AppShadows {
  static const cardShadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 2)),
  ];

  static const cardElevated = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 4)),
  ];

  static const fabShadow = [
    BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const navShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 0, offset: Offset(0, -1)),
  ];
}
