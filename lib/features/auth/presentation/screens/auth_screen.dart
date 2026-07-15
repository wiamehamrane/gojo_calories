import 'package:dio/dio.dart' show DioException;
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gojocalories/core/config/env_config.dart';
import 'package:gojocalories/core/theme/app_colors.dart';
import 'package:gojocalories/core/utils/image.dart';
import 'package:gojocalories/core/di/repository_providers.dart';
import 'package:gojocalories/features/auth/data/repositories/auth_repository.dart';
import 'package:gojocalories/core/routing/route_paths.dart';
import 'package:gojocalories/core/routing/app_navigation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _agreedToPrivacy = false;
  bool _showEmailSheet = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLoginSuccess(String token) async {
    final auth = ref.read(authRepositoryProvider);
    await auth.saveToken(token);
    await _routeAfterAuth(auth);
  }

  Future<void> _routeAfterAuth(AuthRepository auth) async {
    try {
      final data = await auth.getMe();
      if (!mounted) return;
      if (data['is_email_verified'] != true) {
        final email = data['email'] as String? ?? '';
        context.go('${RoutePaths.verifyOtp}?email=${Uri.encodeComponent(email)}');
        return;
      }
      if (data['current_weight'] == null) {
        AppNavigation.goToWeightSetup(context: context);
      } else if (data['has_paid'] != true) {
        AppNavigation.goToPaywall(context: context);
      } else {
        await auth.setOnboarded(true);
        if (!mounted) return;
        context.go(RoutePaths.home);
      }
    } catch (e) {
      if (mounted) AppNavigation.goToWeightSetup(context: context);
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) return;
    if (_tab.index == 0 && !_agreedToPrivacy) {
      _showError('You must agree to the Privacy Policy to create an account.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_tab.index == 0) {
        final result = await auth.register(email: email, password: password);
        if (!mounted) return;
        if (result['requires_verification'] == true) {
          context.go(
            '${RoutePaths.verifyOtp}?email=${Uri.encodeComponent(email)}',
          );
          return;
        }
        final token = result['access_token'] as String?;
        if (token != null) {
          await _handleLoginSuccess(token);
        }
      } else {
        try {
          final token = await auth.login(email: email, password: password);
          await _handleLoginSuccess(token);
        } on DioException catch (e) {
          if (e.response?.statusCode == 403) {
            if (!mounted) return;
            context.go(
              '${RoutePaths.verifyOtp}?email=${Uri.encodeComponent(email)}',
            );
            return;
          }
          rethrow;
        }
      }
    } on DioException catch (e) {
      String errorMessage = 'Something went wrong. Please try again.';
      if (e.response != null && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('detail')) {
          errorMessage = data['detail'].toString();
        } else {
          errorMessage = e.response!.data.toString();
        }
      }
      _showError('API Error: $errorMessage');
    } catch (e) {
      _showError('Something went wrong. Please try again. Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      if (Platform.isIOS) {
        await GoogleSignIn.instance.initialize(
          clientId: EnvConfig.googleIosClientId,
          serverClientId: EnvConfig.googleWebClientId,
        );
      } else if (Platform.isAndroid) {
        final androidClientId = EnvConfig.googleAndroidClientId;
        await GoogleSignIn.instance.initialize(
          clientId: androidClientId,
          serverClientId: EnvConfig.googleWebClientId,
        );
      } else {
        await GoogleSignIn.instance.initialize(
          serverClientId: EnvConfig.googleWebClientId,
        );
      }

      final account = await GoogleSignIn.instance.authenticate();
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw Exception(
          'Google did not return an ID token. Check Android OAuth setup.',
        );
      }
      final token =
          await ref.read(authRepositoryProvider).googleLogin(idToken);
      await _handleLoginSuccess(token);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        final message = e.toString().toLowerCase();
        if (message.contains('[16]') ||
            message.contains('account reauth failed')) {
          _showError(_googleAndroidConfigError());
        }
        return;
      }
      _showError('Failed to sign in with Google: $e');
    } catch (e) {
      _showError('Failed to sign in with Google: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _googleAndroidConfigError() {
    return 'Google Sign-In is not configured for this Android build.\n\n'
        'In Google Cloud Console, create an Android OAuth client for '
        'com.gojocalories.gojocalories and add these SHA-1 fingerprints:\n'
        '• Release/upload key: 22:53:22:8A:6E:13:93:D6:3E:B2:57:CC:39:B4:66:92:62:06:F3:18\n'
        '• Debug key: 2A:7F:D1:95:47:F8:0A:4F:9F:BC:6B:7E:97:EA:D1:74:C4:40:0B:BD\n'
        '• Play App Signing key from Play Console → App integrity\n\n'
        'Then clear Google Play Services cache and try again.';
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'com.gojocalories.gojocalories.web',
          redirectUri: Uri.parse(
            'https://api.gojocalories.com/callbacks/sign_in_with_apple',
          ),
        ),
      );
      final token = await ref.read(authRepositoryProvider).appleLogin(
            identityToken: credential.identityToken!,
            givenName: credential.givenName,
            familyName: credential.familyName,
          );
      await _handleLoginSuccess(token);
    } catch (e) {
      if (e is AuthorizationErrorCode && e == AuthorizationErrorCode.canceled) {
        // user cancelled
      } else {
        _showError('Failed to sign in with Apple: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openEmailSheet() {
    FocusScope.of(context).unfocus();
    setState(() => _showEmailSheet = true);
  }

  void _closeEmailSheet() {
    FocusScope.of(context).unfocus();
    setState(() => _showEmailSheet = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          // Background that gently dims while the email sheet is open.
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              color: _showEmailSheet
                  ? const Color(0xFFB5B5B5)
                  : const Color(0xFFF7F7F7),
            ),
          ),
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  Image.asset(
                    ImageAsset.logoHeader,
                    width: 88,
                    height: 88,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'GojoCalories',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(flex: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (Platform.isIOS) ...[
                          _SocialCircleButton(
                            onTap: _isLoading ? null : _signInWithApple,
                            child: Icon(
                              Icons.apple,
                              size: 28,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 20),
                        ],
                        _SocialCircleButton(
                          onTap: _isLoading ? null : _signInWithGoogle,
                          child: SvgPicture.asset(
                            'assets/icons/google_logo.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                        const SizedBox(width: 20),
                        _SocialCircleButton(
                          onTap: _isLoading ? null : _openEmailSheet,
                          child: Icon(
                            Icons.mail_outline,
                            size: 24,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: _LegalFooter(
                      onTermsTap: () => launchUrl(
                        Uri.parse('https://gojocalories.com/terms'),
                      ),
                      onPrivacyTap: () => launchUrl(
                        Uri.parse('https://gojocalories.com/privacy-policy'),
                      ),
                    ),
                  ),
                  SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),

          // Frosted-glass barrier that blurs the page behind the sheet.
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_showEmailSheet,
              child: GestureDetector(
                onTap: _closeEmailSheet,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _showEmailSheet ? 1 : 0),
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) {
                    if (t == 0) return const SizedBox.expand();
                    return BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10 * t, sigmaY: 10 * t),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.10 * t),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Email sheet slides and fades in graciously.
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSlide(
              offset: _showEmailSheet ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _showEmailSheet ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: IgnorePointer(
                  ignoring: !_showEmailSheet,
                  child: GestureDetector(
                    onTap: () {},
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.92,
                      ),
                      child: _EmailAuthSheet(
                        tabController: _tab,
                        emailCtrl: _emailCtrl,
                        passwordCtrl: _passwordCtrl,
                        emailFocus: _emailFocus,
                        passFocus: _passFocus,
                        obscurePass: _obscurePass,
                        agreedToPrivacy: _agreedToPrivacy,
                        isLoading: _isLoading,
                        onToggleObscure: () =>
                            setState(() => _obscurePass = !_obscurePass),
                        onAgreedChanged: (v) =>
                            setState(() => _agreedToPrivacy = v),
                        onSubmit: _submitEmail,
                        onPrivacyTap: () => launchUrl(
                          Uri.parse('https://gojocalories.com/privacy-policy'),
                        ),
                        onForgotPassword: () {
                          final email = Uri.encodeComponent(
                            _emailCtrl.text.trim(),
                          );
                          context.push(
                            email.isEmpty
                                ? RoutePaths.forgotPassword
                                : '${RoutePaths.forgotPassword}?email=$email',
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.12),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryDark),
              ),
            ),
        ],
      ),
    );
  }
}

class _SocialCircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _SocialCircleButton({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  const _LegalFooter({
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'By continuing, you agree to our',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 2),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GestureDetector(
              onTap: onTermsTap,
              child: Text(
                'Terms of Service',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              ' and ',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            GestureDetector(
              onTap: onPrivacyTap,
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmailAuthSheet extends StatelessWidget {
  final TabController tabController;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final FocusNode emailFocus;
  final FocusNode passFocus;
  final bool obscurePass;
  final bool agreedToPrivacy;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final ValueChanged<bool> onAgreedChanged;
  final VoidCallback onSubmit;
  final VoidCallback onPrivacyTap;
  final VoidCallback onForgotPassword;

  const _EmailAuthSheet({
    required this.tabController,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.emailFocus,
    required this.passFocus,
    required this.obscurePass,
    required this.agreedToPrivacy,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onAgreedChanged,
    required this.onSubmit,
    required this.onPrivacyTap,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final isCreate = tabController.index == 0;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.65),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D0D0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _AnimatedAuthTabBar(tabController: tabController),
              const SizedBox(height: 24),
              _AuthField(
                label: 'Email',
                controller: emailCtrl,
                focusNode: emailFocus,
                hint: 'you@example.com',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(passFocus),
              ),
              const SizedBox(height: 16),
              _AuthField(
                label: 'Password',
                controller: passwordCtrl,
                focusNode: passFocus,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: obscurePass,
                textInputAction:
                    isCreate ? TextInputAction.next : TextInputAction.done,
                onSubmitted: (_) => onSubmit(),
                suffix: GestureDetector(
                  onTap: onToggleObscure,
                  child: Icon(
                    obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: !isCreate
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading ? null : onForgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              // Privacy checkbox gracefully grows/shrinks when switching
              // between Create Account and Log In.
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: !isCreate
                      ? const SizedBox(width: double.infinity)
                      : Column(
                          key: const ValueKey('privacy_row'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: agreedToPrivacy,
                        onChanged: (val) => onAgreedChanged(val ?? false),
                        activeColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.textPlaceholder,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: onPrivacyTap,
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree to the Terms of Use & ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              _PrimaryButton(
                label: isCreate ? 'Create Account' : 'Log In',
                isLoading: isLoading,
                onTap: onSubmit,
              ),
            ],
          ),
        ),
        ),
      ),
        ),
      ),
    );
  }
}

class _AnimatedAuthTabBar extends StatelessWidget {
  final TabController tabController;

  const _AnimatedAuthTabBar({required this.tabController});

  static const _duration = Duration(milliseconds: 320);
  static const _curve = Curves.easeInOutCubic;

  void _selectTab(int index) {
    if (tabController.index == index) return;
    tabController.animateTo(index, duration: _duration, curve: _curve);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = (constraints.maxWidth - 6) / 2;

        return Container(
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(22),
          ),
          child: AnimatedBuilder(
            animation: tabController.animation!,
            builder: (context, child) {
              final position = tabController.animation!.value;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: position * tabWidth,
                    width: tabWidth,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _selectTab(0),
                          child: Center(
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color.lerp(
                                  AppColors.textPrimary,
                                  AppColors.textSecondary,
                                  position,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _selectTab(1),
                          child: Center(
                            child: Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color.lerp(
                                  AppColors.textSecondary,
                                  AppColors.textPrimary,
                                  position,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _AuthField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscure;
  final Widget? suffix;
  final void Function(String)? onSubmitted;

  const _AuthField({
    required this.label,
    required this.controller,
    this.focusNode,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscure = false,
    this.suffix,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  textInputAction: textInputAction,
                  obscureText: obscure,
                  onSubmitted: onSubmitted,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: AppColors.textPlaceholder,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (suffix != null) ...[
                suffix!,
                const SizedBox(width: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: isLoading
              ? AppColors.primary.withValues(alpha: 0.7)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.35),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    label,
                    key: ValueKey(label),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
