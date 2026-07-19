import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/di/repository_providers.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../events/domain/models/event_location_selection.dart';
import '../../../events/presentation/widgets/event_location_picker_sheet.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../widgets/coach_ui.dart';

const _specialtyOptions = [
  'nutrition',
  'weight_loss',
  'muscle',
  'cardio',
  'general',
];

const _languageOptions = [
  'en',
  'fr',
  'ar',
  'es',
  'nl',
  'pt',
  'zh',
  'ru',
  'de',
  'ja',
  'ko',
];

class BecomeCoachScreen extends ConsumerStatefulWidget {
  const BecomeCoachScreen({super.key});

  @override
  ConsumerState<BecomeCoachScreen> createState() => _BecomeCoachScreenState();
}

class _BecomeCoachScreenState extends ConsumerState<BecomeCoachScreen> {
  final _pageController = PageController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();

  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _userHasPaid = false;
  bool _userIsCoach = false;
  bool _isActive = false;
  bool _hasCoachSub = false;

  final Set<String> _specialties = {};
  final Set<String> _languages = {};
  String? _gender;
  String? _coachingMode;
  double? _latitude;
  double? _longitude;
  String? _city;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final me = await ref.read(coachesRepositoryProvider).getMe();
      final profile = me.profile;
      if (profile != null) {
        _bioController.text = profile.bio ?? '';
        _phoneController.text = profile.phone ?? '';
        if (profile.experienceYears != null) {
          _experienceController.text = profile.experienceYears.toString();
        }
        _specialties
          ..clear()
          ..addAll(profile.specialties);
        _languages
          ..clear()
          ..addAll(profile.languages);
        _gender = profile.gender;
        _coachingMode = profile.coachingMode;
        _latitude = profile.latitude;
        _longitude = profile.longitude;
        _city = profile.city;
        _isActive = profile.isActive;
        _hasCoachSub = profile.hasActiveCoachSubscription;
      }
      setState(() {
        _userHasPaid = me.userHasPaid;
        _userIsCoach = me.userIsCoach || (profile?.userIsCoach ?? false);
        _loading = false;
      });
    } catch (_) {
      // Fallback to profile has_paid if coaches/me fails for unpaid users.
      try {
        final profile = await ref.read(profileRepositoryProvider).getMe();
        setState(() {
          _userHasPaid = profile['has_paid'] == true;
          _loading = false;
        });
      } catch (_) {
        setState(() {
          _loading = false;
          _error = 'error';
        });
      }
    }
  }

  String _t(String key) => Translations.t(ref.read(localeProvider), key);

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickLocation() async {
    HapticFeedback.selectionClick();
    final selected = await EventLocationPickerSheet.show(
      context,
      initial: (_latitude != null && _longitude != null)
          ? EventLocationSelection(
              name: _city ?? '',
              latitude: _latitude,
              longitude: _longitude,
            )
          : null,
    );
    if (selected == null || !selected.hasCoordinates || !mounted) return;
    setState(() {
      _latitude = selected.latitude;
      _longitude = selected.longitude;
      _city = selected.name;
    });
  }

  bool _validateStep0() {
    if (_bioController.text.trim().isEmpty) {
      setState(() => _error = 'become_coach_bio_required');
      return false;
    }
    if (_specialties.isEmpty) {
      setState(() => _error = 'become_coach_specialty_required');
      return false;
    }
    if (_gender == null) {
      setState(() => _error = 'become_coach_gender_required');
      return false;
    }
    if (_coachingMode == null) {
      setState(() => _error = 'become_coach_mode_required');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  bool _validateStep1() {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _error = 'become_coach_phone_required');
      return false;
    }
    if (_latitude == null || _longitude == null) {
      setState(() => _error = 'become_coach_location_required');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  Map<String, dynamic> _payload() {
    final years = int.tryParse(_experienceController.text.trim());
    return {
      'bio': _bioController.text.trim(),
      'specialties': _specialties.toList(),
      'gender': _gender,
      'experience_years': years,
      'phone': _phoneController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      'city': _city,
      'languages': _languages.toList(),
      'coaching_mode': _coachingMode,
    };
  }

  Future<void> _activateCoach() async {
    final repo = ref.read(coachesRepositoryProvider);
    final activated = await repo.activate();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _userIsCoach = true;
      _isActive = activated.isActive;
      _hasCoachSub = activated.hasActiveCoachSubscription || _hasCoachSub;
    });
    ref.invalidate(profileProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t('become_coach_success'))),
    );
    context.pop();
  }

  Future<void> _saveProfileOnly() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(coachesRepositoryProvider).upsertMe(_payload());
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('become_coach_saved'))),
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response!.data['detail']?.toString() ?? '')
          : '';
      setState(() {
        _saving = false;
        _error = detail.isNotEmpty ? detail : 'become_coach_failed';
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'become_coach_failed';
      });
    }
  }

  Future<void> _pauseListing() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref.read(coachesRepositoryProvider).deactivate();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _isActive = updated.isActive;
        _userIsCoach = true;
      });
      ref.invalidate(profileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('become_coach_paused'))),
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response!.data['detail']?.toString() ?? '')
          : '';
      setState(() {
        _saving = false;
        _error = detail.isNotEmpty ? detail : 'become_coach_failed';
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'become_coach_failed';
      });
    }
  }

  Future<void> _resumeListing() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(coachesRepositoryProvider).upsertMe(_payload());
      if (!mounted) return;

      if (!_hasCoachSub && !EnvConfig.skipCoachPayment) {
        setState(() => _saving = false);
        final paid = await context.push<bool>(RoutePaths.coachPaywall);
        if (!mounted) return;
        if (paid != true) {
          setState(() => _error = 'become_coach_payment_required');
          return;
        }
        setState(() {
          _hasCoachSub = true;
          _saving = true;
        });
      }

      final activated = await ref.read(coachesRepositoryProvider).activate();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _isActive = activated.isActive;
        _userIsCoach = true;
        _hasCoachSub = activated.hasActiveCoachSubscription || _hasCoachSub;
      });
      ref.invalidate(profileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('become_coach_resumed'))),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = e.response?.data is Map
          ? (e.response!.data['detail']?.toString() ?? '')
          : '';
      setState(() {
        _saving = false;
        if (status == 402) {
          _error = 'become_coach_sub_required';
        } else if (detail.isNotEmpty) {
          _error = detail;
        } else {
          _error = 'become_coach_failed';
        }
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'become_coach_failed';
      });
    }
  }

  Future<void> _submit() async {
    if (!_validateStep0() || !_validateStep1()) {
      if (!_validateStep0()) {
        _goTo(0);
      } else {
        _goTo(1);
      }
      return;
    }

    // Existing coach: save profile only (listing toggled separately).
    if (_userIsCoach) {
      await _saveProfileOnly();
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(coachesRepositoryProvider);
      await repo.upsertMe(_payload());
      if (!mounted) return;

      if (!_hasCoachSub && !EnvConfig.skipCoachPayment) {
        setState(() => _saving = false);
        final paid = await context.push<bool>(RoutePaths.coachPaywall);
        if (!mounted) return;
        if (paid != true) {
          setState(() => _error = 'become_coach_payment_required');
          return;
        }
        setState(() {
          _hasCoachSub = true;
          _saving = true;
          _error = null;
        });
      }

      await _activateCoach();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final detail = e.response?.data is Map
          ? (e.response!.data['detail']?.toString() ?? '')
          : '';
      setState(() {
        _saving = false;
        if (status == 403) {
          _error = 'become_coach_pro_required';
          _userHasPaid = false;
        } else if (status == 402) {
          _error = 'become_coach_sub_required';
        } else if (detail.isNotEmpty) {
          _error = detail;
        } else {
          _error = 'become_coach_failed';
        }
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'become_coach_failed';
      });
    }
  }

  String _stepSubtitle(String Function(String) t) {
    switch (_step) {
      case 1:
        return t('become_coach_step_contact');
      case 2:
        return t('become_coach_step_review');
      default:
        return t('become_coach_step_about');
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_userHasPaid
              ? Column(
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(LucideIcons.arrowLeft),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _ProRequired(
                        t: t,
                        onSubscribe: () {
                          HapticFeedback.selectionClick();
                          context.push(RoutePaths.paywall);
                        },
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFE8FBFE),
                            Color(0xFFF2F2F7),
                            Color(0xFFFFF6EE),
                          ],
                          stops: [0, 0.55, 1],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () => context.pop(),
                                icon: const Icon(LucideIcons.arrowLeft),
                              ),
                            ),
                            CoachGradientHeader(
                              title: _userIsCoach
                                  ? t('become_coach_manage_title')
                                  : t('become_coach_title'),
                              subtitle: _stepSubtitle(t),
                              icon: _userIsCoach
                                  ? LucideIcons.badgeCheck
                                  : LucideIcons.sparkles,
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: -0.04, curve: Curves.easeOutCubic),
                    if (_userIsCoach)
                      _ListingStatusBanner(
                        t: t,
                        isActive: _isActive,
                      ),
                    _ConnectedStepIndicator(step: _step, t: t),
                    if (_error != null)
                      _ErrorBanner(
                        message:
                            t(_error!) == _error ? _error! : t(_error!),
                      ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (i) => setState(() => _step = i),
                        children: [
                          _AboutStep(
                            t: t,
                            bioController: _bioController,
                            experienceController: _experienceController,
                            specialties: _specialties,
                            languages: _languages,
                            gender: _gender,
                            coachingMode: _coachingMode,
                            onToggleSpecialty: (v) {
                              setState(() {
                                if (_specialties.contains(v)) {
                                  _specialties.remove(v);
                                } else {
                                  _specialties.add(v);
                                }
                              });
                            },
                            onToggleLanguage: (v) {
                              setState(() {
                                if (_languages.contains(v)) {
                                  _languages.remove(v);
                                } else {
                                  _languages.add(v);
                                }
                              });
                            },
                            onGender: (v) => setState(() => _gender = v),
                            onMode: (v) => setState(() => _coachingMode = v),
                          )
                              .animate(key: const ValueKey('coach-step-0'))
                              .fadeIn(duration: 320.ms)
                              .slideY(
                                begin: 0.05,
                                curve: Curves.easeOutCubic,
                              ),
                          _ContactStep(
                            t: t,
                            phoneController: _phoneController,
                            city: _city,
                            hasLocation:
                                _latitude != null && _longitude != null,
                            onPickLocation: _pickLocation,
                          )
                              .animate(key: const ValueKey('coach-step-1'))
                              .fadeIn(duration: 320.ms)
                              .slideY(
                                begin: 0.05,
                                curve: Curves.easeOutCubic,
                              ),
                          _ReviewStep(
                            t: t,
                            bio: _bioController.text.trim(),
                            specialties: _specialties.toList(),
                            gender: _gender,
                            mode: _coachingMode,
                            phone: _phoneController.text.trim(),
                            city: _city,
                            languages: _languages.toList(),
                            experience: _experienceController.text.trim(),
                            isActive: _isActive,
                            isCoach: _userIsCoach,
                            saving: _saving,
                            onPause: _pauseListing,
                            onResume: _resumeListing,
                          )
                              .animate(key: const ValueKey('coach-step-2'))
                              .fadeIn(duration: 320.ms)
                              .slideY(
                                begin: 0.05,
                                curve: Curves.easeOutCubic,
                              ),
                        ],
                      ),
                    ),
                    _BottomCtaBar(
                      step: _step,
                      saving: _saving,
                      userIsCoach: _userIsCoach,
                      t: t,
                      onBack: () => _goTo(_step - 1),
                      onPrimary: () {
                        HapticFeedback.selectionClick();
                        if (_step == 0) {
                          if (_validateStep0()) _goTo(1);
                        } else if (_step == 1) {
                          if (_validateStep1()) _goTo(2);
                        } else {
                          _submit();
                        }
                      },
                    ),
                  ],
                ),
    );
  }
}

