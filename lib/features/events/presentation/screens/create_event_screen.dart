import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/event.dart';
import '../../theme/events_theme.dart';
import '../providers/events_provider.dart';
import '../../../../core/utils/error_handler.dart';

const _kEventTypes = [
  'Running',
  'Walking',
  'Soccer',
  'Cycling',
  'Swimming',
  'Other',
];

const _kAudiences = ['female', 'male', 'mixed'];

const _kStepLabels = ['Event Details', 'Media & Links', 'Preview'];

bool _isValidWhatsAppLink(String link) {
  final trimmed = link.trim();
  if (trimmed.isEmpty) return true;
  return RegExp(r'^https?://chat\.whatsapp\.com/[a-zA-Z0-9]+$')
          .hasMatch(trimmed) ||
      RegExp(r'^https?://wa\.me/\d+').hasMatch(trimmed);
}

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _pageController = PageController();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _customCategoryController = TextEditingController();

  String _eventType = 'Running';
  String _audience = 'mixed';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _selectedImage;

  int _currentStep = 0;
  bool _isLoading = false;
  String? _titleError;
  String? _categoryError;
  String? _whatsappError;

  bool get _isOtherCategory => _eventType == 'Other';

  String get _resolvedEventType {
    if (_isOtherCategory) {
      return _customCategoryController.text.trim().toLowerCase();
    }
    return _eventType.toLowerCase();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _whatsappController.dispose();
    _maxParticipantsController.dispose();
    _customCategoryController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      final title = _titleController.text.trim();
      if (title.isEmpty) {
        setState(() => _titleError = 'Title is required');
        return;
      }
      if (_isOtherCategory && _customCategoryController.text.trim().isEmpty) {
        setState(() => _categoryError = 'Please write your category');
        return;
      }
      setState(() {
        _titleError = null;
        _categoryError = null;
      });
      if (_selectedDate == null || _selectedTime == null) {
        _showError('Please select a date and time.');
        return;
      }
    }
    if (_currentStep == 1) {
      final link = _whatsappController.text.trim();
      if (link.isEmpty) {
        setState(() => _whatsappError = 'WhatsApp link is required');
        return;
      }
      if (!_isValidWhatsAppLink(link)) {
        setState(
          () => _whatsappError =
              'Use a chat.whatsapp.com or wa.me WhatsApp link',
        );
        return;
      }
      setState(() => _whatsappError = null);
    }
    _goToStep(_currentStep + 1);
  }

  void _prevStep() {
    if (_currentStep == 0) {
      context.pop();
    } else {
      _goToStep(_currentStep - 1);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null && mounted) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  DateTime get _startDateTime => DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

  Future<void> _pickDate() async {
    var temp = _selectedDate ?? DateTime.now().add(const Duration(days: 1));
    final now = DateTime.now();
    final floor = DateTime(now.year, now.month, now.day);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CupertinoPickerSheet(
          title: 'Select date',
          onDone: () {
            setState(() => _selectedDate = temp);
            Navigator.pop(sheetContext);
          },
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: temp.isBefore(floor) ? floor : temp,
            minimumDate: floor,
            maximumDate: now.add(const Duration(days: 365)),
            onDateTimeChanged: (value) {
              HapticFeedback.selectionClick();
              temp = value;
            },
          ),
        );
      },
    );
  }

  Future<void> _pickTime() async {
    final initial = _selectedTime ?? TimeOfDay.now();
    var temp = DateTime(2020, 1, 1, initial.hour, initial.minute);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CupertinoPickerSheet(
          title: 'Select time',
          onDone: () {
            setState(() {
              _selectedTime = TimeOfDay(hour: temp.hour, minute: temp.minute);
            });
            Navigator.pop(sheetContext);
          },
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: temp,
            use24hFormat: false,
            onDateTimeChanged: (value) {
              HapticFeedback.selectionClick();
              temp = value;
            },
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final eventData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'event_type': _resolvedEventType,
      'audience': _audience,
      'location_name': _locationController.text.trim(),
      'start_time': _startDateTime.toIso8601String(),
      'whatsapp_link': _whatsappController.text.trim(),
      'max_participants': _maxParticipantsController.text.isNotEmpty
          ? int.tryParse(_maxParticipantsController.text)
          : null,
    };

    try {
      final createdEvent =
          await ref.read(eventsProvider.notifier).createEvent(eventData);

      if (createdEvent != null && _selectedImage != null) {
        try {
          await ref
              .read(eventsProvider.notifier)
              .uploadEventImage(createdEvent.id, _selectedImage!);
        } catch (e) {
          if (!mounted) return;
          _showError(
            'Event created, but the cover photo failed to upload. '
            '${AppErrorHandler.message(e)}',
          );
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      await _showSuccessSheet(createdEvent!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(AppErrorHandler.message(e));
    }
  }

  Future<void> _showSuccessSheet(Event event) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EventPublishedSheet(
        event: event,
        onInviteCircles: () {
          final date =
              DateFormat('EEE, MMM d • h:mm a').format(event.startTime);
          final location = (event.locationName?.isNotEmpty ?? false)
              ? ' at ${event.locationName}'
              : '';
          Share.share(
            'Join me for "${event.title}" on $date$location — on GojoCalories!',
          );
        },
        onDone: () => Navigator.pop(sheetContext),
      ),
    );

    if (mounted) {
      context.pop();
      _showSnack('Event posted to the world!');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3Preview(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Event',
                      style: AppTextStyles.screenTitle.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Step ${_currentStep + 1} of 3 — ${_kStepLabels[_currentStep]}',
                      style: AppTextStyles.bodyRegular.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _prevStep,
                icon: Icon(
                  _currentStep == 0 ? LucideIcons.x : LucideIcons.arrowLeft,
                  size: 22,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(3, (i) {
              final active = i <= _currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 3,
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primaryDark : AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _currentStep == 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        8,
        AppSpacing.screenPadding,
        16,
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _isLoading
              ? null
              : (isLast ? _submit : _nextStep),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryDark,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppColors.primaryDark.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  isLast
                      ? 'Publish Event'
                      : (_currentStep == 0
                          ? 'Next: Media & Links'
                          : 'Next: Preview'),
                  style: AppTextStyles.buttonLabel.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Step 1 ─────────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        24,
        AppSpacing.screenPadding,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormCard(
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) {
                    if (_titleError != null) {
                      setState(() => _titleError = null);
                    }
                  },
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Event title',
                    hintStyle: AppTextStyles.bodyRegular.copyWith(
                      color: AppColors.textPlaceholder,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.border),
                TextField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  minLines: 2,
                  style: AppTextStyles.bodyRegular.copyWith(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What to expect, how to prepare…',
                    hintStyle: AppTextStyles.bodyRegular.copyWith(
                      color: AppColors.textPlaceholder,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          if (_titleError != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                _titleError!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Category',
            style: AppTextStyles.cardHeading.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _buildCategoryChips(),
          if (_isOtherCategory) ...[
            const SizedBox(height: 12),
            _FormCard(
              child: TextField(
                controller: _customCategoryController,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) {
                  if (_categoryError != null) {
                    setState(() => _categoryError = null);
                  }
                },
                style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Write your category…',
                  hintStyle: AppTextStyles.bodyRegular.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            if (_categoryError != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _categoryError!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Text(
            'Who can attend',
            style: AppTextStyles.cardHeading.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _buildAudienceChips(),
          const SizedBox(height: 16),
          _FormCard(
            child: Column(
              children: [
                _PickerRow(
                  icon: LucideIcons.calendar,
                  label: 'Date',
                  value: _selectedDate == null
                      ? 'Select date'
                      : DateFormat('EEE, MMM d').format(_selectedDate!),
                  placeholder: _selectedDate == null,
                  onTap: _pickDate,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                  indent: 64,
                ),
                _PickerRow(
                  icon: LucideIcons.clock,
                  label: 'Time',
                  value: _selectedTime == null
                      ? 'Select time'
                      : _selectedTime!.format(context),
                  placeholder: _selectedTime == null,
                  onTap: _pickTime,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                  indent: 64,
                ),
                TextField(
                  controller: _locationController,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 12),
                      child: Icon(
                        LucideIcons.mapPin,
                        size: 18,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: 'Location',
                    hintStyle: AppTextStyles.bodyRegular.copyWith(
                      color: AppColors.textPlaceholder,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kEventTypes.map((type) {
        final active = _eventType == type;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _eventType = type;
              if (type != 'Other') {
                _categoryError = null;
                _customCategoryController.clear();
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: active ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
              ),
              boxShadow: active ? null : AppShadows.cardShadow,
            ),
            child: Text(
              type,
              style: TextStyle(
                color: active ? AppColors.primaryDark : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAudienceChips() {
    return Row(
      children: _kAudiences.map((option) {
        final active = _audience == option;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: option == _kAudiences.last ? 0 : 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _audience = option);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.border,
                  ),
                  boxShadow: active ? null : AppShadows.cardShadow,
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color:
                        active ? AppColors.primaryDark : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Step 2 ─────────────────────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        24,
        AppSpacing.screenPadding,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cover photo',
            style: AppTextStyles.cardHeading.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _buildImagePicker(),
          const SizedBox(height: 16),
          _FormCard(
            child: Column(
              children: [
                TextField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.url,
                  onChanged: (_) {
                    if (_whatsappError != null) {
                      setState(() => _whatsappError = null);
                    }
                  },
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 12),
                      child: Icon(
                        LucideIcons.messageCircle,
                        size: 18,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: 'WhatsApp link',
                    hintStyle: AppTextStyles.bodyRegular.copyWith(
                      color: AppColors.textPlaceholder,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.border,
                  indent: 52,
                ),
                TextField(
                  controller: _maxParticipantsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 12),
                      child: Icon(
                        LucideIcons.users,
                        size: 18,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: 'Max participants (optional)',
                    hintStyle: AppTextStyles.bodyRegular.copyWith(
                      color: AppColors.textPlaceholder,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_whatsappError != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                _whatsappError!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Required · chat.whatsapp.com or wa.me',
            style: AppTextStyles.bodyRegular.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_selectedImage!, fit: BoxFit.cover),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.pencil, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Change',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      LucideIcons.imagePlus,
                      size: 22,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add cover photo',
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to choose from gallery',
                    style: AppTextStyles.bodyRegular,
                  ),
                ],
              ),
      ),
    );
  }

  // ── Step 3 ─────────────────────────────────────────────────────────────
  Widget _buildStep3Preview() {
    final resolvedType = _resolvedEventType.isEmpty ? 'other' : _resolvedEventType;
    final typeColor = EventsTheme.eventTypeColor(resolvedType);
    final hasDate = _selectedDate != null && _selectedTime != null;
    final title = _titleController.text.trim().isEmpty
        ? 'Event name'
        : _titleController.text.trim();
    final typeLabel = _isOtherCategory
        ? (_customCategoryController.text.trim().isEmpty
            ? 'OTHER'
            : _customCategoryController.text.trim().toUpperCase())
        : _eventType.toUpperCase();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        24,
        AppSpacing.screenPadding,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: AppTextStyles.cardHeading.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This is how your event will look to others.',
            style: AppTextStyles.bodyRegular,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.cardShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedImage != null)
                  Image.file(
                    _selectedImage!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [typeColor, typeColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.calendar,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.chip),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(AppRadius.chip),
                            ),
                            child: Text(
                              _audience,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        style: AppTextStyles.bodyBold.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (hasDate)
                        _PreviewMeta(
                          icon: LucideIcons.calendar,
                          text: DateFormat('EEE, MMM d • h:mm a')
                              .format(_startDateTime),
                          color: typeColor,
                        ),
                      if (_locationController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _PreviewMeta(
                          icon: LucideIcons.mapPin,
                          text: _locationController.text.trim(),
                          color: typeColor,
                        ),
                      ],
                      if (_descriptionController.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          _descriptionController.text.trim(),
                          style: AppTextStyles.bodyRegular.copyWith(height: 1.5),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            disabledBackgroundColor: AppColors.primaryDark,
                            disabledForegroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.button),
                            ),
                          ),
                          child: const Text(
                            'Join now',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool placeholder;
  final VoidCallback onTap;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.cardHeading.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: placeholder
                        ? AppTextStyles.bodyRegular.copyWith(
                            color: AppColors.textPlaceholder,
                          )
                        : AppTextStyles.bodyBold.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.inactive,
            ),
          ],
        ),
      ),
    );
  }
}

class _CupertinoPickerSheet extends StatelessWidget {
  final String title;
  final VoidCallback onDone;
  final Widget child;

  const _CupertinoPickerSheet({
    required this.title,
    required this.onDone,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.bodyRegular.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 16),
                  ),
                ),
                CupertinoButton(
                  onPressed: onDone,
                  child: Text(
                    'Done',
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoTheme(
              data: CupertinoTheme.of(context).copyWith(
                primaryColor: AppColors.primaryDark,
                textTheme: const CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMeta extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _PreviewMeta({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyRegular.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _EventPublishedSheet extends StatelessWidget {
  final Event event;
  final VoidCallback onInviteCircles;
  final VoidCallback onDone;

  const _EventPublishedSheet({
    required this.event,
    required this.onInviteCircles,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = EventsTheme.eventTypeColor(event.eventType);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 28,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.circleCheck, color: typeColor, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            event.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyBold.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your event is ready. Invite your circles\nor post it to the world.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyRegular.copyWith(height: 1.45),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onInviteCircles,
              icon: const Icon(
                LucideIcons.userPlus,
                size: 18,
                color: AppColors.textPrimary,
              ),
              label: Text(
                'Invite circles',
                style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onDone,
              icon: const Icon(LucideIcons.globe, size: 18, color: Colors.white),
              label: Text(
                'Post event to the world',
                style: AppTextStyles.buttonLabel.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
