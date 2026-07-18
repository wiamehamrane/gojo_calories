import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/di/repository_providers.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../events/domain/models/event_location_selection.dart';
import '../../../events/presentation/widgets/event_location_picker_sheet.dart';

const _specialtyOptions = [
  'nutrition',
  'weight_loss',
  'muscle',
  'cardio',
  'general',
];

const _languageOptions = ['fr', 'ar', 'en'];

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t('become_coach_success'))),
    );
    context.pop();
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

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(coachesRepositoryProvider);
      // Save draft profile only — listing requires payment + activate.
      await repo.upsertMe(_payload());
      if (!mounted) return;

      // Already listed: saving profile is enough.
      if (_userIsCoach && _isActive) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('become_coach_success'))),
        );
        context.pop();
        return;
      }

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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _userIsCoach ? t('become_coach_manage_title') : t('become_coach_title'),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_userHasPaid
              ? _ProRequired(
                  t: t,
                  onSubscribe: () {
                    HapticFeedback.selectionClick();
                    context.push(RoutePaths.paywall);
                  },
                )
              : Column(
                  children: [
                    _StepHeader(step: _step, t: t),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          t(_error!) == _error ? _error! : t(_error!),
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 13,
                          ),
                        ),
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
                          ),
                          _ContactStep(
                            t: t,
                            phoneController: _phoneController,
                            city: _city,
                            hasLocation: _latitude != null && _longitude != null,
                            onPickLocation: _pickLocation,
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
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(
                          children: [
                            if (_step > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _saving
                                      ? null
                                      : () => _goTo(_step - 1),
                                  child: Text(t('become_coach_back')),
                                ),
                              ),
                            if (_step > 0) const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: FilledButton(
                                onPressed: _saving
                                    ? null
                                    : () {
                                        HapticFeedback.selectionClick();
                                        if (_step == 0) {
                                          if (_validateStep0()) _goTo(1);
                                        } else if (_step == 1) {
                                          if (_validateStep1()) _goTo(2);
                                        } else {
                                          _submit();
                                        }
                                      },
                                child: _saving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _step < 2
                                            ? t('become_coach_continue')
                                            : (_userIsCoach
                                                ? t('become_coach_update')
                                                : (_hasCoachSub
                                                    ? t('become_coach_submit')
                                                    : t(
                                                        'become_coach_continue_payment',
                                                      ))),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final int step;
  final String Function(String) t;

  const _StepHeader({required this.step, required this.t});

  @override
  Widget build(BuildContext context) {
    final labels = [
      t('become_coach_step_about'),
      t('become_coach_step_contact'),
      t('become_coach_step_review'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: List.generate(3, (i) {
          final active = i == step;
          final done = i < step;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active || done
                    ? AppColors.primaryLight
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? AppColors.primary : Colors.transparent,
                ),
              ),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active || done
                      ? AppColors.primaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                LucideIcons.badgeCheck,
                color: AppColors.primaryDark,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t('become_coach_pro_title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('become_coach_pro_body'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onSubscribe,
              child: Text(t('become_coach_get_pro')),
            ),
          ],
        ),
      ),
    );
  }
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
      padding: const EdgeInsets.all(16),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('become_coach_bio'), style: _labelStyle),
              const SizedBox(height: 8),
              TextField(
                controller: bioController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: t('become_coach_bio_hint'),
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(t('become_coach_experience'), style: _labelStyle),
              const SizedBox(height: 8),
              TextField(
                controller: experienceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: t('become_coach_experience_hint'),
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('coaches_specialty'), style: _labelStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _specialtyOptions.map((s) {
                  return _Chip(
                    label: t('coach_specialty_$s'),
                    selected: specialties.contains(s),
                    onTap: () => onToggleSpecialty(s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text(t('coaches_gender'), style: _labelStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _Chip(
                    label: t('gender_male'),
                    selected: gender == 'male',
                    onTap: () => onGender('male'),
                  ),
                  _Chip(
                    label: t('gender_female'),
                    selected: gender == 'female',
                    onTap: () => onGender('female'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(t('become_coach_mode'), style: _labelStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    label: t('coach_mode_in_person'),
                    selected: coachingMode == 'in_person',
                    onTap: () => onMode('in_person'),
                  ),
                  _Chip(
                    label: t('coach_mode_online'),
                    selected: coachingMode == 'online',
                    onTap: () => onMode('online'),
                  ),
                  _Chip(
                    label: t('coach_mode_both'),
                    selected: coachingMode == 'both',
                    onTap: () => onMode('both'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(t('become_coach_languages'), style: _labelStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _languageOptions.map((l) {
                  return _Chip(
                    label: l.toUpperCase(),
                    selected: languages.contains(l),
                    onTap: () => onToggleLanguage(l),
                  );
                }).toList(),
              ),
            ],
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
      padding: const EdgeInsets.all(16),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('become_coach_phone'), style: _labelStyle),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: t('become_coach_phone_hint'),
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t('become_coach_phone_privacy'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('become_coach_location'), style: _labelStyle),
              const SizedBox(height: 8),
              Material(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onPickLocation,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 10),
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
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('become_coach_step_review'), style: _labelStyle),
              const SizedBox(height: 12),
              _ReviewLine(label: t('become_coach_bio'), value: bio),
              _ReviewLine(
                label: t('coaches_specialty'),
                value: specialties
                    .map((s) => t('coach_specialty_$s'))
                    .join(', '),
              ),
              _ReviewLine(
                label: t('coaches_gender'),
                value: gender == 'female'
                    ? t('gender_female')
                    : t('gender_male'),
              ),
              if (mode != null)
                _ReviewLine(
                  label: t('become_coach_mode'),
                  value: t('coach_mode_$mode'),
                ),
              if (experience.isNotEmpty)
                _ReviewLine(
                  label: t('become_coach_experience'),
                  value: experience,
                ),
              if (languages.isNotEmpty)
                _ReviewLine(
                  label: t('become_coach_languages'),
                  value: languages.map((e) => e.toUpperCase()).join(' · '),
                ),
              _ReviewLine(label: t('become_coach_phone'), value: phone),
              _ReviewLine(
                label: t('become_coach_location'),
                value: city ?? '-',
              ),
              if (isCoach) ...[
                const SizedBox(height: 8),
                Text(
                  isActive
                      ? t('become_coach_already_active')
                      : t('become_coach_already_inactive'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewLine extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.cardShadow,
      ),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

const _labelStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: AppColors.textSecondary,
);
