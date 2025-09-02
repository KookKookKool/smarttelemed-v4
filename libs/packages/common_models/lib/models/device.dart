// Device Data Model
enum DeviceType {
  bloodPressure,
  pulseOximeter,
  thermometer,
  glucometer,
  scale,
}

enum DeviceStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final String macAddress;
  final DeviceStatus status;
  final DateTime? lastConnected;
  final String manufacturer;
  final String model;

  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.macAddress,
    required this.status,
    this.lastConnected,
    required this.manufacturer,
    required this.model,
  });

  // Convert Device to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'macAddress': macAddress,
        'status': status.name,
        'lastConnected': lastConnected?.toIso8601String(),
        'manufacturer': manufacturer,
        'model': model,
      };

  // Create Device from JSON
  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'],
        name: json['name'],
        type: DeviceType.values.firstWhere((e) => e.name == json['type']),
        macAddress: json['macAddress'],
        status: DeviceStatus.values.firstWhere((e) => e.name == json['status']),
        lastConnected: json['lastConnected'] != null
            ? DateTime.parse(json['lastConnected'])
            : null,
        manufacturer: json['manufacturer'],
        model: json['model'],
      );

  // Copy with modifications
  Device copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? macAddress,
    DeviceStatus? status,
    DateTime? lastConnected,
    String? manufacturer,
    String? model,
  }) =>
      Device(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        macAddress: macAddress ?? this.macAddress,
        status: status ?? this.status,
        lastConnected: lastConnected ?? this.lastConnected,
        manufacturer: manufacturer ?? this.manufacturer,
        model: model ?? this.model,
      );

  // Check if device is connected
  bool get isConnected => status == DeviceStatus.connected;

  // Get device type display name
  String get typeDisplayName {
    switch (type) {
      case DeviceType.bloodPressure:
        return 'Blood Pressure Monitor';
      case DeviceType.pulseOximeter:
        return 'Pulse Oximeter';
      case DeviceType.thermometer:
        return 'Thermometer';
      case DeviceType.glucometer:
        return 'Glucometer';
      case DeviceType.scale:
        return 'Scale';
    }
  }
}