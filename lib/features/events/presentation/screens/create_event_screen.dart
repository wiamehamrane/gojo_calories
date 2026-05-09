import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../providers/events_provider.dart';
import '../../theme/events_theme.dart';

const _kEventTypes = ['Running', 'Walking', 'Soccer', 'Cycling', 'Swimming', 'Other'];

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen>
    with SingleTickerProviderStateMixin {
  final _step1FormKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  late AnimationController _progressController;

  // Form state – Step 1
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _eventType = 'Running';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  // Form state – Step 2
  final _whatsappController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  File? _selectedImage;

  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 0.5, // 50% = step 1 of 2
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _whatsappController.dispose();
    _maxParticipantsController.dispose();
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
      if (_selectedDate == null || _selectedTime == null) {
        _showError('Please select a date and time.');
        return;
      }
    }
    setState(() => _currentStep = 1);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    _progressController.animateTo(1.0, curve: Curves.easeInOut);
  }

  void _prevStep() {
    setState(() => _currentStep = 0);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    _progressController.animateTo(0.5, curve: Curves.easeInOut);
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

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final eventData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'event_type': _eventType.toLowerCase(),
      'location_name': _locationController.text.trim(),
      'start_time': startDateTime.toIso8601String(),
      'whatsapp_link': _whatsappController.text.trim().isNotEmpty
          ? _whatsappController.text.trim()
          : null,
      'max_participants': _maxParticipantsController.text.isNotEmpty
          ? int.tryParse(_maxParticipantsController.text)
          : null,
    };

    final createdEvent = await ref.read(eventsProvider.notifier).createEvent(eventData);

    if (createdEvent != null && _selectedImage != null) {
      await ref.read(eventsProvider.notifier).uploadEventImage(createdEvent.id, _selectedImage!);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (createdEvent != null) {
        Navigator.pop(context);
        _showSnack('Event created successfully! 🎉');
      } else {
        _showError('Failed to create event. Please try again.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: EventsTheme.destructive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: EventsTheme.foreground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EventsTheme.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: EventsTheme.background,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: EventsTheme.pagePadding,
        right: EventsTheme.pagePadding,
        bottom: 16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _currentStep == 0 ? () => Navigator.pop(context) : _prevStep,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: EventsTheme.cardBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: EventsTheme.cardStroke),
                  ),
                  child: const Icon(LucideIcons.arrowLeft, size: 18, color: EventsTheme.foreground),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Event',
                      style: TextStyle(
                        color: EventsTheme.foreground,
                        fontFamily: EventsTheme.headingFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Step ${_currentStep + 1} of 2 — ${_currentStep == 0 ? 'Event Details' : 'Media & Links'}',
                      style: const TextStyle(
                        color: EventsTheme.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          AnimatedBuilder(
            animation: _progressController,
            builder: (_, __) {
              return Container(
                height: 4,
                decoration: BoxDecoration(
                  color: EventsTheme.cardStroke,
                  borderRadius: BorderRadius.circular(EventsTheme.chipRadius),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressController.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: EventsTheme.brandGradient,
                      borderRadius: BorderRadius.circular(EventsTheme.chipRadius),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // STEP 1 — Event Details
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: EventsTheme.pagePadding),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event title
            _buildFieldLabel('Event Title', required: true),
            _buildTextField(
              controller: _titleController,
              hint: 'e.g. Morning 5K Run',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),

            // Category chips
            _buildFieldLabel('Category', required: true),
            _buildCategoryChips(),
            const SizedBox(height: 20),

            // Date & Time
            _buildFieldLabel('Date & Time', required: true),
            Row(
              children: [
                Expanded(child: _buildDateField()),
                const SizedBox(width: 12),
                Expanded(child: _buildTimeField()),
              ],
            ),
            const SizedBox(height: 20),

            // Location
            _buildFieldLabel('Location'),
            _buildTextField(
              controller: _locationController,
              hint: 'e.g. Central Park, NYC',
              prefixIcon: LucideIcons.mapPin,
            ),
            const SizedBox(height: 20),

            // Description
            _buildFieldLabel('Description'),
            _buildTextField(
              controller: _descriptionController,
              hint: 'What to expect, how to prepare…',
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // Next button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EventsTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Next: Media & Links',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Icon(LucideIcons.arrowRight, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // STEP 2 — Media & Links
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: EventsTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image picker
          _buildFieldLabel('Event Cover Photo'),
          _buildImagePicker(),
          const SizedBox(height: 20),

          // WhatsApp group link
          _buildFieldLabel('WhatsApp Group Link'),
          _buildTextField(
            controller: _whatsappController,
            hint: 'https://chat.whatsapp.com/…',
            prefixIcon: LucideIcons.messageCircle,
            keyboardType: TextInputType.url,
            validator: (v) {
              if (v != null && v.trim().isNotEmpty) {
                if (!v.trim().startsWith('https://chat.whatsapp.com/')) {
                  return 'Must start with https://chat.whatsapp.com/';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Max participants
          _buildFieldLabel('Max Participants (Optional)'),
          _buildTextField(
            controller: _maxParticipantsController,
            hint: 'e.g. 30',
            prefixIcon: LucideIcons.users,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: EventsTheme.primaryDark,
                disabledBackgroundColor: EventsTheme.primaryDark.withValues(alpha: 0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Create Event',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Shared components
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: EventsTheme.foreground,
              fontFamily: EventsTheme.headingFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(color: EventsTheme.destructive, fontSize: 14, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: EventsTheme.foreground, fontSize: 15),
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: EventsTheme.muted, fontSize: 15),
        filled: true,
        fillColor: EventsTheme.cardBackground,
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Icon(prefixIcon, size: 18, color: EventsTheme.muted),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EventsTheme.inputRadius),
          borderSide: const BorderSide(color: EventsTheme.cardStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EventsTheme.inputRadius),
          borderSide: const BorderSide(color: EventsTheme.cardStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EventsTheme.inputRadius),
          borderSide: BorderSide(color: EventsTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EventsTheme.inputRadius),
          borderSide: BorderSide(color: EventsTheme.destructive, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EventsTheme.inputRadius),
          borderSide: BorderSide(color: EventsTheme.destructive, width: 1.5),
        ),
        errorStyle: TextStyle(color: EventsTheme.destructive, fontSize: 12),
      ),
      validator: validator,
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kEventTypes.map((type) {
        final active = _eventType == type;
        final color = EventsTheme.eventTypeColor(type);
        return GestureDetector(
          onTap: () => setState(() => _eventType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: active ? color : EventsTheme.cardBackground,
              borderRadius: BorderRadius.circular(EventsTheme.chipRadius),
              border: Border.all(
                color: active ? color : EventsTheme.cardStroke,
                width: active ? 0 : 1,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: active ? Colors.white : EventsTheme.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: EventsTheme.primary,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: EventsTheme.cardBackground,
          borderRadius: BorderRadius.circular(EventsTheme.inputRadius),
          border: Border.all(
            color: _selectedDate != null ? EventsTheme.primary : EventsTheme.cardStroke,
          ),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 16, color: _selectedDate != null ? EventsTheme.primary : EventsTheme.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'Select date'
                    : DateFormat('MMM d, yyyy').format(_selectedDate!),
                style: TextStyle(
                  color: _selectedDate == null ? EventsTheme.muted : EventsTheme.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField() {
    return GestureDetector(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: EventsTheme.primary,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (time != null) setState(() => _selectedTime = time);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: EventsTheme.cardBackground,
          borderRadius: BorderRadius.circular(EventsTheme.inputRadius),
          border: Border.all(
            color: _selectedTime != null ? EventsTheme.primary : EventsTheme.cardStroke,
          ),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.clock, size: 16, color: _selectedTime != null ? EventsTheme.primary : EventsTheme.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedTime == null ? 'Select time' : _selectedTime!.format(context),
                style: TextStyle(
                  color: _selectedTime == null ? EventsTheme.muted : EventsTheme.foreground,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: EventsTheme.cardBackground,
          borderRadius: BorderRadius.circular(EventsTheme.cardRadius),
          border: Border.all(
            color: _selectedImage != null ? EventsTheme.primary : EventsTheme.cardStroke,
            style: _selectedImage != null ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: _selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_selectedImage!, fit: BoxFit.cover),
                  // Change photo overlay
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(EventsTheme.chipRadius),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(LucideIcons.pencil, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Change',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
                      color: EventsTheme.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.imagePlus, size: 24, color: EventsTheme.primary),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Add cover photo',
                    style: TextStyle(
                      color: EventsTheme.foreground,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to choose from gallery',
                    style: TextStyle(color: EventsTheme.muted, fontSize: 13),
                  ),
                ],
              ),
      ),
    );
  }
}
