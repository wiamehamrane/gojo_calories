class EventLocationSelection {
  final String name;
  final double? latitude;
  final double? longitude;

  const EventLocationSelection({
    required this.name,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
}
