import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          Translations.t(lang, 'language'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          _LangOption(
            code: 'en',
            label: 'English',
            native: 'English',
            currentLang: lang,
            ref: ref,
          ),
          const SizedBox(height: 10),
          _LangOption(
            code: 'fr',
            label: 'Français',
            native: 'Français',
            currentLang: lang,
            ref: ref,
          ),
          const SizedBox(height: 10),
          _LangOption(
            code: 'ar',
            label: 'العربية',
            native: 'العربية (دارجة)',
            currentLang: lang,
            ref: ref,
          ),
          const SizedBox(height: 10),
          _LangOption(
            code: 'es',
            label: 'Español',
            native: 'Español',
            currentLang: lang,
            ref: ref,
          ),
          const SizedBox(height: 10),
          _LangOption(
            code: 'nl',
            label: 'Nederlands',
            native: 'Nederlands',
            currentLang: lang,
            ref: ref,
          ),
          const SizedBox(height: 10),
          _LangOption(
            code: 'pt',
            label: 'Português',
            native: 'Português',
            currentLang: lang,
            ref: ref,
          ),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String code;
  final String label;
  final String native;
  final String currentLang;
  final WidgetRef ref;

  const _LangOption({
    required this.code,
    required this.label,
    required this.native,
    required this.currentLang,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentLang == code;
    return GestureDetector(
      onTap: () => ref.read(localeProvider.notifier).setLocale(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _LanguageFlag(code: code),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    native,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }
}

/// Emoji flags render as broken boxes on many Android devices (each regional
/// indicator shows separately). Use simple painted badges instead.
class _LanguageFlag extends StatelessWidget {
  final String code;
  const _LanguageFlag({required this.code});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(width: 36, height: 28, child: _buildFlag()),
    );
  }

  Widget _buildFlag() {
    switch (code) {
      case 'fr':
        return const Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: ColoredBox(color: Color(0xFF002395))),
            Expanded(child: ColoredBox(color: Colors.white)),
            Expanded(child: ColoredBox(color: Color(0xFFED2939))),
          ],
        );
      case 'ar':
        return Container(
          color: const Color(0xFFC1272D),
          alignment: Alignment.center,
          child: const Text(
            '★',
            style: TextStyle(
              color: Color(0xFF006233),
              fontSize: 14,
              height: 1,
            ),
          ),
        );
      case 'es':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: Container(color: const Color(0xFFAA151B)),
            ),
            Expanded(
              flex: 1,
              child: Container(color: const Color(0xFFF1BF00)),
            ),
            Expanded(
              flex: 2,
              child: Container(color: const Color(0xFFAA151B)),
            ),
          ],
        );
      case 'nl':
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: ColoredBox(color: Color(0xFFAE1C28))),
            Expanded(child: ColoredBox(color: Colors.white)),
            Expanded(child: ColoredBox(color: Color(0xFF21468B))),
          ],
        );
      case 'pt':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 2,
              child: Container(color: const Color(0xFF006600)),
            ),
            Expanded(
              flex: 3,
              child: Container(color: const Color(0xFFFF0000)),
            ),
          ],
        );
      case 'en':
      default:
        return Container(
          color: const Color(0xFF012169),
          alignment: Alignment.center,
          child: const Text(
            'EN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        );
    }
  }
}
