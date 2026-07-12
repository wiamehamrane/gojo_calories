import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/models/event.dart';
import '../../domain/whatsapp_link.dart';
import '../../domain/models/event_location_selection.dart';
import '../providers/events_provider.dart';
import '../widgets/event_location_picker_sheet.dart';

const _kEventTypes = [
  'Running',
  'Walking',
  'Soccer',
  'Cycling',
  'Swimming',
  'Other',
];

const _kAudiences = ['female', 'male', 'mixed'];

class EditEventScreen extends ConsumerStatefulWidget {
  final Event event;

  const EditEventScreen({super.key, required this.event});

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _maxParticipantsController;
  late final TextEditingController _customCategoryController;

  late String _eventType;
  late String _audience;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  double? _selectedLatitude;
  double? _selectedLongitude;

  bool _isSaving = false;
  String? _titleError;
  String? _categoryError;
  String? _whatsappError;

  bool get _isOtherCategory => _eventType == 'Other';

  String get _resolvedEventType => _isOtherCategory
      ? _customCategoryController.text.trim().toLowerCase()
      : _eventType.toLowerCase();

  @override
  void initState() {
    super.initState();
    final event = widget.event;

    _titleController = TextEditingController(text: event.title);
    _descriptionController =
        TextEditingController(text: event.description ?? '');
    _locationController =
        TextEditingController(text: event.locationName ?? '');
    _whatsappController =
        TextEditingController(text: event.whatsappLink ?? '');
    _maxParticipantsController = TextEditingController(
      text: event.maxParticipants?.toString() ?? '',
    );

    final knownType = _kEventTypes.firstWhere(
      (t) => t.toLowerCase() == event.eventType.toLowerCase(),
      orElse: () => 'Other',
    );
    _eventType = knownType;
    _customCategoryController = TextEditingController(
      text: knownType == 'Other' ? event.eventType : '',
    );

    _audience = _kAudiences.contains(event.audience) ? event.audience : 'mixed';
    _selectedDate = DateTime(
      event.startTime.year,
      event.startTime.month,
      event.startTime.day,
    );
    _selectedTime = TimeOfDay.fromDateTime(event.startTime);
    _selectedLatitude = event.latitude;
    _selectedLongitude = event.longitude;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _whatsappController.dispose();
    _maxParticipantsController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  DateTime get _startDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  Future<void> _pickLocation() async {
    final initial = _locationController.text.trim().isEmpty
        ? null
        : EventLocationSelection(
            name: _locationController.text.trim(),
            latitude: _selectedLatitude,
            longitude: _selectedLongitude,
          );

    final result = await EventLocationPickerSheet.show(
      context,
      initial: initial,
    );
    if (result == null || !mounted) return;

    setState(() {
      _locationController.text = result.name;
      _selectedLatitude = result.latitude;
      _selectedLongitude = result.longitude;
    });
  }

  Future<void> _pickDate() async {
    var temp = _selectedDate;
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
    var temp = DateTime(2020, 1, 1, _selectedTime.hour, _selectedTime.minute);

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

  bool _validate() {
    var valid = true;
    setState(() {
      _titleError = null;
      _categoryError = null;
      _whatsappError = null;

      if (_titleController.text.trim().isEmpty) {
        _titleError = 'Title is required';
        valid = false;
      }
      if (_isOtherCategory && _customCategoryController.text.trim().isEmpty) {
        _categoryError = 'Please write your category';
        valid = false;
      }
      final link = EventWhatsAppLink.normalize(_whatsappController.text);
      if (link.isEmpty) {
        _whatsappError = 'WhatsApp link is required';
        valid = false;
      } else if (!EventWhatsAppLink.isValid(link)) {
        _whatsappError = EventWhatsAppLink.errorMessage;
        valid = false;
      }
    });
    return valid;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    final updates = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'event_type': _resolvedEventType,
      'audience': _audience,
      'location_name': _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      if (_selectedLatitude != null) 'latitude': _selectedLatitude,
      if (_selectedLongitude != null) 'longitude': _selectedLongitude,
      'start_time': _startDateTime.toIso8601String(),
      'whatsapp_link': EventWhatsAppLink.normalize(_whatsappController.text),
      'max_participants': _maxParticipantsController.text.isNotEmpty
          ? int.tryParse(_maxParticipantsController.text)
          : null,
    };

    try {
      await ref
          .read(myEventsProvider.notifier)
          .updateEvent(widget.event.id, updates);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Event updated'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorHandler.message(e)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            LucideIcons.x,
            size: 22,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: Text(
          'Edit Event',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  8,
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
                            decoration: _inputDecoration('Event title'),
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border,
                          ),
                          TextField(
                            controller: _descriptionController,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 3,
                            minLines: 2,
                            style: AppTextStyles.bodyRegular.copyWith(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            decoration: _inputDecoration(
                              'What to expect, how to prepare…',
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ErrorLabel(_titleError),
                    const SizedBox(height: 16),
                    _SectionTitle('Category'),
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
                          decoration:
                              _inputDecoration('Write your category…'),
                        ),
                      ),
                      _ErrorLabel(_categoryError),
                    ],
                    const SizedBox(height: 16),
                    _SectionTitle('Who can attend'),
                    const SizedBox(height: 10),
                    _buildAudienceChips(),
                    const SizedBox(height: 16),
                    _SectionTitle('When & where'),
                    const SizedBox(height: 10),
                    _FormCard(
                      child: Column(
                        children: [
                          _PickerRow(
                            icon: LucideIcons.calendar,
                            label: 'Date',
                            value: DateFormat('EEE, MMM d, yyyy')
                                .format(_selectedDate),
                            onTap: _pickDate,
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border,
                            indent: 64,
                          ),
                          _PickerRow(
                            icon: LucideIcons.clock,
                            label: 'Time',
                            value: _selectedTime.format(context),
                            onTap: _pickTime,
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border,
                            indent: 64,
                          ),
                          _PickerRow(
                            icon: LucideIcons.mapPin,
                            label: 'Location',
                            value: _locationController.text.trim().isEmpty
                                ? 'Add location'
                                : _locationController.text.trim(),
                            onTap: _pickLocation,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle('Group & capacity'),
                    const SizedBox(height: 10),
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
                            style:
                                AppTextStyles.bodyBold.copyWith(fontSize: 15),
                            decoration: _iconInputDecoration(
                              'WhatsApp group link',
                              LucideIcons.messageCircle,
                            ),
                          ),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border,
                            indent: 52,
                          ),
                          TextField(
                            controller: _maxParticipantsController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style:
                                AppTextStyles.bodyBold.copyWith(fontSize: 15),
                            decoration: _iconInputDecoration(
                              'Max participants (optional)',
                              LucideIcons.users,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ErrorLabel(_whatsappError),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                8,
                AppSpacing.screenPadding,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
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
                  child: _isSaving
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          'Save Changes',
                          style: AppTextStyles.buttonLabel.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyRegular.copyWith(
        color: AppColors.textPlaceholder,
      ),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.all(16),
    );
  }

  InputDecoration _iconInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: Icon(icon, size: 18, color: AppColors.primaryDark),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      hintText: hint,
      hintStyle: AppTextStyles.bodyRegular.copyWith(
        color: AppColors.textPlaceholder,
      ),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
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
                color:
                    active ? AppColors.primaryDark : AppColors.textSecondary,
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
            padding:
                EdgeInsets.only(right: option == _kAudiences.last ? 0 : 8),
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
                    color: active
                        ? AppColors.primaryDark
                        : AppColors.textSecondary,
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
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.cardHeading.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ErrorLabel extends StatelessWidget {
  final String? error;

  const _ErrorLabel(this.error);

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Text(
        error!,
        style: TextStyle(
          color: AppColors.danger,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
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
  final VoidCallback onTap;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
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
                    style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ),
            Icon(
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
      decoration: BoxDecoration(
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
                textTheme: CupertinoTextThemeData(
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
