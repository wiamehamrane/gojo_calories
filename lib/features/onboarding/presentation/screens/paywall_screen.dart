import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gojocalories/core/theme/app_colors.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final bool _isLoading = false;

  void _handlePurchaseSuccess(CustomerInfo customerInfo, StoreTransaction storeTransaction) async {
    // Check for gojocalories Pro entitlement
    final entitlement = customerInfo.entitlements.all['gojocalories Pro'];
    if (entitlement != null && entitlement.isActive) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_onboarded', true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Purchase successful! Welcome to Pro.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    }
  }

  void _handleRestoreSuccess(CustomerInfo customerInfo) async {
    final entitlement = customerInfo.entitlements.all['gojocalories Pro'];
    if (entitlement != null && entitlement.isActive) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_onboarded', true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Purchase restored! Welcome back to Pro.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active subscriptions found to restore.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: _isLoading ? null : () => context.go('/onboarding/weight'),
        ),
      ),
      body: SafeArea(
        child: PaywallView(
          onPurchaseCompleted: _handlePurchaseSuccess,
          onRestoreCompleted: _handleRestoreSuccess,
        ),
      ),
    );
  }
}