class _BottomCtaBar extends StatelessWidget {
  final int step;
  final bool saving;
  final bool userIsCoach;
  final String Function(String) t;
  final VoidCallback onBack;
  final VoidCallback onPrimary;

  const _BottomCtaBar({
    required this.step,
    required this.saving,
    required this.userIsCoach,
    required this.t,
    required this.onBack,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(
                color: AppColors.border.withValues(alpha: 0.8),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  if (step > 0)
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: saving ? null : onBack,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(t('become_coach_back')),
                        ),
                      ),
                    ),
                  if (step > 0) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: saving ? null : onPrimary,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                step < 2
                                    ? t('become_coach_continue')
                                    : (userIsCoach
                                        ? t('become_coach_save')
                                        : t(
                                            'become_coach_continue_payment',
                                          )),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: 16,
              color: AppColors.danger.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 240.ms)
          .slideY(begin: -0.08, curve: Curves.easeOutCubic)
          .shake(hz: 2.5, offset: const Offset(0.4, 0)),
    );
  }
}

class _ListingStatusBanner extends StatelessWidget {
  final String Function(String) t;
  final bool isActive;

  const _ListingStatusBanner({required this.t, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Icon(
                isActive ? LucideIcons.eye : LucideIcons.eyeOff,
                key: ValueKey(isActive),
                size: 18,
                color: isActive
                    ? AppColors.primaryDark
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 280),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
                child: Text(
                  isActive
                      ? t('become_coach_status_visible')
                      : t('become_coach_status_hidden'),
                ),
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 300.ms)
          .slideY(begin: -0.04),
    );
  }
}

