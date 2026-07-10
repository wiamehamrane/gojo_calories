import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/event_location_selection.dart';

class EventLocationPickerSheet extends StatefulWidget {
  final EventLocationSelection? initial;

  const EventLocationPickerSheet({super.key, this.initial});

  static Future<EventLocationSelection?> show(
    BuildContext context, {
    EventLocationSelection? initial,
  }) {
    return showModalBottomSheet<EventLocationSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventLocationPickerSheet(initial: initial),
    );
  }

  @override
  State<EventLocationPickerSheet> createState() =>
      _EventLocationPickerSheetState();
}

class _EventLocationPickerSheetState extends State<EventLocationPickerSheet> {
  final _geocoding = Geocoding();
  late final TextEditingController _searchController;
  late final MapController _mapController;

  int _activeTab = 0;
  LatLng? _mapPin;
  String? _resolvedName;
  bool _isSearching = false;
  bool _isLoadingMap = true;
  bool _isResolvingPin = false;
  String? _error;
  List<_LocationResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.initial?.name ?? '',
    );
    _mapController = MapController();
    if (widget.initial?.hasCoordinates ?? false) {
      _mapPin = LatLng(widget.initial!.latitude!, widget.initial!.longitude!);
      _resolvedName = widget.initial!.name;
    }
    _initMapCenter();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String get _selectedName {
    if (_mapPin != null) {
      final resolved = _resolvedName?.trim();
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }
    return _searchController.text.trim();
  }

  bool get _canConfirm =>
      !_isResolvingPin &&
      _selectedName.isNotEmpty &&
      (_mapPin != null || _searchController.text.trim().isNotEmpty);

  Future<void> _initMapCenter() async {
    LatLng center = _mapPin ?? const LatLng(33.5731, -7.5898);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      if (await Geolocator.isLocationServiceEnabled()) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
        center = LatLng(position.latitude, position.longitude);
        if (_mapPin == null) {
          await _setMapPin(center);
        }
      }
    } catch (_) {
      // Keep fallback center.
    }

    if (!mounted) return;
    setState(() => _isLoadingMap = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(center, _mapPin == null ? 12 : 14);
    });
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _searchResults = [];
    });

    try {
      final locations = await _geocoding.locationFromAddress(query);
      final results = <_LocationResult>[];
      for (final location in locations.take(6)) {
        final placemarks = await _geocoding.placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        final label = placemarks.isNotEmpty
            ? _formatPlacemark(placemarks.first)
            : query;
        results.add(
          _LocationResult(
            name: label.isNotEmpty ? label : query,
            latitude: location.latitude,
            longitude: location.longitude,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _searchResults = results;
        if (results.isEmpty) {
          _error = 'No places found. Try a different name.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not search for that location.');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _error = null;
      _isResolvingPin = true;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission is required.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      await _setMapPin(LatLng(position.latitude, position.longitude));
      setState(() => _activeTab = 1);
      _mapController.move(_mapPin!, 15);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not get your current location.');
      }
    } finally {
      if (mounted) setState(() => _isResolvingPin = false);
    }
  }

  Future<void> _setMapPin(LatLng point) async {
    setState(() {
      _mapPin = point;
      _isResolvingPin = true;
      _error = null;
    });

    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      final name = placemarks.isNotEmpty
          ? _formatPlacemark(placemarks.first)
          : '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      if (!mounted) return;
      setState(() {
        _resolvedName = name;
        _searchController.text = name;
      });
    } catch (_) {
      if (!mounted) return;
      final fallback =
          '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      setState(() {
        _resolvedName = fallback;
        _searchController.text = fallback;
      });
    } finally {
      if (mounted) setState(() => _isResolvingPin = false);
    }
  }

  void _selectSearchResult(_LocationResult result) {
    setState(() {
      _searchController.text = result.name;
      _resolvedName = result.name;
      _mapPin = LatLng(result.latitude, result.longitude);
      _searchResults = [];
      _error = null;
      _activeTab = 1;
    });
    _mapController.move(_mapPin!, 15);
  }

  void _confirm() {
    if (!_canConfirm) {
      setState(() {
        _error = _activeTab == 1
            ? 'Tap the map to choose a location.'
            : 'Search for a place or switch to the map.';
      });
      return;
    }

    Navigator.pop(
      context,
      EventLocationSelection(
        name: _selectedName,
        latitude: _mapPin?.latitude,
        longitude: _mapPin?.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.9;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Event location',
                    style: AppTextStyles.screenTitle.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    LucideIcons.x,
                    size: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _SegmentedTabs(
              activeIndex: _activeTab,
              onChanged: (index) => setState(() => _activeTab = index),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _activeTab,
              children: [
                _buildSearchTab(),
                _buildMapTab(),
              ],
            ),
          ),
          if (_selectedName.isNotEmpty && _mapPin != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _SelectedLocationCard(
                name: _selectedName,
                isLoading: _isResolvingPin,
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              8,
              AppSpacing.screenPadding,
              bottomInset + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canConfirm ? _confirm : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  disabledBackgroundColor:
                      AppColors.primaryDark.withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: Text(
                  _isResolvingPin ? 'Finding address…' : 'Use this location',
                  style: AppTextStyles.buttonLabel.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      children: [
        Text(
          'Search by name',
          style: AppTextStyles.cardHeading.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        _FormCard(
          child: TextField(
            controller: _searchController,
            textCapitalization: TextCapitalization.sentences,
            style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
            onChanged: (_) {
              setState(() {
                _error = null;
                if (_mapPin != null &&
                    _searchController.text.trim() != (_resolvedName ?? '')) {
                  _mapPin = null;
                  _resolvedName = null;
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Park, gym, café, address…',
              hintStyle: AppTextStyles.bodyRegular.copyWith(
                color: AppColors.textPlaceholder,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _searchAddress,
                      icon: const Icon(
                        LucideIcons.search,
                        size: 20,
                        color: AppColors.primaryDark,
                      ),
                    ),
            ),
            onSubmitted: (_) => _searchAddress(),
          ),
        ),
        const SizedBox(height: 12),
        _FormCard(
          child: InkWell(
            onTap: _isResolvingPin ? null : _useCurrentLocation,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.locateFixed,
                      size: 18,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use my current location',
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
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
          ),
        ),
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Suggestions',
            style: AppTextStyles.cardHeading.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _FormCard(
            child: Column(
              children: [
                for (var i = 0; i < _searchResults.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                      indent: 52,
                    ),
                  InkWell(
                    onTap: () => _selectSearchResult(_searchResults[i]),
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
                            child: const Icon(
                              LucideIcons.mapPin,
                              size: 18,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _searchResults[i].name,
                              style: AppTextStyles.bodyBold.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMapTab() {
    if (_isLoadingMap) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryDark),
      );
    }

    final pin = _mapPin ?? const LatLng(33.5731, -7.5898);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Text(
            'Tap the map to drop a pin',
            style: AppTextStyles.cardHeading.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: AppShadows.cardShadow,
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: pin,
                  initialZoom: 14,
                  onTap: (_, point) => _setMapPin(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.gojocalories.gojocalories',
                  ),
                  if (_mapPin != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _mapPin!,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.cardElevated,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              LucideIcons.mapPin,
                              color: AppColors.primaryDark,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextButton.icon(
            onPressed: _isResolvingPin ? null : _useCurrentLocation,
            icon: const Icon(LucideIcons.locateFixed, size: 18),
            label: const Text('Center on my location'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }

  String _formatPlacemark(Placemark placemark) {
    final street = placemark.street?.trim();
    final name = placemark.name?.trim();
    final locality = placemark.locality?.trim();
    final subLocality = placemark.subLocality?.trim();
    final admin = placemark.administrativeArea?.trim();
    final country = placemark.country?.trim();

    final headline = (street != null && street.isNotEmpty)
        ? street
        : (name != null && name.isNotEmpty ? name : null);

    final city = locality ?? subLocality ?? admin;
    final parts = <String>[];
    if (headline != null && headline.isNotEmpty) parts.add(headline);
    if (city != null &&
        city.isNotEmpty &&
        !parts.any((p) => p.toLowerCase() == city.toLowerCase())) {
      parts.add(city);
    }
    if (country != null &&
        country.isNotEmpty &&
        !parts.any((p) => p.toLowerCase() == country.toLowerCase())) {
      parts.add(country);
    }

    if (parts.isEmpty) {
      return [locality, admin, country]
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .join(', ');
    }
    return parts.join(', ');
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          _tab('Search', 0),
          _tab('Map', 1),
        ],
      ),
    );
  }

  Widget _tab(String label, int index) {
    final active = activeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: active ? AppColors.primary : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.primaryDark : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedLocationCard extends StatelessWidget {
  final String name;
  final bool isLoading;

  const _SelectedLocationCard({
    required this.name,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryDark,
                    ),
                  )
                : const Icon(
                    LucideIcons.mapPin,
                    size: 20,
                    color: AppColors.primaryDark,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected location',
                  style: AppTextStyles.cardHeading.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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

class _LocationResult {
  final String name;
  final double latitude;
  final double longitude;

  const _LocationResult({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}
