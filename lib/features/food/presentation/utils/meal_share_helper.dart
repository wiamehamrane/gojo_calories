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
  BuildContext context, {
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
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(content: Text('Could not share right now.')),
    );
    return;
  }

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
    } catch (_) {}
  }
  if (!context.mounted) return;

  final boundaryKey = GlobalKey();
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: -cardWidth - 40,
      top: 0,
      child: Material(
        type: MaterialType.transparency,
        child: RepaintBoundary(
          key: boundaryKey,
          child: builder(ctx),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  try {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw Exception('Share card failed to render');
    }

    // Wait until the first paint finishes (image decoded).
    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
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

    final box = context.findRenderObject() as RenderBox?;
    final origin = sharePositionOrigin ??
        (box != null ? box.localToGlobal(Offset.zero) & box.size : null);

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
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Could not create share image.')),
      );
    }
  } finally {
    entry.remove();
  }
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
  } catch (_) {
    return null;
  }
}
