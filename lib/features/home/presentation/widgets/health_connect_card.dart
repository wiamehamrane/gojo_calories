import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gojocalories/core/theme/app_colors.dart';
import 'package:gojocalories/core/theme/app_radius.dart';
import 'package:gojocalories/core/theme/app_spacing.dart';
import 'package:gojocalories/core/theme/app_text_styles.dart';
import 'package:gojocalories/core/localization/locale_provider.dart';
import 'package:gojocalories/core/localization/translations.dart';
import '../../../health/presentation/providers/health_provider.dart';

class HealthConnectCard extends ConsumerWidget {
  const HealthConnectCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthSyncProvider);
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);

    ref.listen(healthSyncProvider, (previous, next) {
      final message = next.error;
      if (message != null && message != previous?.error) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.heartPulse,
                color: AppColors.protein,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                t('health_sync'),
                style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
              ),
              const Spacer(),
              if (health.isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (health.isConnected)
                IconButton(
                  tooltip: t('refresh'),
                  onPressed: () =>
                      ref.read(healthSyncProvider.notifier).refresh(),
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            health.isConnected
                ? t('health_sync_connected')
                : t('health_sync_prompt'),
            style: AppTextStyles.bodyRegular,
          ),
          if (health.isConnected) ...[
            const SizedBox(height: 14),
            _SyncedStatsRow(health: health, lang: lang),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: health.isLoading
                    ? null
                    : () => ref.read(healthSyncProvider.notifier).disconnect(),
                child: Text(t('disconnect')),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Row(
              children: [
                // Only show the button that matches the platform: Apple
                // Health on iOS, Health Connect on Android.
                if (Platform.isIOS)
                  Expanded(
                    child: _HealthButton(
                      label: t('apple_health'),
                      labelKey: 'apple_health',
                      lang: lang,
                      icon: LucideIcons.apple,
                      color: AppColors.textPrimary,
                      isConnected: false,
                      enabled: true,
                      onTap: () => ref
                          .read(healthSyncProvider.notifier)
                          .connectAppleHealth(),
                    ),
                  ),
                if (Platform.isAndroid)
                  Expanded(
                    child: _HealthButton(
                      label: t('health_connect'),
                      labelKey: 'health_connect',
                      lang: lang,
                      icon: LucideIcons.activity,
                      color: const Color(0xFF4285F4),
                      isConnected: false,
                      enabled: health.isAvailable,
                      onTap: () => ref
                          .read(healthSyncProvider.notifier)
                          .connectHealthConnect(),
                    ),
                  ),
              ],
            ),
            if (!Platform.isIOS && !Platform.isAndroid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  t('health_sync_platform_only'),
                  style: AppTextStyles.bodyRegular.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SyncedStatsRow extends StatelessWidget {
  const _SyncedStatsRow({required this.health, required this.lang});

  final HealthSyncState health;
  final String lang;

  @override
  Widget build(BuildContext context) {
    String t(String k) => Translations.t(lang, k);
    final data = health.data;
    final weight = data.weightKg;
    final weightLabel = weight == null
        ? '--'
        : '${weight.toStringAsFixed(1)} kg';

    return Row(
      children: [
        _StatChip(
          icon: LucideIcons.footprints,
          label: '${data.stepsToday ?? 0}',
          caption: t('steps'),
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: LucideIcons.flame,
          label: '${data.activeCaloriesToday ?? 0}',
          caption: t('active_cal'),
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: LucideIcons.scale,
          label: weightLabel,
          caption: t('weight_label'),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.caption,
  });

  final IconData icon;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.primaryMid),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodyBold.copyWith(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            Text(
              caption,
              style: AppTextStyles.bodyRegular.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthButton extends StatelessWidget {
  final String label;
  final String labelKey;
  final String lang;
  final IconData icon;
  final Color color;
  final bool isConnected;
  final bool enabled;
  final VoidCallback? onTap;

  const _HealthButton({
    required this.label,
    required this.labelKey,
    required this.lang,
    required this.icon,
    required this.color,
    required this.isConnected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : Colors.grey;

    return Material(
      color: effectiveColor.withValues(alpha: enabled ? 0.05 : 0.03),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isConnected
                  ? AppColors.primaryMid
                  : effectiveColor.withValues(alpha: 0.1),
              width: isConnected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Icon(
                isConnected ? LucideIcons.circleCheck : icon,
                color: isConnected ? AppColors.primaryMid : effectiveColor,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              if (!enabled && Platform.isIOS && labelKey == 'health_connect')
                Text(
                  Translations.t(lang, 'android_only'),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                )
              else if (!enabled && Platform.isAndroid && labelKey == 'apple_health')
                Text(
                  Translations.t(lang, 'ios_only'),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
