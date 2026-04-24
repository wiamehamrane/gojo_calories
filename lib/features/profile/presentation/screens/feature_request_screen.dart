import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class FeatureRequestScreen extends StatefulWidget {
  const FeatureRequestScreen({super.key});

  @override
  State<FeatureRequestScreen> createState() => _FeatureRequestScreenState();
}

class _FeatureRequestScreenState extends State<FeatureRequestScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitFeature() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);
    
    // For now, we'll open the support email with the feature request text
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'support@gojocalories.com',
      queryParameters: {
        'subject': 'Feature Request - GojoCalories',
        'body': text,
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening your email client...')),
          );
          context.pop();
        }
      } else {
        throw 'Could not launch $emailUri';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Feature Request',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'What feature would you like to see next?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'We are constantly improving GojoCalories. Share your ideas and help us build the best nutrition tracker!',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Describe your idea here...',
                  hintStyle: const TextStyle(color: AppColors.textPlaceholder),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                ),
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitFeature,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Send Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
