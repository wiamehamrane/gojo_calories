import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:dio/dio.dart' show DioException, DioExceptionType;
import '../providers/food_providers.dart';
import '../../../stats/presentation/providers/dashboard_provider.dart';
import '../../../stats/presentation/providers/history_provider.dart';
import '../../../stats/presentation/providers/weekly_stats_provider.dart';
import '../../../../features/stats/presentation/providers/selected_date_provider.dart';
import 'package:go_router/go_router.dart';
import 'food_detail_screen.dart';

class ScanFoodScreen extends ConsumerStatefulWidget {
  final String initialMode;
  const ScanFoodScreen({super.key, this.initialMode = 'Scan Food'});

  @override
  ConsumerState<ScanFoodScreen> createState() => _ScanFoodScreenState();
}

class _ScanFoodScreenState extends ConsumerState<ScanFoodScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _showSuccess = false;
  bool _barcodeScanned = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late String _currentMode;
  String? _cameraError;
  String? _pickedImagePath;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraError = 'No camera found on this device.';
            _isInitializing = false;
          });
        }
        return;
      }
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = _friendlyCameraError(e.code);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Could not start the camera. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  String _friendlyCameraError(String code) {
    switch (code) {
      case 'CameraAccessDenied':
        return 'Camera access denied. Please enable camera permission in your device settings.';
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Camera permission is needed. Go to Settings → Apps → GojoCalories → Permissions.';
      default:
        return 'Camera unavailable. Make sure no other app is using the camera.';
    }
  }

  String _friendlyNetworkError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Request timed out. Check your internet connection and try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please connect to Wi-Fi or mobile data.';
        case DioExceptionType.badResponse:
          final code = e.response?.statusCode ?? 0;
          if (code == 404) {
            return 'Product not found. Try using the camera to analyze the food.';
          }
          if (code == 401 || code == 403) {
            return 'Session expired. Please log out and log back in.';
          }
          if (code >= 500) {
            return 'Our server is having trouble right now. Please try again in a moment.';
          }
          return 'Unexpected server response ($code). Please try again.';
        default:
          return 'Network error. Please check your connection and try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  /// Returns the user's current local date as "YYYY-MM-DD"
  String get _localDateStr {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// Navigate to home with a smooth fade+slide transition after success.
  Future<void> _redirectToHome() async {
    if (mounted) setState(() => _showSuccess = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    ref.invalidate(historyProvider);
    context.go('/home');
  }

  Future<void> _analyzeFile(String path, String name) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final data = await ref.read(foodScanProvider.notifier).analyzeImage(
            File(path),
            _localDateStr,
          );
      if (data != null) {
        final calories = int.tryParse(data['calories']?.toString() ?? '0') ?? 0;
        final protein = int.tryParse(data['protein']?.toString() ?? '0') ?? 0;
        final carbs = int.tryParse(data['carbs']?.toString() ?? '0') ?? 0;
        final fat = int.tryParse(data['fat']?.toString() ?? '0') ?? 0;
        final mealName = data['name_en']?.toString() ?? data['name']?.toString() ?? 'Analyzed Food';

        // NOTE: The backend /food/analyze already saves the FoodLog + image to S3 + updates DailyStats.
        // We only need to update local in-memory state here — no second POST needed.
        // Prepare data for the detail screen
        final logData = Map<String, dynamic>.from(data);
        // Ensure image_url is present, fallback to local path if needed
        logData['image_url'] = data['image_url'] ?? path;
        logData['created_at'] = data['created_at'] ?? DateTime.now().toIso8601String();

        ref
            .read(dashboardProvider.notifier)
            .logFood(
              calories: calories,
              protein: protein,
              carbs: carbs,
              fat: fat,
              name: mealName,
              nameEn: data['name_en']?.toString(),
              nameFr: data['name_fr']?.toString(),
              nameAr: data['name_ar']?.toString(),
              imageUrl: logData['image_url']?.toString(),
              ingredients: data['ingredients'] as List<dynamic>?,
            );
            
        final selectedDate = ref.read(selectedDateProvider);
        ref.invalidate(historyProvider(selectedDate));
        ref.invalidate(weeklyStatsProvider);
        ref.invalidate(dashboardProvider);

        if (!mounted) return;
        
        // Navigate to details screen instead of home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FoodDetailScreen(log: logData),
          ),
        );
      } else {
        _showError('Analysis failed. Please try again with a clearer photo.');
      }
    } catch (e) {
      if (mounted) _showError(_friendlyNetworkError(e));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _lookupBarcode(String barcode) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _barcodeScanned = true;
    });
    try {
      final data = await ref.read(foodScanProvider.notifier).lookupBarcode(barcode);

      if (data != null) {
        final productName = data['name'] as String? ?? 'Scanned Product';
        final calories = int.tryParse(data['calories']?.toString() ?? '0') ?? 0;
        final protein = int.tryParse(data['protein']?.toString() ?? '0') ?? 0;
        final carbs = int.tryParse(data['carbs']?.toString() ?? '0') ?? 0;
        final fat = int.tryParse(data['fat']?.toString() ?? '0') ?? 0;

        if (!mounted) return;

        final imageUrl = data['image_url'] as String?;
        try {
          await ref.read(foodScanProvider.notifier).logBarcodeItem({
              'name': productName,
              'name_en': data['name_en'] ?? productName,
              'name_fr': data['name_fr'],
              'name_ar': data['name_ar'],
              'calories': calories,
              'protein': protein,
              'carbs': carbs,
              'fat': fat,
              'image_url': imageUrl,
              'ingredients': data['ingredients'],
            }, localDate: _localDateStr);
        } catch (e) {
          debugPrint('Barcode post to backend failed: $e');
          /* non-fatal — local state already updated */
        }

        ref
            .read(dashboardProvider.notifier)
            .logFood(
              calories: calories,
              protein: protein,
              carbs: carbs,
              fat: fat,
              name: productName,
              nameEn: data['name_en']?.toString(),
              nameFr: data['name_fr']?.toString(),
              nameAr: data['name_ar']?.toString(),
              imageUrl: imageUrl,
              ingredients: data['ingredients'] as List<dynamic>?,
            );

        await _redirectToHome();
      } else {
        _showError(
          'Product not found. Try using the camera to analyze the food.',
        );
        setState(() {
          _isProcessing = false;
          _barcodeScanned = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError(_friendlyNetworkError(e));
        setState(() {
          _isProcessing = false;
          _barcodeScanned = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              LucideIcons.triangleAlert,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }
    try {
      final photo = await _controller!.takePicture();
      if (!mounted) return;
      setState(() => _pickedImagePath = photo.path);
      await _analyzeFile(photo.path, photo.name);
    } on CameraException catch (e) {
      _showError(_friendlyCameraError(e.code));
    } catch (e) {
      _showError('Could not capture photo. Please try again.');
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    try {
      final img = await picker.pickImage(source: ImageSource.gallery);
      if (img == null) return;
      if (!mounted) return;
      setState(() => _pickedImagePath = img.path);
      if (_currentMode == 'Barcode') {
        // For barcode mode, treat the image as a vision scan to detect the barcode
        await _analyzeFile(img.path, img.name);
      } else {
        await _analyzeFile(img.path, img.name);
      }
    } catch (e) {
      _showError('Could not access your gallery. Please check permissions.');
    }
  }

  /// Builds a properly-sized camera preview that prevents stretching/distortion.
  Widget _buildCameraPreview() {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize!.height,
          height: _controller!.value.previewSize!.width,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_cameraError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                LucideIcons.cameraOff,
                color: Colors.white54,
                size: 64,
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _cameraError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                label: const Text(
                  'Go Back',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // ─── Background layer ───────────────────────────────────────────
          Positioned.fill(
            child: _pickedImagePath != null
                ? Image.file(File(_pickedImagePath!), fit: BoxFit.cover)
                : _currentMode == 'Scan Food'
                    ? (_controller != null && _controller!.value.isInitialized
                          ? _buildCameraPreview()
                          : const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryDark,
                              ),
                            ))
                    : MobileScanner(
                        onDetect: (capture) {
                      if (!mounted || _barcodeScanned || _isProcessing) return;
                      final barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty &&
                          barcodes.first.rawValue != null) {
                        _lookupBarcode(barcodes.first.rawValue!);
                      }
                    },
                  ),
          ),

          // ─── Success flash overlay ──────────────────────────────────────
          if (_showSuccess)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _showSuccess ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  child: const Center(
                    child: Icon(
                      LucideIcons.circleCheck,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                ),
              ),
            ),

          // ─── Processing overlay ─────────────────────────────────────────
          if (_isProcessing && !_showSuccess)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 20),
                      Text(
                        'Analyzing…',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ─── Top bar: close (left) + upload icon (right) ────────────────
          Positioned(
            top: safeTop > 0 ? safeTop + 10 : 30,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: const _CameraRoundButton(icon: LucideIcons.x),
                ),
                // Upload icon — opens gallery for the current mode
                GestureDetector(
                  onTap: _isProcessing ? null : _pickFromGallery,
                  child: const _CameraRoundButton(icon: LucideIcons.imagePlus),
                ),
              ],
            ),
          ),

          // ─── Scan frame ─────────────────────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value,
                  child: CustomPaint(
                    size: const Size(240, 240),
                    painter: _ScanCornersPainter(
                      color: Colors.white,
                      strokeWidth: 3,
                      cornerLength: 28,
                      cornerRadius: 6,
                    ),
                  ),
                );
              },
            ),
          ),

          // ─── Barcode hint label ─────────────────────────────────────────
          if (_currentMode == 'Barcode' && !_isProcessing)
            Positioned(
              top: safeTop + 80,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  'Point at a product barcode',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // ─── Bottom controls ────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: safeBottom > 0 ? safeBottom + 16 : 24,
                top: 16,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mode pills — only two modes now
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildModeCard(LucideIcons.scanLine, 'Scan Food'),
                      const SizedBox(width: 10),
                      _buildModeCard(LucideIcons.barcode, 'Barcode'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Shutter button — only for Vision mode
                  if (_currentMode == 'Scan Food')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 44),
                        const SizedBox(width: 48),
                        GestureDetector(
                          onTap: _isProcessing ? null : _takePicture,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              color: Colors.transparent,
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isProcessing
                                      ? Colors.white.withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.9),
                                ),
                                child: const Center(
                                  child: Icon(
                                    LucideIcons.camera,
                                    size: 26,
                                    color: Color(0xFF0A0A0A),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                        const SizedBox(width: 44),
                      ],
                    )
                  else
                    const SizedBox(height: 76),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(IconData icon, String modeString) {
    final isActive = _currentMode == modeString;
    return GestureDetector(
      onTap: _isProcessing
          ? null
          : () {
              setState(() {
                _currentMode = modeString;
                _barcodeScanned = false;
                _pickedImagePath = null;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? const Color(0xFF0A0A0A) : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              modeString,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF0A0A0A) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraRoundButton extends StatelessWidget {
  final IconData icon;
  const _CameraRoundButton({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.85),
      ),
      child: Center(child: Icon(icon, size: 20, color: AppColors.textPrimary)),
    );
  }
}

class _ScanCornersPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double cornerRadius;

  _ScanCornersPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height, l = cornerLength, r = cornerRadius;
    canvas.drawPath(
      Path()
        ..moveTo(0, l)
        ..lineTo(0, r)
        ..arcTo(Rect.fromLTWH(0, 0, r * 2, r * 2), pi, pi / 2, false)
        ..lineTo(l, 0),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w - l, 0)
        ..lineTo(w - r, 0)
        ..arcTo(
          Rect.fromLTWH(w - (r * 2), 0, r * 2, r * 2),
          -pi / 2,
          pi / 2,
          false,
        )
        ..lineTo(w, l),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h - l)
        ..lineTo(0, h - r)
        ..arcTo(Rect.fromLTWH(0, h - (r * 2), r * 2, r * 2), pi, -pi / 2, false)
        ..lineTo(l, h),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w - l, h)
        ..lineTo(w - r, h)
        ..arcTo(
          Rect.fromLTWH(w - (r * 2), h - (r * 2), r * 2, r * 2),
          pi / 2,
          -pi / 2,
          false,
        )
        ..lineTo(w, h - l),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
