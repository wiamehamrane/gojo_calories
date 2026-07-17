import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/widgets/cached_food_image.dart';
import '../../domain/meal_share_data.dart';
import '../widgets/meal_share_card.dart';

/// Renders [MealShareCard] off-screen, captures a PNG, and opens the system share sheet.
Future<void> shareMealAsImage(
  BuildContext context,
  MealShareData data, {
  Rect? sharePositionOrigin,
}) async {
  final imageBytes = data.imageBytes ?? await resolveShareImageBytes(data.imageUrl);
  if (!context.mounted) return;

  final shareData = MealShareData(
    name: data.name,
    imageUrl: data.imageUrl,
    imageBytes: imageBytes,
    calories: data.calories,
    protein: data.protein,
    carbs: data.carbs,
    fat: data.fat,
    ingredients: data.ingredients,
    authorName: data.authorName,
  );

  await captureAndShareWidget(
    context,
    builder: (_) => MealShareCard(data: shareData),
    cardWidth: MealShareCard.width,
    filePrefix: 'gojocalories_meal',
    shareText: '${shareData.name} — ${shareData.calories} kcal via gojocalories',
    sharePositionOrigin: sharePositionOrigin,
    precacheBytes: imageBytes,
  );
}

/// Loads meal photo bytes from a local path, disk cache, or network URL.
Future<Uint8List?> resolveShareImageBytes(String? imageUrl) async {
  if (imageUrl == null || imageUrl.trim().isEmpty) return null;
  final raw = imageUrl.trim();

  // Local device path (common right after scan when API image_url is missing).
  if (CachedFoodImage.isLocalPath(raw)) {
    final path = raw.replaceFirst('file://', '');
    final file = File(path);
    if (await file.exists()) {
      try {
        return await file.readAsBytes();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  final resolved = EnvConfig.resolveMediaUrl(raw);
  if (resolved.isEmpty) return null;

  // Prefer CachedNetworkImage disk cache (already shown on Nutrition screen).
  try {
    final cached = await DefaultCacheManager().getFileFromCache(
      CachedFoodImage.stableCacheKey(resolved),
    );
    if (cached != null && await cached.file.exists()) {
      return await cached.file.readAsBytes();
    }
  } catch (_) {}

  try {
    final file = await DefaultCacheManager().getSingleFile(
      resolved,
      key: CachedFoodImage.stableCacheKey(resolved),
    );
    return await file.readAsBytes();
  } catch (_) {}

  return downloadShareImage(resolved);
}

Future<void> captureAndShareWidget(
  BuildContext context,
  {
  required WidgetBuilder builder,
  required double cardWidth,
  required String filePrefix,
  required String shareText,
  Rect? sharePositionOrigin,
  Uint8List? precacheBytes,
}) async {
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.maybeOf(context);
  OverlayState? overlay;
  try {
    overlay = Overlay.of(context, rootOverlay: true);
  } catch (e) {
    debugPrint('Share overlay unavailable: $e');
    messenger?.showSnackBar(
      const SnackBar(content: Text('Could not share right now.')),
    );
    return;
  }

  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(
    const SnackBar(
      content: Text('Preparing share image…'),
      duration: Duration(seconds: 2),
    ),
  );

  // Decode meal photo before capture so Image.memory is ready to paint.
  if (precacheBytes != null && precacheBytes.isNotEmpty) {
    try {
      await precacheImage(MemoryImage(precacheBytes), context);
    } catch (e) {
      debugPrint('Share precache failed: $e');
    }
  }
  if (!context.mounted) return;

  final boundaryKey = GlobalKey();
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      // Keep on-screen (opacity 0) — off-screen capture fails on some devices.
      left: 0,
      top: 0,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.01,
          child: Material(
            type: MaterialType.transparency,
            child: RepaintBoundary(
              key: boundaryKey,
              child: builder(ctx),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  try {
    // Let the overlay layout + paint before capturing.
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Share card failed to render');
    }

    // Extra frame if layout size is still empty.
    if (boundary.size.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await WidgetsBinding.instance.endOfFrame;
    }

    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw Exception('Failed to encode share image');
    }

    final bytes = byteData.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);

    if (!context.mounted) return;

    messenger?.hideCurrentSnackBar();

    final origin = _shareOrigin(context, sharePositionOrigin);

    await Share.shareXFiles(
      [
        XFile(
          file.path,
          mimeType: 'image/png',
          name: '$filePrefix.png',
        ),
      ],
      text: shareText,
      sharePositionOrigin: origin,
    );
  } catch (e, st) {
    debugPrint('Share image failed: $e\n$st');
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Could not create share image.')),
      );
    }
  } finally {
    entry.remove();
  }
}

/// iPad / iOS require a non-zero popover origin for the share sheet.
Rect _shareOrigin(BuildContext context, Rect? preferred) {
  if (preferred != null && preferred.width > 0 && preferred.height > 0) {
    return preferred;
  }
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  final size = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: 2,
    height: 2,
  );
}

Future<Uint8List?> downloadShareImage(String url) async {
  try {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    final data = response.data;
    if (data == null || data.isEmpty) return null;
    return Uint8List.fromList(data);
  } catch (e) {
    debugPrint('Share image download failed: $e');
    return null;
  }
}
