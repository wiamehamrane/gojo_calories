import 'package:dio/dio.dart' show DioException;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gojocalories/core/theme/app_colors.dart';
import 'package:gojocalories/core/network/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _agreedToPrivacy = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _referralCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLoginSuccess(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    try {
      final res = await ApiClient.instance.get('auth/me');
      if (res.statusCode == 200) {
        final data = res.data;
        if (!mounted) return;
        if (data['current_weight'] == null) {
          context.go('/onboarding/weight');
        } else if (data['has_paid'] != true) {
          context.go('/onboarding/paywall');
        } else {
          await prefs.setBool('is_onboarded', true);
          if (!mounted) return;
          context.go('/home');
        }
      } else {
        if (mounted) context.go('/onboarding/weight');
      }
    } catch (e) {
      if (mounted) context.go('/onboarding/weight'); // fallback
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final name = _nameCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) return;
    if (_tab.index == 0 && name.isEmpty) return;
    if (_tab.index == 0 && !_agreedToPrivacy) {
      _showError('You must agree to the Privacy Policy to create an account.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final endpoint = _tab.index == 0 ? 'auth/register' : 'auth/login';
      final body = _tab.index == 0
          ? {
              'email': email,
              'name': name,
              'password': password,
              if (_referralCtrl.text.trim().isNotEmpty)
                'referral_code': _referralCtrl.text.trim().toUpperCase(),
            }
          : {'email': email, 'password': password};

      final res = await ApiClient.instance.post(endpoint, data: body);

      if (res.statusCode == 200) {
        final token = res.data['access_token'];
        await _handleLoginSuccess(token);
      } else {
        _showError('Login failed. Check your credentials.');
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
      await GoogleSignIn.instance.initialize(
        clientId: '980076580409-4d78u72lc8o7aqfuoinvd72dk2tr27co.apps.googleusercontent.com',
        serverClientId: const String.fromEnvironment(
          'GOOGLE_WEB_CLIENT_ID',
          defaultValue:
              '980076580409-rgqujk89m5lhvsr3nfg24hhodk08uoeh.apps.googleusercontent.com',
        ),
      );
      final account = await GoogleSignIn.instance.authenticate();
      final auth = account.authentication;
      final res = await ApiClient.instance.post(
        'auth/google',
        data: {'id_token': auth.idToken},
      );
      if (res.statusCode == 200) {
        await _handleLoginSuccess(res.data['access_token']);
      } else {
        _showError('Google Login failed');
      }
    } catch (e) {
      _showError('Failed to sign in with Google: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              'https://api.gojocalories.com/callbacks/sign_in_with_apple'),
        ),
      );
      final res = await ApiClient.instance.post(
        'auth/apple',
        data: {
          'identity_token': credential.identityToken,
          'given_name': credential.givenName,
          'family_name': credential.familyName,
        },
      );
      if (res.statusCode == 200) {
        await _handleLoginSuccess(res.data['access_token']);
      } else {
        _showError('Apple Login failed');
      }
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Subtle decorative gradient blob
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryMid.withValues(alpha: 0.10),
              ),
            ),
          ),

          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 32, 24, 24 + bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + wordmark
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'GojoCalories',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 500.ms),

                    const SizedBox(height: 40),

                    Text(
                          'Your nutrition,\nperfectly tracked.',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.15,
                            letterSpacing: -0.8,
                          ),
                        )
                        .animate()
                        .slideY(
                          begin: 0.15,
                          duration: 500.ms,
                          curve: Curves.easeOutQuad,
                        )
                        .fadeIn(),

                    const SizedBox(height: 8),

                    Text(
                      'AI-powered calorie tracking with a 3-day free trial.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 36),

                    // Tab selector
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tab,
                        indicator: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.textSecondary,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Create Account'),
                          Tab(text: 'Log In'),
                        ],
                        onTap: (_) => setState(() {}),
                      ),
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 24),

                    // Form card
                    Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Name field (sign up only)
                              if (_tab.index == 0) ...[
                                _buildField(
                                  controller: _nameCtrl,
                                  focusNode: _nameFocus,
                                  label: 'Full name',
                                  hint: 'John Doe',
                                  icon: Icons.person_outline_rounded,
                                  textInputAction: TextInputAction.next,
                                  onSubmitted: (_) => FocusScope.of(
                                    context,
                                  ).requestFocus(_emailFocus),
                                ),
                                const SizedBox(height: 14),
                              ],

                              _buildField(
                                controller: _emailCtrl,
                                focusNode: _emailFocus,
                                label: 'Email',
                                hint: 'you@example.com',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_passFocus),
                              ),

                              const SizedBox(height: 14),

                              _buildField(
                                controller: _passwordCtrl,
                                focusNode: _passFocus,
                                label: 'Password',
                                hint: '••••••••',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscurePass,
                                textInputAction: _tab.index == 0
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                onSubmitted: (_) => _tab.index == 0
                                    ? FocusScope.of(context).nextFocus()
                                    : _submitEmail(),
                                suffix: GestureDetector(
                                  onTap: () => setState(
                                    () => _obscurePass = !_obscurePass,
                                  ),
                                  child: Icon(
                                    _obscurePass
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),

                              // Optional referral code — only on sign-up tab
                              if (_tab.index == 0) ...[
                                const SizedBox(height: 14),
                                _buildField(
                                  controller: _referralCtrl,
                                  label: 'Referral Code (optional)',
                                  hint: 'e.g. ABC123',
                                  icon: Icons.card_giftcard_rounded,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submitEmail(),
                                ),
                              ],

                              if (_tab.index == 0)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 6,
                                    bottom: 20,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _agreedToPrivacy,
                                          onChanged: (val) {
                                            setState(() {
                                              _agreedToPrivacy = val ?? false;
                                            });
                                          },
                                          activeColor: AppColors.primary,
                                          side: const BorderSide(
                                            color: AppColors.textPlaceholder,
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => launchUrl(
                                            Uri.parse(
                                              'https://gojocalories.com/privacy-policy',
                                            ),
                                          ),
                                          child: const Text.rich(
                                            TextSpan(
                                              text:
                                                  'I agree to the Terms of Use & ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                                height: 1.4,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: 'Privacy Policy.',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.primaryDark,
                                                    decoration: TextDecoration
                                                        .underline,
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
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () => launchUrl(
                                        Uri.parse(
                                          'https://gojocalories.com/privacy-policy',
                                        ),
                                      ),
                                      child: const Text.rich(
                                        TextSpan(
                                          text:
                                              'By logging in you agree to our Terms & ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            height: 1.4,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Privacy Policy.',
                                              style: TextStyle(
                                                color: AppColors.primaryDark,
                                                decoration:
                                                    TextDecoration.underline,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),

                              // Primary CTA
                              _PrimaryButton(
                                label: _tab.index == 0
                                    ? 'Create Account'
                                    : 'Log In',
                                isLoading: _isLoading,
                                onTap: _submitEmail,
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .slideY(
                          begin: 0.1,
                          delay: 200.ms,
                          duration: 500.ms,
                          curve: Curves.easeOutQuad,
                        )
                        .fadeIn(),

                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: AppColors.border, height: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or continue with',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: AppColors.border, height: 1),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 16),

                    // Social buttons row
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            label: 'Google',
                            icon: _googleIcon(),
                            onTap: _signInWithGoogle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Apple Sign in ONLY on iOS/macOS typically, but we can leave it for both if testing
                        Expanded(
                          child: _SocialButton(
                            label: 'Apple',
                            icon: const Icon(
                              Icons.apple_rounded,
                              size: 20,
                              color: AppColors.textPrimary,
                            ),
                            onTap: _signInWithApple,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 350.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscure = false,
    Widget? suffix,
    void Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
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
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: AppColors.textPlaceholder,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 6),
                suffix,
                const SizedBox(width: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

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
              ? AppColors.primaryDark.withValues(alpha: 0.7)
              : AppColors.primaryDark,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple Google "G" logo painter using 4-colour segments.
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    final starts = [-0.1, 0.4, 0.9, 1.4];
    final sweeps = [0.5, 0.5, 0.5, 0.5];

    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        starts[i] * 3.14159,
        sweeps[i] * 3.14159,
        true,
        paint,
      );
    }
    // white center circle
    paint.color = Colors.white;
    canvas.drawCircle(c, r * 0.55, paint);
    // G bar (simplified with blue rect)
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - r * 0.13, r * 0.9, r * 0.26),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
