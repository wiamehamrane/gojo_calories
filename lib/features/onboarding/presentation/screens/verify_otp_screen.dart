import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class VerifyOTPScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyOTPScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyOTPScreen> createState() => _VerifyOTPScreenState();
}

class _VerifyOTPScreenState extends ConsumerState<VerifyOTPScreen> {
  final _otpCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = "Please enter a 6-digit code.");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.instance.post('auth/verify-otp', data: {
        'email': widget.email,
        'otp': otp,
      });

      if (res.statusCode == 200) {
        if (!mounted) return;
        // Proceed to weight setup
        context.go('/onboarding/weight');
      } else {
        setState(() => _error = "Invalid or expired code.");
      }
    } catch (e) {
      setState(() => _error = "Invalid or expired code.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ApiClient.instance.post('auth/resend-verification');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Code resent successfully!"),
          backgroundColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to resend code."),
          backgroundColor: AppColors.danger,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
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
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.go('/auth'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify your email',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
              
              const SizedBox(height: 12),
              
              Text.rich(
                TextSpan(
                  text: 'We sent a 6-digit code to ',
                  style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
                  children: [
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),
              
              const SizedBox(height: 40),
              
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                  counterText: "",
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
                onChanged: (v) {
                  if (v.length == 6) _verify();
                },
              ).animate().fadeIn(delay: 200.ms),
              
              if (_error != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 14)),
                ),
              ],
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text("Verify", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ).animate().fadeIn(delay: 300.ms),
              
              const SizedBox(height: 24),
              
              Center(
                child: TextButton(
                  onPressed: () => context.go('/onboarding/weight'),
                  child: const Text(
                    "Skip for now →",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ).animate().fadeIn(delay: 450.ms),
              
              const SizedBox(height: 12),
              
              Center(
                child: GestureDetector(
                  onTap: _resend,
                  child: const Text(
                    "Didn't receive a code? Resend",
                    style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
