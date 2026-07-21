import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_message.dart';

enum _PostKind { image, video, beforeAfter }

class CreateCoachPostScreen extends ConsumerStatefulWidget {
  const CreateCoachPostScreen({super.key});

  @override
  ConsumerState<CreateCoachPostScreen> createState() =>
      _CreateCoachPostScreenState();
}

class _CreateCoachPostScreenState extends ConsumerState<CreateCoachPostScreen> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();
  _PostKind _kind = _PostKind.image;
  XFile? _primary;
  XFile? _after;
  File? _videoThumb;
  bool _saving = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickPrimary() async {
    HapticFeedback.selectionClick();
    if (_kind == _PostKind.video) {
      final file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (file == null || !mounted) return;
      setState(() {
        _primary = file;
        _videoThumb = null;
      });
      final thumb = await _generateVideoThumbnail(file.path);
      if (!mounted) return;
      setState(() => _videoThumb = thumb);
      return;
    }
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (file == null || !mounted) return;
    setState(() => _primary = file);
  }

  Future<File?> _generateVideoThumbnail(String videoPath) async {
    try {
      final path = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 80,
      );
      if (path == null) return null;
      return File(path);
    } catch (_) {
      // Thumbnail is a nice-to-have; the post still works without it.
      return null;
    }
  }

  Future<void> _pickAfter() async {
    HapticFeedback.selectionClick();
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (file == null || !mounted) return;
    setState(() => _after = file);
  }

  Future<void> _submit() async {
    final lang = ref.read(localeProvider);
    String t(String k) => Translations.t(lang, k);

    if (_primary == null) {
      AppMessage.error(context, t('coach_post_media_required'));
      return;
    }
    if (_kind == _PostKind.beforeAfter && _after == null) {
      AppMessage.error(context, t('coach_post_after_required'));
      return;
    }

    setState(() => _saving = true);
    try {
      final type = switch (_kind) {
        _PostKind.image => 'image',
        _PostKind.video => 'video',
        _PostKind.beforeAfter => 'before_after',
      };
      var thumb = _videoThumb;
      if (_kind == _PostKind.video && thumb == null) {
        thumb = await _generateVideoThumbnail(_primary!.path);
      }
      await ref.read(coachesRepositoryProvider).createPost(
            postType: type,
            media: File(_primary!.path),
            after: _after == null ? null : File(_after!.path),
            thumbnail: _kind == _PostKind.video ? thumb : null,
            caption: _captionController.text.trim(),
          );
      if (!mounted) return;
      AppMessage.success(context, t('coach_post_created'));
      context.pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppMessage.error(context, t('coach_post_create_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(t('coach_create_post')),
        actions: [
          TextButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t('coach_post_publish')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            t('coach_post_type'),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _KindChip(
                label: t('coach_post_type_image'),
                selected: _kind == _PostKind.image,
                onTap: () => setState(() {
                  _kind = _PostKind.image;
                  _after = null;
                  if (_primary != null &&
                      !(_primary!.mimeType?.startsWith('image/') ?? true)) {
                    _primary = null;
                  }
                }),
              ),
              _KindChip(
                label: t('coach_post_type_video'),
                selected: _kind == _PostKind.video,
                onTap: () => setState(() {
                  _kind = _PostKind.video;
                  _after = null;
                  _primary = null;
                }),
              ),
              _KindChip(
                label: t('coach_post_type_before_after'),
                selected: _kind == _PostKind.beforeAfter,
                onTap: () => setState(() {
                  _kind = _PostKind.beforeAfter;
                  if (_primary != null &&
                      !(_primary!.mimeType?.startsWith('image/') ?? true)) {
                    _primary = null;
                  }
                }),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_kind == _PostKind.beforeAfter) ...[
            Row(
              children: [
                Expanded(
                  child: _MediaPickerTile(
                    label: t('coach_post_before'),
                    path: _primary?.path,
                    isVideo: false,
                    onTap: _pickPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MediaPickerTile(
                    label: t('coach_post_after'),
                    path: _after?.path,
                    isVideo: false,
                    onTap: _pickAfter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              t('coach_post_before_after_hint'),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ] else
            _MediaPickerTile(
              label: _kind == _PostKind.video
                  ? t('coach_post_pick_video')
                  : t('coach_post_pick_image'),
              path: _primary?.path,
              isVideo: _kind == _PostKind.video,
              thumbPath: _videoThumb?.path,
              onTap: _pickPrimary,
              tall: true,
            ),
          const SizedBox(height: 18),
          TextField(
            controller: _captionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: t('coach_post_caption_hint'),
              filled: true,
              fillColor: AppColors.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _MediaPickerTile extends StatelessWidget {
  final String label;
  final String? path;
  final bool isVideo;
  final String? thumbPath;
  final VoidCallback onTap;
  final bool tall;

  const _MediaPickerTile({
    required this.label,
    required this.path,
    required this.isVideo,
    this.thumbPath,
    required this.onTap,
    this.tall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: tall ? 220 : 160,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: path == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isVideo ? LucideIcons.video : LucideIcons.imagePlus,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : isVideo
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      if (thumbPath != null)
                        Image.file(File(thumbPath!), fit: BoxFit.cover)
                      else
                        ColoredBox(color: AppColors.surface),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.play,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(blurRadius: 6, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Image.file(File(path!), fit: BoxFit.cover),
      ),
    );
  }
}
