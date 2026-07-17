import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';

/// Which legal document to display.
enum LegalDocType { terms, privacy }

/// In-app legal document viewer (Terms of Service / Privacy Policy).
/// Replaces the old external web links so no website is required.
class LegalScreen extends ConsumerWidget {
  final LegalDocType docType;

  const LegalScreen({super.key, required this.docType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final isTerms = docType == LegalDocType.terms;
    final title = Translations.t(
        lang, isTerms ? 'terms_of_service' : 'privacy_policy');
    final sections = isTerms ? _termsSections : _privacySections;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          const Text(
            'Last updated: July 16, 2026',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          for (final section in sections) ...[
            Text(
              section.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _LegalSection {
  final String title;
  final String body;
  const _LegalSection(this.title, this.body);
}

const List<_LegalSection> _termsSections = [
  _LegalSection(
    '1. Acceptance of Terms',
    'By creating an account or using GojoCalories ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App. We may update these terms from time to time; continued use of the App after changes means you accept the updated terms.',
  ),
  _LegalSection(
    '2. Description of Service',
    'GojoCalories is a nutrition tracking application that uses artificial intelligence to estimate the calories and macronutrients in your meals from photos, barcodes, and text descriptions. The App also provides personalized nutrition goals, progress statistics, exercise logging, social features, and smart reminders.',
  ),
  _LegalSection(
    '3. Not Medical Advice',
    'GojoCalories provides general nutrition information for educational and informational purposes only. It is not medical advice, and it is not a substitute for consultation with a qualified physician, dietitian, or other healthcare professional. Always consult a healthcare professional before starting any diet, exercise program, or if you have (or suspect you have) a medical condition, an eating disorder, or are pregnant or nursing.',
  ),
  _LegalSection(
    '4. Accuracy of AI Estimates',
    'Calorie and macronutrient values produced by our AI models are estimates and may be inaccurate. Portion sizes, hidden ingredients, and preparation methods can significantly affect actual nutritional values. You should not rely on the App for medically critical dietary decisions (for example insulin dosing). You can always edit or correct any logged value manually.',
  ),
  _LegalSection(
    '5. Accounts and Eligibility',
    'You must be at least 13 years old (or the minimum age required in your country) to use the App. You are responsible for keeping your account credentials secure and for all activity that occurs under your account. You agree to provide accurate information during onboarding so that your nutrition goals can be calculated correctly.',
  ),
  _LegalSection(
    '6. Subscriptions and Payments',
    'Some features require a paid subscription. Subscriptions purchased through the Apple App Store or Google Play are billed and managed by those platforms, and renew automatically unless cancelled at least 24 hours before the end of the current period. You can manage or cancel your subscription in your App Store or Google Play account settings. Purchases made through our web checkout are processed by Stripe. Except where required by law or by platform policy, payments are non-refundable.',
  ),
  _LegalSection(
    '7. Referrals',
    'The App may offer referral rewards. We reserve the right to modify, suspend, or cancel any referral program at any time, and to withhold rewards obtained through fraud, abuse, or violation of these terms.',
  ),
  _LegalSection(
    '8. User Content and Community Features',
    'The App includes social features such as groups, events, posts, and shared diaries. You are responsible for the content you share. You agree not to post content that is illegal, abusive, harassing, misleading, or that infringes the rights of others. We may remove content or suspend accounts that violate these rules.',
  ),
  _LegalSection(
    '9. Acceptable Use',
    'You agree not to misuse the App, including by attempting to access it using automated means, reverse engineering it, interfering with its operation, or using it for any unlawful purpose.',
  ),
  _LegalSection(
    '10. Intellectual Property',
    'The App, including its design, logos, text, and software, is owned by GojoCalories and protected by intellectual property laws. We grant you a limited, non-exclusive, non-transferable license to use the App for personal, non-commercial purposes.',
  ),
  _LegalSection(
    '11. Termination',
    'You may delete your account at any time from the App settings, which removes your personal data as described in our Privacy Policy. We may suspend or terminate your access if you violate these terms.',
  ),
  _LegalSection(
    '12. Disclaimer of Warranties',
    'The App is provided "as is" and "as available" without warranties of any kind, whether express or implied, including fitness for a particular purpose and accuracy of nutritional information.',
  ),
  _LegalSection(
    '13. Limitation of Liability',
    'To the maximum extent permitted by law, GojoCalories shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or for any health outcomes, arising from your use of the App.',
  ),
  _LegalSection(
    '14. Contact',
    'If you have questions about these Terms of Service, contact us at support@gojocalories.com.',
  ),
];

const List<_LegalSection> _privacySections = [
  _LegalSection(
    '1. Introduction',
    'GojoCalories ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and disclose your personal information when you use our app.',
  ),
  _LegalSection(
    '2. Information We Collect',
    'Account data: your name, email address, and password (stored encrypted).\n\nHealth and profile data: age, gender, height, weight, goal weight, activity level, and dietary preferences, used to calculate your personalized nutrition goals.\n\nFood and exercise logs: meals you log (including photos of food), barcodes you scan, and exercises you record.\n\nCamera and image data: when you photograph a meal, the image is processed by our AI models to estimate nutritional information. Images may be sent to our secure servers or trusted third-party AI services (such as Google Gemini) for analysis, and may be stored to provide your food history and improve recognition accuracy.\n\nDevice data: a push notification identifier (via OneSignal) so we can send you reminders, and basic diagnostic information.',
  ),
  _LegalSection(
    '3. How We Use Your Information',
    'We use your information to: generate personalized nutrition plans and daily targets; provide calorie and macro tracking; send you smart reminders and progress notifications (which you can disable at any time in your device settings); enable social features you choose to use; sync with Apple Health or Google Fit if you enable it; process payments and subscriptions; and improve our AI food recognition technology.',
  ),
  _LegalSection(
    '4. Push Notifications',
    'With your permission, we send push notifications such as meal logging reminders, protein and calorie progress updates, and encouragement messages. These are generated from your own logged data and goals. You can turn notifications off at any time in your device settings or in the App preferences.',
  ),
  _LegalSection(
    '5. Data Sharing',
    'We do not sell your personal data. We share data only with service providers necessary to operate the App: AI providers for food image analysis, OneSignal for push notifications, Stripe / Apple / Google for payment processing, and our cloud hosting providers (such as AWS). Each provider is bound to use your data only to provide their service. If you use social features, the content you post is visible to other users according to the sharing settings you choose.',
  ),
  _LegalSection(
    '6. Data Retention and Deletion',
    'We keep your data for as long as your account is active. You can delete your account and all associated data at any time from the App settings. Once deleted, your personal data is removed from our systems except where retention is required by law (for example payment records).',
  ),
  _LegalSection(
    '7. Data Security',
    'We use industry-standard measures to protect your data, including encryption in transit (HTTPS) and encrypted password storage. No system is 100% secure, but we work to protect your information against unauthorized access.',
  ),
  _LegalSection(
    '8. Your Rights',
    'Depending on your location, you may have the right to access, correct, export, or delete your personal data, and to object to or restrict certain processing. You can exercise most of these rights directly in the App, or by contacting us.',
  ),
  _LegalSection(
    "9. Children's Privacy",
    'The App is not directed at children under 13 (or the applicable minimum age in your country), and we do not knowingly collect personal information from them. If you believe a child has provided us personal data, contact us and we will delete it.',
  ),
  _LegalSection(
    '10. Changes to This Policy',
    'We may update this Privacy Policy from time to time. We will notify you of material changes through the App. The "Last updated" date at the top shows the latest revision.',
  ),
  _LegalSection(
    '11. Contact Us',
    'If you have any questions about this Privacy Policy, contact us at support@gojocalories.com.',
  ),
];
