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

class ScanFoodScreen extends ConsumerStatefulWidget {
  final String initialMode;
  const ScanFoodScreen({super.key, this.initialMode = 'Scan Food'});

  @override
  ConsumerState<ScanFoodScreen> createState() => _ScanFoodScreenState();
}

class _ScanFoodScreenState extends ConsumerState<ScanFoodScreen> with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isProcessing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late String _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _isInitializing = false);
        return;
      }
      
      _controller = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
    } catch (e) {
      debugPrint('Camera init error: $e');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _analyzeFile(String path, String name) async {
    setState(() => _isProcessing = true);
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analyzing image via AI...'), duration: Duration(seconds: 3)),
      );

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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged ${data['name']} (${data['calories']} kcal)!'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed analyzing: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;
    try {
      final photo = await _controller!.takePicture();
      if (!mounted) return;
      await _analyzeFile(photo.path, photo.name);
    } catch (e) {
      debugPrint('Photo error $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img == null) return;
    await _analyzeFile(img.path, img.name);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Background layer depending on mode
          Positioned.fill(
            child: _currentMode == 'Scan Food' || _currentMode == 'Food label'
                ? (_controller != null && _controller!.value.isInitialized
                    ? CameraPreview(_controller!)
                    : const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)))
                : (_currentMode == 'Barcode'
                    ? MobileScanner(
                        onDetect: (capture) {
                          if (!mounted) return;
                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Barcode Found: ${barcodes.first.rawValue}'),
                              backgroundColor: AppColors.primaryDark,
                            ));
                            Navigator.pop(context);
                          }
                        },
                      )
                    : const Center(child: Text('Gallery Selected', style: TextStyle(color: Colors.white)))),
          ),

          // Top buttons
          Positioned(
            top: safeTop > 0 ? safeTop + 10 : 30,
            left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const _CameraRoundButton(icon: LucideIcons.x),
                ),
                const _CameraRoundButton(icon: LucideIcons.info),
              ],
            ),
          ),

          // Scan frame
          if (_currentMode == 'Scan Food' || _currentMode == 'Barcode')
            Center(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _pulseAnimation.value,
                    child: CustomPaint(
                      size: const Size(240, 240),
                      painter: _ScanCornersPainter(color: Colors.white, strokeWidth: 3, cornerLength: 28, cornerRadius: 6),
                    ),
                  );
                },
              ),
            ),

          // Mode selector row
          Positioned(
            bottom: safeBottom > 0 ? safeBottom + 100 : 100,
            left: 0, right: 0,
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

          // Shutter row
          if (_currentMode == 'Scan Food' || _currentMode == 'Gallery')
            Positioned(
              bottom: safeBottom > 0 ? safeBottom + 28 : 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _CameraRoundButton(icon: LucideIcons.zapOff),
                  const SizedBox(width: 70),
                  GestureDetector(
                    onTap: _currentMode == 'Gallery' ? _pickFromGallery : _takePicture,
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(230)),
                      child: _isProcessing 
                          ? const CircularProgressIndicator(color: AppColors.primaryDark) 
                          : Icon(_currentMode == 'Gallery' ? LucideIcons.image : LucideIcons.camera, size: 28, color: AppColors.textPrimary),
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
      onTap: () {
        if (modeString == 'Gallery') {
           _pickFromGallery();
        }
        setState(() => _currentMode = modeString);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withAlpha(64),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isActive ? AppColors.textPrimary : Colors.white),
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
      width: 44, height: 44,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(216)),
      child: Center(child: Icon(icon, size: 20, color: AppColors.textPrimary)),
    );
  }
}

class _ScanCornersPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double cornerRadius;

  _ScanCornersPainter({required this.color, required this.strokeWidth, required this.cornerLength, required this.cornerRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height, l = cornerLength, r = cornerRadius;
    canvas.drawPath(Path()..moveTo(0, l)..lineTo(0, r)..arcTo(Rect.fromLTWH(0, 0, r*2, r*2), pi, pi/2, false)..lineTo(l, 0), paint);
    canvas.drawPath(Path()..moveTo(w-l, 0)..lineTo(w-r, 0)..arcTo(Rect.fromLTWH(w-(r*2), 0, r*2, r*2), -pi/2, pi/2, false)..lineTo(w, l), paint);
    canvas.drawPath(Path()..moveTo(0, h-l)..lineTo(0, h-r)..arcTo(Rect.fromLTWH(0, h-(r*2), r*2, r*2), pi, -pi/2, false)..lineTo(l, h), paint);
    canvas.drawPath(Path()..moveTo(w-l, h)..lineTo(w-r, h)..arcTo(Rect.fromLTWH(w-(r*2), h-(r*2), r*2, r*2), pi/2, -pi/2, false)..lineTo(w, h-l), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
