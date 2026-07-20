import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/models/progress_photo.dart';
import '../providers/progress_photos_provider.dart';
import '../widgets/progress_glass.dart';

/// Guided Front → Left → Right → Back capture.
///
/// Each shot is copied into app documents storage immediately (so iOS temp
/// camera files can't vanish), then uploaded to the API right away so photos
/// are durable in the database before the user finishes the flow.
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
  final Set<BodyPose> _uploaded = {};
  int _index = 0;
  bool _busy = false;
  String? _error;
  int _celebrateTick = 0;

  @override
  void initState() {
    super.initState();
    _poses = widget.poses.isEmpty ? kRequiredPoses : widget.poses;
  }

  BodyPose get _current => _poses[_index];
  bool get _isLast => _index == _poses.length - 1;
  int get _capturedCount => _captured.length;

  Future<File> _persistLocally(XFile picked, BodyPose pose) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/progress_captures');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final dest = File(
      '${folder.path}/${pose.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    return File(picked.path).copy(dest.path);
  }

  Future<void> _openCamera() async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() => _error = null);

    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 2000,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final durable = await _persistLocally(picked, _current);
      if (!mounted) return;
      setState(() {
        _captured[_current] = durable;
        _celebrateTick++;
      });

      // Upload immediately so the photo is in the DB even if the user leaves.
      final uploaded = await ref.read(progressPhotosProvider.notifier).uploadPhoto(
            durable,
            pose: _current,
            photoDate: DateTime.now(),
          );
      if (!mounted) return;
      if (uploaded == null) {
        setState(() {
          _error = 'Couldn\'t save ${_current.label}. Check your connection and retry.';
          _busy = false;
        });
        return;
      }
      setState(() {
        _uploaded.add(_current);
        _busy = false;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Couldn\'t save this photo. Please try again.';
      });
    }
  }

  void _retake() {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() {
      _captured.remove(_current);
      _uploaded.remove(_current);
      _error = null;
    });
  }

  Future<void> _next() async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    if (!_uploaded.contains(_current)) {
      // Shot on device but upload failed earlier — retry once.
      final file = _captured[_current];
      if (file == null) return;
      setState(() {
        _busy = true;
        _error = null;
      });
      final uploaded =
          await ref.read(progressPhotosProvider.notifier).uploadPhoto(
                file,
                pose: _current,
                photoDate: DateTime.now(),
              );
      if (!mounted) return;
      if (uploaded == null) {
        setState(() {
          _busy = false;
          _error = 'Upload failed. Tap Next to retry.';
        });
        return;
      }
      setState(() {
        _uploaded.add(_current);
        _busy = false;
      });
    }

    if (_isLast) {
      await _finish();
    } else {
      setState(() => _index += 1);
    }
  }

  Future<void> _finish() async {
    // Ensure every captured pose is on the server.
    setState(() {
      _busy = true;
      _error = null;
    });
    final notifier = ref.read(progressPhotosProvider.notifier);
    var allOk = true;
    for (final entry in _captured.entries) {
      if (_uploaded.contains(entry.key)) continue;
      final ok = await notifier.uploadPhoto(
        entry.value,
        pose: entry.key,
        photoDate: DateTime.now(),
      );
      if (ok == null) {
        allOk = false;
      } else {
        _uploaded.add(entry.key);
      }
    }
    await notifier.fetchPhotos();
    if (!mounted) return;
    setState(() => _busy = false);

    if (allOk && _uploaded.length == _poses.length) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } else if (_uploaded.isNotEmpty) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Photos couldn\'t be saved. Please try again.');
    }
  }

  void _back() {
    if (_index == 0 || _busy) return;
    HapticFeedback.selectionClick();
    setState(() => _index -= 1);
  }

  Future<void> _confirmClose() async {
    if (_busy) return;
    if (_capturedCount == 0) {
      Navigator.of(context).pop(_uploaded.isNotEmpty);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title:
            Text('Leave capture?', style: display(size: 19, weight: FontWeight.w700)),
        content: Text(
          _uploaded.isEmpty
              ? 'You haven\'t saved any shots yet.'
              : '${_uploaded.length} of ${_poses.length} shots are already saved. You can finish the rest later.',
          style: TextStyle(color: kInkSoft, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep going', style: TextStyle(color: kInkSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: kDanger)),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      Navigator.of(context).pop(_uploaded.isNotEmpty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasShot = _captured.containsKey(_current);
    final saved = _uploaded.contains(_current);

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
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kDanger,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn().shake(hz: 2, duration: 320.ms),
              const SizedBox(height: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey('${_current.id}_$hasShot'),
                      child: hasShot ? _preview(saved: saved) : _guide(),
                    ),
                  ),
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
            onPressed: _busy ? null : _confirmClose,
            icon: Icon(LucideIcons.x, color: kInk),
          ),
          Expanded(
            child: Column(
              children: [
                Eyebrow('Step ${_index + 1} of ${_poses.length}'),
                const SizedBox(height: 3),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    _current.label,
                    key: ValueKey(_current.id),
                    style: display(size: 19, weight: FontWeight.w700),
                  ),
                ),
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
        final done = _uploaded.contains(_poses[i]);
        final active = i == _index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
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
                )
                    .animate()
                    .fadeIn(duration: 360.ms)
                    .scale(
                      begin: const Offset(0.96, 0.96),
                      curve: Curves.easeOutCubic,
                    ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
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
                            style: TextStyle(
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
            style: TextStyle(color: kInk, fontSize: 15.5, height: 1.45)),
        const SizedBox(height: 8),
        Text('Same spot, same distance, same light each day.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 12.5)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _preview({required bool saved}) {
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
                    key: ValueKey('badge_$_celebrateTick'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          saved ? LucideIcons.circleCheck : LucideIcons.check,
                          size: 14,
                          color: kAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          saved
                              ? '${_current.label} saved'
                              : '${_current.label} captured',
                          style: TextStyle(
                              color: kInk,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 200.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        curve: Curves.easeOutBack,
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
      child: _busy
          ? SizedBox(
              height: 54,
              child: Center(
                child: CircularProgressIndicator(
                    color: kAccent, strokeWidth: 2.4),
              ),
            )
          : !hasShot
              ? ProgressPressable(
                  onTap: _openCamera,
                  child: _primaryButton(
                    icon: LucideIcons.camera,
                    label: 'Open camera',
                  ),
                )
              : Row(
                  children: [
                    if (_index > 0)
                      ProgressPressable(
                        onTap: _back,
                        child: _iconButton(LucideIcons.chevronLeft),
                      ),
                    Expanded(
                      child: ProgressPressable(
                        onTap: _retake,
                        child: Container(
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kHair),
                            color: kSurface,
                          ),
                          child: Text('Retake',
                              style: TextStyle(
                                  color: kInk, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ProgressPressable(
                        onTap: _next,
                        child: _primaryButton(
                          icon: _isLast
                              ? LucideIcons.check
                              : LucideIcons.arrowRight,
                          label: _isLast ? 'Done' : 'Next',
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _primaryButton({required IconData icon, required String label}) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: kInk,
        borderRadius: BorderRadius.circular(14),
      ),
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
    );
  }

  Widget _iconButton(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kHair),
        ),
        child: Icon(icon, color: kInk, size: 20),
      ),
    );
  }
}
