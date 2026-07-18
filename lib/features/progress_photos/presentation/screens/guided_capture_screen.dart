import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../domain/models/progress_photo.dart';
import '../providers/progress_photos_provider.dart';
import '../widgets/progress_glass.dart';

/// Guided Front → Left → Right → Back capture flow, light editorial styling.
///
/// Steps through the poses that still need to be taken today. For each pose it
/// shows a silhouette guide + instruction, opens the camera, then lets the user
/// preview / retake before moving on. All shots upload together at the end.
class GuidedCaptureScreen extends ConsumerStatefulWidget {
  final List<BodyPose> poses;

  const GuidedCaptureScreen({super.key, this.poses = kRequiredPoses});

  @override
  ConsumerState<GuidedCaptureScreen> createState() =>
      _GuidedCaptureScreenState();
}

class _GuidedCaptureScreenState extends ConsumerState<GuidedCaptureScreen> {
  late final List<BodyPose> _poses;
  final Map<BodyPose, File> _captured = {};
  int _index = 0;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _poses = widget.poses.isEmpty ? kRequiredPoses : widget.poses;
  }

  BodyPose get _current => _poses[_index];
  bool get _isLast => _index == _poses.length - 1;
  int get _capturedCount => _captured.length;

  Future<void> _openCamera() async {
    HapticFeedback.selectionClick();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 2000,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked == null || !mounted) return;
    setState(() => _captured[_current] = File(picked.path));
  }

  void _retake() {
    HapticFeedback.selectionClick();
    setState(() => _captured.remove(_current));
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_isLast) {
      _uploadAll();
    } else {
      setState(() => _index += 1);
    }
  }

  void _back() {
    if (_index == 0) return;
    HapticFeedback.selectionClick();
    setState(() => _index -= 1);
  }

  Future<void> _uploadAll() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    final now = DateTime.now();
    final notifier = ref.read(progressPhotosProvider.notifier);

    var allOk = true;
    for (final entry in _captured.entries) {
      final ok = await notifier.uploadPhoto(
        entry.value,
        pose: entry.key,
        photoDate: now,
      );
      if (!ok) allOk = false;
    }
    if (!mounted) return;
    setState(() => _uploading = false);

    if (allOk) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Some photos failed to upload. Tap Finish to retry.'),
          backgroundColor: kDanger,
        ),
      );
    }
  }

  Future<void> _confirmClose() async {
    if (_capturedCount == 0) {
      Navigator.of(context).pop(false);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Discard photos?', style: serif(size: 19, weight: FontWeight.w600)),
        content: Text(
          'You\'ve taken $_capturedCount of ${_poses.length} shots. Leaving now discards them.',
          style: const TextStyle(color: kInkSoft, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep going', style: TextStyle(color: kInkSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard', style: TextStyle(color: kDanger)),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final hasShot = _captured.containsKey(_current);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmClose();
      },
      child: Scaffold(
        backgroundColor: kPaper,
        body: SafeArea(
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 6),
              _stepDots(),
              const SizedBox(height: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: hasShot ? _preview() : _guide(),
                ),
              ),
              _bottomBar(hasShot),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _uploading ? null : _confirmClose,
            icon: const Icon(LucideIcons.x, color: kInk),
          ),
          Expanded(
            child: Column(
              children: [
                Eyebrow('Step ${_index + 1} of ${_poses.length}'),
                const SizedBox(height: 3),
                Text(_current.label,
                    style: serif(size: 19, weight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _stepDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_poses.length, (i) {
        final done = _captured.containsKey(_poses[i]);
        final active = i == _index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: done
                ? kAccent
                : active
                    ? kInk
                    : kHair,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }

  Widget _guide() {
    return Column(
      children: [
        Expanded(
          child: EditorialCard(
            padding: EdgeInsets.zero,
            radius: 24,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: CustomPaint(
                      painter: PoseSilhouettePainter(_current),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: kAccentSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_current.icon, size: 14, color: kAccent),
                        const SizedBox(width: 6),
                        Text(_current.label,
                            style: const TextStyle(
                                color: kAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(_current.instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kInk, fontSize: 15.5, height: 1.45)),
        const SizedBox(height: 8),
        const Text('Same spot, same distance, same light each day.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 12.5)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _preview() {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(_captured[_current]!, fit: BoxFit.cover),
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.check, size: 14, color: kAccent),
                        const SizedBox(width: 6),
                        Text('${_current.label} captured',
                            style: const TextStyle(
                                color: kInk,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _bottomBar(bool hasShot) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: _uploading
          ? const SizedBox(
              height: 54,
              child: Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2.4)),
            )
          : !hasShot
              ? _primaryButton(
                  icon: LucideIcons.camera, label: 'Open camera', onTap: _openCamera)
              : Row(
                  children: [
                    if (_index > 0) _iconButton(LucideIcons.chevronLeft, _back),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _retake,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kHair),
                          foregroundColor: kInk,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Retake'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _primaryButton(
                        icon: _isLast ? LucideIcons.check : LucideIcons.arrowRight,
                        label: _isLast ? 'Finish' : 'Next',
                        onTap: _next,
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: kInk,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kHair),
            ),
            child: Icon(icon, color: kInk, size: 20),
          ),
        ),
      ),
    );
  }
}
