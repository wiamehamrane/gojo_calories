import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FixResultsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> log;
  const FixResultsScreen({super.key, required this.log});

  @override
  ConsumerState<FixResultsScreen> createState() => _FixResultsScreenState();
}

class _FixResultsScreenState extends ConsumerState<FixResultsScreen> {
  final _promptController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _submitFix() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.instance.post(
        'food/analyze/fix',
        data: {
          'log_id': widget.log['log_id'] ?? widget.log['id'].toString(),
          'prompt': prompt,
        },
      );
      
      if (mounted) {
        context.pop(res.data); // Return the updated log data
      }
    } catch (e) {
      setState(() {
        _error = "Failed to fix results. Please try again.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final logId = widget.log['log_id'] ?? widget.log['id']?.toString();
    if (logId == null) {
      return const Scaffold(
        body: Center(child: Text("Cannot fix an unsaved log.")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Fix Results',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "What's wrong with this entry?",
                style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Tell us what needs to be changed (e.g. 'I had 2 eggs instead of 1' or 'Remove the cheese').",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _promptController,
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "e.g., 'Change the amount of chicken to 200g'",
                  hintStyle: const TextStyle(color: AppColors.inactive),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 14)),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitFix,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          "Update Log",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
