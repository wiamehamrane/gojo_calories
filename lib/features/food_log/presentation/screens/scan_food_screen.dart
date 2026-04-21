import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../../../dashboard/providers/history_provider.dart';
import 'package:go_router/go_router.dart';

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
        ResolutionPreset.medium,
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

  /// Navigate to home with a smooth fade+slide transition after success.
  Future<void> _redirectToHome() async {
    // Flash success state briefly so the user gets feedback on this screen.
    if (mounted) setState(() => _showSuccess = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    // Invalidate history so the new item shows up immediately.
    ref.invalidate(historyProvider);
    context.go('/home');
  }

  Future<void> _analyzeFile(String path, String name) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: name),
      });

      final res = await ApiClient.instance.post('food/analyze', data: formData);

      if (res.statusCode == 200 && res.data != null) {
        if (!mounted) return;
        final data = res.data as Map<String, dynamic>;
        ref.read(dashboardProvider.notifier).logFood(
              calories: int.tryParse(data['calories']?.toString() ?? '0') ?? 0,
              protein: int.tryParse(data['protein']?.toString() ?? '0') ?? 0,
              carbs: int.tryParse(data['carbs']?.toString() ?? '0') ?? 0,
              fat: int.tryParse(data['fat']?.toString() ?? '0') ?? 0,
              name: data['name']?.toString() ?? 'Analyzed Food',
            );
        await _redirectToHome();
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
      final dio = Dio();
      final res = await dio
          .get(
            'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
            options: Options(receiveTimeout: const Duration(seconds: 10)),
          )
          .timeout(const Duration(seconds: 12));

      final productData = res.data;
      if (productData == null ||
          productData['status'] == 0 ||
          productData['product'] == null) {
        _showError(
            'Product not found in our database. Try scanning a different barcode or use the camera to analyze the food.');
        setState(() {
          _isProcessing = false;
          _barcodeScanned = false;
        });
        return;
      }

      final product = productData['product'] as Map<String, dynamic>;
      final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

      // Prefer 100g values; fallback to per-serving
      double getNum(String key) {
        final val = nutriments[key] ?? nutriments['${key}_100g'] ?? 0;
        return (val is num) ? val.toDouble() : double.tryParse(val.toString()) ?? 0.0;
      }

      final productName =
          (product['product_name'] as String? ?? '').isNotEmpty
              ? product['product_name'] as String
              : 'Scanned Product';

      final calories = getNum('energy-kcal').round();
      final protein = getNum('proteins').round();
      final carbs = getNum('carbohydrates').round();
      final fat = getNum('fat').round();

      if (!mounted) return;
      ref.read(dashboardProvider.notifier).logFood(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            name: productName,
          );

      await _redirectToHome();
    } on DioException catch (e) {
      if (mounted) {
        _showError(_friendlyNetworkError(e));
        setState(() {
          _isProcessing = false;
          _barcodeScanned = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Could not look up this barcode. Please try again.');
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
            const Icon(LucideIcons.triangleAlert, color: Colors.white, size: 18),
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
      await _analyzeFile(img.path, img.name);
    } catch (e) {
      _showError('Could not access your gallery. Please check permissions.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Full-screen loading / init
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Camera error — show full screen friendly message
    if (_cameraError != null &&
        (_currentMode == 'Scan Food' || _currentMode == 'Food label')) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.cameraOff, color: Colors.white54, size: 64),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _cameraError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                ),
              ),
              const SizedBox(height: 32),
              TextButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                label: const Text('Go Back', style: TextStyle(color: Colors.white)),
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
            child: _currentMode == 'Scan Food' || _currentMode == 'Food label'
                ? (_controller != null && _controller!.value.isInitialized
                    ? CameraPreview(_controller!)
                    : const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primaryDark),
                      ))
                : (_currentMode == 'Barcode'
                    ? MobileScanner(
                        onDetect: (capture) {
                          if (!mounted || _barcodeScanned || _isProcessing) return;
                          final barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty &&
                              barcodes.first.rawValue != null) {
                            _lookupBarcode(barcodes.first.rawValue!);
                          }
                        },
                      )
                    : const Center(
                        child: Text('Gallery Selected',
                            style: TextStyle(color: Colors.white)))),
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
                    child: Icon(LucideIcons.circleCheck,
                        color: Colors.white, size: 80),
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
                        style: TextStyle(color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ─── Top buttons ────────────────────────────────────────────────
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
                const _CameraRoundButton(icon: LucideIcons.info),
              ],
            ),
          ),

          // ─── Scan frame ─────────────────────────────────────────────────
          if (_currentMode == 'Scan Food' || _currentMode == 'Barcode')
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

          // ─── Mode selector row ──────────────────────────────────────────
          Positioned(
            bottom: safeBottom > 0 ? safeBottom + 100 : 100,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildModeCard(LucideIcons.scanLine, 'Scan Food'),
                  const SizedBox(width: 8),
                  _buildModeCard(LucideIcons.barcode, 'Barcode'),
                  const SizedBox(width: 8),
                  _buildModeCard(LucideIcons.tag, 'Food label'),
                  const SizedBox(width: 8),
                  _buildModeCard(LucideIcons.image, 'Gallery'),
                ],
              ),
            ),
          ),

          // ─── Shutter row ────────────────────────────────────────────────
          if (_currentMode == 'Scan Food' ||
              _currentMode == 'Gallery' ||
              _currentMode == 'Food label')
            Positioned(
              bottom: safeBottom > 0 ? safeBottom + 28 : 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _CameraRoundButton(icon: LucideIcons.zapOff),
                  const SizedBox(width: 70),
                  GestureDetector(
                    onTap: _isProcessing
                        ? null
                        : (_currentMode == 'Gallery'
                            ? _pickFromGallery
                            : _takePicture),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isProcessing
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.9),
                      ),
                      child: Center(
                        child: Icon(
                          _currentMode == 'Gallery'
                              ? LucideIcons.image
                              : LucideIcons.camera,
                          size: 28,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 114),
                ],
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
              if (modeString == 'Gallery') {
                _pickFromGallery();
              }
              setState(() {
                _currentMode = modeString;
                _barcodeScanned = false;
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22,
                color: isActive ? AppColors.textPrimary : Colors.white),
            const SizedBox(height: 4),
            Text(
              modeString,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.textPrimary : Colors.white,
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
          color: Colors.white.withValues(alpha: 0.85)),
      child: Center(
          child: Icon(icon, size: 20, color: AppColors.textPrimary)),
    );
  }
}

class _ScanCornersPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double cornerRadius;

  _ScanCornersPainter(
      {required this.color,
      required this.strokeWidth,
      required this.cornerLength,
      required this.cornerRadius});

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
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(w - l, 0)
          ..lineTo(w - r, 0)
          ..arcTo(Rect.fromLTWH(w - (r * 2), 0, r * 2, r * 2), -pi / 2,
              pi / 2, false)
          ..lineTo(w, l),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(0, h - l)
          ..lineTo(0, h - r)
          ..arcTo(Rect.fromLTWH(0, h - (r * 2), r * 2, r * 2), pi, -pi / 2,
              false)
          ..lineTo(l, h),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(w - l, h)
          ..lineTo(w - r, h)
          ..arcTo(Rect.fromLTWH(w - (r * 2), h - (r * 2), r * 2, r * 2),
              pi / 2, -pi / 2, false)
          ..lineTo(w, h - l),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
