import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import 'share_access_screen.dart';

class ShareAcceptScreen extends ConsumerStatefulWidget {
  final String token;

  const ShareAcceptScreen({super.key, required this.token});

  @override
  ConsumerState<ShareAcceptScreen> createState() => _ShareAcceptScreenState();
}

class _ShareAcceptScreenState extends ConsumerState<ShareAcceptScreen> {
  bool _loading = true;
  bool _busy = false;
  Map<String, dynamic>? _preview;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await ref.read(shareRepositoryProvider).preview(widget.token);
      if (!mounted) return;
      setState(() {
        _preview = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppErrorHandler.message(e);
        _loading = false;
      });
    }
  }

  Future<void> _accept() async {
    final lang = ref.read(localeProvider);
    setState(() => _busy = true);
    try {
      await ref.read(shareRepositoryProvider).accept(widget.token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.t(lang, 'share_accepted')),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      context.go(RoutePaths.profileShare);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorHandler.message(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _busy = true);
    try {
      await ref.read(shareRepositoryProvider).decline(widget.token);
      if (!mounted) return;
      context.go(RoutePaths.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorHandler.message(e)),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Widget> _scopeRows(String Function(String) t) {
    final raw = (_preview?['scopes'] as List?) ?? const [];
    final scopes = raw.map((e) => e.toString()).toSet();
    final rows = <Widget>[];
    if (scopes.contains('nutrition')) {
      rows.add(_permRow(LucideIcons.utensils, t('share_scope_nutrition')));
    }
    if (scopes.contains('exercises')) {
      rows.add(_permRow(LucideIcons.dumbbell, t('share_scope_exercises')));
    }
    if (scopes.contains('health_sync')) {
      rows.add(_permRow(LucideIcons.heartPulse, t('share_scope_health_sync')));
    }
    if (scopes.contains('body_journal')) {
      rows.add(_permRow(LucideIcons.images, t('share_scope_body_journal')));
    }
    if (rows.isEmpty) {
      rows.add(_permRow(LucideIcons.eye, t('share_active_access')));
    }
    return rows;
  }

  Widget _permRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final viewerName = _preview?['viewer_name'] as String? ??
        _preview?['viewer_email'] as String? ??
        t('share_viewer');
    final status = _preview?['status'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('share_accept_title')),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        LucideIcons.shieldCheck,
                        size: 48,
                        color: AppColors.primaryDark,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t('share_accept_heading').replaceAll('{name}', viewerName),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t('share_accept_body'),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          t('share_accept_includes'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._scopeRows(t),
                      const Spacer(),
                      if (status == 'pending') ...[
                        FilledButton(
                          onPressed: _busy ? null : _accept,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(t('share_accept')),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _busy ? null : _decline,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(t('share_decline')),
                        ),
                      ] else
                        FilledButton(
                          onPressed: () => context.go(RoutePaths.profileShare),
                          child: Text(t('share_access_title')),
                        ),
                    ],
                  ),
                ),
    );
  }
}
