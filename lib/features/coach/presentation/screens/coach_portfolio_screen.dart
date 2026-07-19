import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/coach.dart';
import '../widgets/coach_ui.dart';

class CoachPortfolioScreen extends ConsumerStatefulWidget {
  const CoachPortfolioScreen({super.key});

  @override
  ConsumerState<CoachPortfolioScreen> createState() =>
      _CoachPortfolioScreenState();
}

class _CoachPortfolioScreenState extends ConsumerState<CoachPortfolioScreen> {
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  List<CoachWork> _works = const [];

  File? _before;
  File? _after;
  final _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  String _t(String key) {
    return Translations.t(ref.read(localeProvider), key);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(coachesRepositoryProvider).listMyWorks();
      if (!mounted) return;
      setState(() {
        _works = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _t('coach_portfolio_load_failed');
      });
    }
  }

  Future<void> _pickSlot({required bool isBefore}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() {
      if (isBefore) {
        _before = File(picked.path);
      } else {
        _after = File(picked.path);
      }
    });
  }

  Future<void> _upload() async {
    if (_before == null || _after == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('coach_portfolio_need_both'))),
      );
      return;
    }
    if (_works.length >= 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('coach_portfolio_max'))),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      final created = await ref.read(coachesRepositoryProvider).createWork(
            before: _before!,
            after: _after!,
            caption: _captionController.text,
          );
      if (!mounted) return;
      setState(() {
        _works = [created, ..._works];
        _before = null;
        _after = null;
        _captionController.clear();
        _uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('coach_portfolio_added'))),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      final detail = e.response?.data;
      final message = detail is Map && detail['detail'] != null
          ? detail['detail'].toString()
          : _t('coach_portfolio_upload_failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('coach_portfolio_upload_failed'))),
      );
    }
  }

  Future<void> _delete(CoachWork work) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('coach_portfolio_delete_title')),
        content: Text(_t('coach_portfolio_delete_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('become_coach_back')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_t('coach_portfolio_delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(coachesRepositoryProvider).deleteWork(work.id);
      if (!mounted) return;
      setState(() {
        _works = _works.where((w) => w.id != work.id).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('coach_portfolio_delete_failed'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _t('coach_portfolio_title'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                    const SizedBox(height: 12),
                  ],
                  CoachSectionCard(
                    title: _t('coach_portfolio_add'),
                    icon: LucideIcons.plus,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _t('coach_portfolio_add_hint'),
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _ImageSlot(
                                label: _t('coach_portfolio_before'),
                                file: _before,
                                onTap: () => _pickSlot(isBefore: true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ImageSlot(
                                label: _t('coach_portfolio_after'),
                                file: _after,
                                onTap: () => _pickSlot(isBefore: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _captionController,
                          decoration: InputDecoration(
                            hintText: _t('coach_portfolio_caption_hint'),
                            filled: true,
                            fillColor: AppColors.surfaceMuted,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _uploading ? null : _upload,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _uploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_t('coach_portfolio_upload')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _t('coach_portfolio_list'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_works.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        _t('coach_portfolio_empty'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    )
                  else
                    ..._works.asMap().entries.map((entry) {
                      final i = entry.key;
                      final work = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _WorkCard(
                          work: work,
                          beforeLabel: _t('coach_portfolio_before'),
                          afterLabel: _t('coach_portfolio_after'),
                          onDelete: () => _delete(work),
                        )
                            .animate()
                            .fadeIn(delay: (40 * i).ms, duration: 280.ms)
                            .slideY(begin: 0.04, curve: Curves.easeOutCubic),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _ImageSlot extends StatelessWidget {
  final String label;
  final File? file;
  final VoidCallback onTap;

  const _ImageSlot({
    required this.label,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CoachPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
            image: file != null
                ? DecorationImage(
                    image: FileImage(file!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.imagePlus,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                )
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _WorkCard extends StatelessWidget {
  final CoachWork work;
  final String beforeLabel;
  final String afterLabel;
  final VoidCallback onDelete;

  const _WorkCard({
    required this.work,
    required this.beforeLabel,
    required this.afterLabel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CoachSectionCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _RemoteLabeledImage(
                  url: work.beforeUrl,
                  label: beforeLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RemoteLabeledImage(
                  url: work.afterUrl,
                  label: afterLabel,
                ),
              ),
            ],
          ),
          if (work.caption != null && work.caption!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              work.caption!,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onDelete,
              icon: const Icon(LucideIcons.trash2, size: 18),
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoteLabeledImage extends StatelessWidget {
  final String url;
  final String label;

  const _RemoteLabeledImage({
    required this.url,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url.isNotEmpty)
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surfaceMuted,
                  child: const Icon(LucideIcons.imageOff),
                ),
              )
            else
              Container(color: AppColors.surfaceMuted),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5),
                color: Colors.black.withValues(alpha: 0.45),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
