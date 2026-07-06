import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../config/env_config.dart';
import '../theme/app_colors.dart';

/// Network food thumbnail with disk + memory cache (avoids re-downloading S3 images).
class CachedFoodImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedFoodImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
  });

  static bool isLocalPath(String url) {
    return url.startsWith('file://') ||
        (url.startsWith('/') && !url.startsWith('/uploads/'));
  }

  static String resolveUrl(String url) {
    if (url.startsWith('http')) return url;
    return EnvConfig.resolveMediaUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return errorWidget ?? _defaultPlaceholder();
    }

    if (isLocalPath(url)) {
      return Image.file(
        File(url.replaceFirst('file://', '')),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => errorWidget ?? _defaultPlaceholder(),
      );
    }

    final resolved = resolveUrl(url);
    if (resolved.isEmpty) {
      return errorWidget ?? _defaultPlaceholder();
    }

    return CachedNetworkImage(
      imageUrl: resolved,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => placeholder ?? _loadingPlaceholder(),
      errorWidget: (_, _, _) => errorWidget ?? _defaultPlaceholder(),
    );
  }

  static Widget _defaultPlaceholder() {
    return Container(
      color: AppColors.surfaceMuted,
      child: const Center(
        child: Icon(LucideIcons.utensils, size: 24, color: AppColors.inactive),
      ),
    );
  }

  static Widget _loadingPlaceholder() {
    return Container(
      color: AppColors.surfaceMuted,
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
