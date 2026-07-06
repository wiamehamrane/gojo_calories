import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Positions a [FloatingActionButton] above the floating bottom nav bar
/// rendered by [MainScaffold].
class FabAboveNavLocation extends FloatingActionButtonLocation {
  const FabAboveNavLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final offset = FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry);
    return Offset(offset.dx, offset.dy - AppSpacing.navHeight);
  }
}
