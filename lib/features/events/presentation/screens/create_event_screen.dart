import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/events_provider.dart';
import '../../theme/events_theme.dart';
import 'package:intl/intl.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _eventType = 'Running';
  String _locationName = '';
  String _whatsappLink = '';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select date and time')));
      return;
    }

    _formKey.currentState!.save();
    
    setState(() { _isLoading = true; });

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final eventData = {
      'title': _title,
      'description': _description,
      'event_type': _eventType.toLowerCase(),
      'location_name': _locationName,
      'start_time': startDateTime.toIso8601String(),
      'whatsapp_link': _whatsappLink.isEmpty ? null : _whatsappLink,
    };

    final success = await ref.read(eventsProvider.notifier).createEvent(eventData);

    setState(() { _isLoading = false; });

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event created successfully!')));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create event.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EventsTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: EventsTheme.darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: EventsTheme.darkForeground),
        title: const Text('Create Event', style: TextStyle(color: EventsTheme.darkForeground, fontFamily: EventsTheme.headingFont)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Event Title'),
              _buildTextField(
                hint: 'e.g. Morning 5K Run',
                onSaved: (val) => _title = val!,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              _buildLabel('Description'),
              _buildTextField(
                hint: 'What to expect...',
                maxLines: 3,
                onSaved: (val) => _description = val!,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Category'),
                        _buildDropdown(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildLabel('Date & Time'),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: EventsTheme.darkCardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: EventsTheme.darkCardStroke),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.calendar, color: EventsTheme.darkMuted, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDate == null ? 'Select Date' : DateFormat('MMM d, yyyy').format(_selectedDate!),
                              style: TextStyle(color: _selectedDate == null ? EventsTheme.darkMuted : EventsTheme.darkForeground),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) setState(() => _selectedTime = time);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: EventsTheme.darkCardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: EventsTheme.darkCardStroke),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.clock, color: EventsTheme.darkMuted, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _selectedTime == null ? 'Time' : _selectedTime!.format(context),
                              style: TextStyle(color: _selectedTime == null ? EventsTheme.darkMuted : EventsTheme.darkForeground),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildLabel('Location'),
              _buildTextField(
                hint: 'e.g. Central Park',
                onSaved: (val) => _locationName = val ?? '',
              ),
              const SizedBox(height: 24),

              _buildLabel('WhatsApp Group Link (Optional)'),
              _buildTextField(
                hint: 'https://chat.whatsapp.com/...',
                onSaved: (val) => _whatsappLink = val ?? '',
                validator: (val) {
                  if (val != null && val.isNotEmpty) {
                    if (!val.startsWith('https://chat.whatsapp.com/')) {
                      return 'Must be a valid WhatsApp group link';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EventsTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'Launch Event',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: EventsTheme.darkForeground,
          fontFamily: EventsTheme.headingFont,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    int maxLines = 1,
    required void Function(String?) onSaved,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      style: const TextStyle(color: EventsTheme.darkForeground),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: EventsTheme.darkMuted),
        filled: true,
        fillColor: EventsTheme.darkCardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: EventsTheme.darkCardStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: EventsTheme.darkCardStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: EventsTheme.primary),
        ),
      ),
      onSaved: onSaved,
      validator: validator,
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: EventsTheme.darkCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EventsTheme.darkCardStroke),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _eventType,
          dropdownColor: EventsTheme.darkCardBackground,
          icon: Icon(LucideIcons.chevronDown, color: EventsTheme.darkMuted),
          isExpanded: true,
          style: const TextStyle(color: EventsTheme.darkForeground, fontSize: 16),
          items: ['Running', 'Walking', 'Soccer', 'Cycling', 'Other'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _eventType = val);
          },
        ),
      ),
    );
  }
}