class _ConnectedStepIndicator extends StatelessWidget {
  final int step;
  final String Function(String) t;

  const _ConnectedStepIndicator({required this.step, required this.t});

  @override
  Widget build(BuildContext context) {
    final labels = [
      t('become_coach_step_about'),
      t('become_coach_step_contact'),
      t('become_coach_step_review'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth - 28;
              final progress = step / 2;

              return SizedBox(
                height: 28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 14,
                      right: 14,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        width: trackWidth * progress,
                        height: 3,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(3, (i) {
                        final active = i == step;
                        final done = i < step;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          width: active ? 28 : 22,
                          height: active ? 28 : 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done || active
                                ? AppColors.primaryDark
                                : AppColors.surface,
                            border: Border.all(
                              color: done || active
                                  ? AppColors.primaryDark
                                  : AppColors.border,
                              width: 2,
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: done
                                ? const Icon(
                                    LucideIcons.check,
                                    size: 12,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: active
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (i) {
              final active = i == step;
              final done = i < step;
              return Expanded(
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active || done
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ProRequired extends StatelessWidget {
  final String Function(String) t;
  final VoidCallback onSubscribe;

  const _ProRequired({required this.t, required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: CoachSectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.25),
                      AppColors.primaryLight,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.badgeCheck,
                  color: AppColors.primaryDark,
                  size: 36,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.05, 1.05),
                    duration: 1400.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 20),
              Text(
                t('become_coach_pro_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.06),
              const SizedBox(height: 10),
              Text(
                t('become_coach_pro_body'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 140.ms),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onSubscribe,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(t('become_coach_get_pro')),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

InputDecoration _fieldDecoration({required String hint, Widget? prefixIcon}) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surfaceMuted,
    prefixIcon: prefixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}

class _AboutStep extends StatelessWidget {
  final String Function(String) t;
  final TextEditingController bioController;
  final TextEditingController experienceController;
  final Set<String> specialties;
  final Set<String> languages;
  final String? gender;
  final String? coachingMode;
  final ValueChanged<String> onToggleSpecialty;
  final ValueChanged<String> onToggleLanguage;
  final ValueChanged<String> onGender;
  final ValueChanged<String> onMode;

  const _AboutStep({
    required this.t,
    required this.bioController,
    required this.experienceController,
    required this.specialties,
    required this.languages,
    required this.gender,
    required this.coachingMode,
    required this.onToggleSpecialty,
    required this.onToggleLanguage,
    required this.onGender,
    required this.onMode,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        CoachSectionCard(
          title: t('become_coach_bio'),
          icon: LucideIcons.fileText,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: bioController,
                maxLines: 4,
                decoration: _fieldDecoration(
                  hint: t('become_coach_bio_hint'),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                t('become_coach_experience'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: experienceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _fieldDecoration(
                  hint: t('become_coach_experience_hint'),
                  prefixIcon: const Icon(
                    LucideIcons.award,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CoachSectionCard(
          title: t('coaches_specialty'),
          icon: LucideIcons.sparkles,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _specialtyOptions.map((s) {
              return CoachSelectTile(
                icon: coachSpecialtyIcon(s),
                label: t('coach_specialty_$s'),
                selected: specialties.contains(s),
                accent: coachSpecialtyTint(s),
                onTap: () => onToggleSpecialty(s),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        CoachSectionCard(
          title: t('become_coach_mode'),
          icon: LucideIcons.video,
          child: Row(
            children: [
              CoachModeCard(
                icon: coachModeIcon('in_person'),
                label: t('coach_mode_in_person'),
                selected: coachingMode == 'in_person',
                onTap: () => onMode('in_person'),
              ),
              const SizedBox(width: 8),
              CoachModeCard(
                icon: coachModeIcon('online'),
                label: t('coach_mode_online'),
                selected: coachingMode == 'online',
                onTap: () => onMode('online'),
              ),
              const SizedBox(width: 8),
              CoachModeCard(
                icon: coachModeIcon('both'),
                label: t('coach_mode_both'),
                selected: coachingMode == 'both',
                onTap: () => onMode('both'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CoachSectionCard(
          title: t('coaches_gender'),
          icon: LucideIcons.user,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CoachSelectTile(
                icon: LucideIcons.user,
                label: t('gender_male'),
                selected: gender == 'male',
                onTap: () => onGender('male'),
              ),
              CoachSelectTile(
                icon: LucideIcons.user,
                label: t('gender_female'),
                selected: gender == 'female',
                onTap: () => onGender('female'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CoachSectionCard(
          title: t('become_coach_languages'),
          icon: LucideIcons.languages,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _languageOptions.map((l) {
              return CoachSelectTile(
                icon: LucideIcons.languages,
                label: t('lang_name_$l'),
                selected: languages.contains(l),
                onTap: () => onToggleLanguage(l),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ContactStep extends StatelessWidget {
  final String Function(String) t;
  final TextEditingController phoneController;
  final String? city;
  final bool hasLocation;
  final VoidCallback onPickLocation;

  const _ContactStep({
    required this.t,
    required this.phoneController,
    required this.city,
    required this.hasLocation,
    required this.onPickLocation,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        CoachSectionCard(
          title: t('become_coach_phone'),
          icon: LucideIcons.phone,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: _fieldDecoration(
                  hint: t('become_coach_phone_hint'),
                  prefixIcon: const Icon(
                    LucideIcons.phone,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t('become_coach_phone_privacy'),
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CoachSectionCard(
          title: t('become_coach_location'),
          icon: LucideIcons.mapPin,
          child: CoachPressable(
            onTap: onPickLocation,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hasLocation
                    ? AppColors.primaryLight
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasLocation
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.map,
                      color: hasLocation
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasLocation
                          ? (city?.isNotEmpty == true
                              ? city!
                              : t('coaches_manual_location'))
                          : t('become_coach_pick_location'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: hasLocation
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.inactive,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final String Function(String) t;
  final String bio;
  final List<String> specialties;
  final String? gender;
  final String? mode;
  final String phone;
  final String? city;
  final List<String> languages;
  final String experience;
  final bool isActive;
  final bool isCoach;
  final bool saving;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _ReviewStep({
    required this.t,
    required this.bio,
    required this.specialties,
    required this.gender,
    required this.mode,
    required this.phone,
    required this.city,
    required this.languages,
    required this.experience,
    required this.isActive,
    required this.isCoach,
    required this.saving,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        CoachSectionCard(
          title: t('become_coach_step_review'),
          icon: LucideIcons.clipboardCheck,
          child: Column(
            children: [
              _ReviewIconRow(
                icon: LucideIcons.fileText,
                label: t('become_coach_bio'),
                value: bio,
              ),
              _ReviewIconRow(
                icon: LucideIcons.sparkles,
                label: t('coaches_specialty'),
                value: specialties
                    .map((s) => t('coach_specialty_$s'))
                    .join(', '),
              ),
              _ReviewIconRow(
                icon: LucideIcons.user,
                label: t('coaches_gender'),
                value: gender == 'female'
                    ? t('gender_female')
                    : t('gender_male'),
              ),
              if (mode != null)
                _ReviewIconRow(
                  icon: coachModeIcon(mode),
                  label: t('become_coach_mode'),
                  value: t('coach_mode_$mode'),
                ),
              if (experience.isNotEmpty)
                _ReviewIconRow(
                  icon: LucideIcons.award,
                  label: t('become_coach_experience'),
                  value: experience,
                ),
              if (languages.isNotEmpty)
                _ReviewIconRow(
                  icon: LucideIcons.languages,
                  label: t('become_coach_languages'),
                  value: languages.map((e) => t('lang_name_$e')).join(' · '),
                ),
              _ReviewIconRow(
                icon: LucideIcons.phone,
                label: t('become_coach_phone'),
                value: phone,
              ),
              _ReviewIconRow(
                icon: LucideIcons.mapPin,
                label: t('become_coach_location'),
                value: city ?? '-',
                isLast: true,
              ),
            ],
          ),
        ),
        if (isCoach) ...[
          const SizedBox(height: 12),
          _ListingToggleCard(
            t: t,
            isActive: isActive,
            saving: saving,
            onPause: onPause,
            onResume: onResume,
          ),
        ],
      ],
    );
  }
}

class _ReviewIconRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _ReviewIconRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 16, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingToggleCard extends StatelessWidget {
  final String Function(String) t;
  final bool isActive;
  final bool saving;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _ListingToggleCard({
    required this.t,
    required this.isActive,
    required this.saving,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return CoachSectionCard(
      title: t('become_coach_listing'),
      icon: isActive ? LucideIcons.eye : LucideIcons.eyeOff,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryLight
                  : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? LucideIcons.eye : LucideIcons.eyeOff,
                  size: 20,
                  color: isActive
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isActive
                        ? t('become_coach_already_active')
                        : t('become_coach_already_inactive'),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: isActive
                ? OutlinedButton.icon(
                    onPressed: saving ? null : onPause,
                    icon: const Icon(LucideIcons.eyeOff, size: 16),
                    label: Text(t('become_coach_pause')),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: saving ? null : onResume,
                    icon: const Icon(LucideIcons.eye, size: 16),
                    label: Text(t('become_coach_resume')),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
