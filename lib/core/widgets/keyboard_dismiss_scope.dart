import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Tap outside fields to dismiss the keyboard, plus an iOS-style "Done" bar
/// that sits above the software keyboard when a field is focused.
class KeyboardDismissScope extends StatelessWidget {
  final Widget child;
  final String doneLabel;

  const KeyboardDismissScope({
    super.key,
    required this.child,
    this.doneLabel = 'Done',
  });

  void _dismiss(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _dismiss(context),
      child: Column(
        children: [
          Expanded(child: child),
          if (keyboardOpen)
            Material(
              color: AppColors.surface,
              elevation: 6,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 44,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _dismiss(context),
                        child: Text(
                          doneLabel,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
