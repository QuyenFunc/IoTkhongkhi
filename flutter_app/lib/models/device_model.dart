class DeviceModel {
  String? id;
  final String name;
  final String? location;
  final String? type;
  final String status;
  final int? lastSeen;
  final String? firmwareVersion;
  final String? macAddress;
  final String? ipAddress;
  final String? wifiSSID;
  final DeviceSettings? settings;
  final Map<String, dynamic>? commands;

  DeviceModel({
    this.id,
    required this.name,
    this.location,
    this.type,
    this.status = 'offline',
    this.lastSeen,
    this.firmwareVersion,
    this.macAddress,
    this.ipAddress,
    this.wifiSSID,
    this.settings,
    this.commands,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String?,
      name: json['name'] as String? ?? json['deviceName'] as String? ?? 'Unknown Device',
      location: json['location'] as String?,
      type: json['type'] as String? ?? 'air_monitor',
      status: json['status'] as String? ?? 'offline',
      lastSeen: _parseInt(json['lastSeen']),
      firmwareVersion: json['firmwareVersion'] as String?,
      macAddress: json['macAddress'] as String?,
      ipAddress: json['ipAddress'] as String?,
      wifiSSID: json['wifiSSID'] as String?,
      settings: json['settings'] != null 
          ? DeviceSettings.fromJson(Map<String, dynamic>.from(json['settings']))
          : null,
      commands: json['commands'] != null 
          ? Map<String, dynamic>.from(json['commands'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'type': type,
      'status': status,
      'lastSeen': lastSeen,
      'firmwareVersion': firmwareVersion,
      'macAddress': macAddress,
      'ipAddress': ipAddress,
      'wifiSSID': wifiSSID,
      'settings': settings?.toJson(),
      'commands': commands,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Status helpers
  bool get isOnline => status == 'online';
  bool get isOffline => status == 'offline';
  bool get isPending => status == 'pending';

  // DateTime helper
  DateTime? get lastSeenDateTime => 
      lastSeen != null ? DateTime.fromMillisecondsSinceEpoch(lastSeen! * 1000) : null;

  String get lastSeenFormatted {
    if (lastSeenDateTime == null) return 'Never';
    DateTime now = DateTime.now();
    Duration difference = now.difference(lastSeenDateTime!);
    
    if (difference.inMinutes < 1) return 'Vừa xong';
    if (difference.inMinutes < 60) return '${difference.inMinutes} phút trước';
    if (difference.inHours < 24) return '${difference.inHours} giờ trước';
    if (difference.inDays < 7) return '${difference.inDays} ngày trước';
    
    return '${lastSeenDateTime!.day}/${lastSeenDateTime!.month}/${lastSeenDateTime!.year}';
  }

  // Display helpers
  String get displayName => name.isNotEmpty ? name : 'Unknown Device';
  String get displayLocation => location?.isNotEmpty == true ? location! : 'No location';

  @override
  String toString() {
    return 'DeviceModel(id: $id, name: $name, status: $status, location: $location)';
  }

  DeviceModel copyWith({
    String? id,
    String? name,
    String? location,
    String? type,
    String? status,
    int? lastSeen,
    String? firmwareVersion,
    String? macAddress,
    String? ipAddress,
    String? wifiSSID,
    DeviceSettings? settings,
    Map<String, dynamic>? commands,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      type: type ?? this.type,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      macAddress: macAddress ?? this.macAddress,
      ipAddress: ipAddress ?? this.ipAddress,
      wifiSSID: wifiSSID ?? this.wifiSSID,
      settings: settings ?? this.settings,
      commands: commands ?? this.commands,
    );
  }
}

class DeviceSettings {
  final double? tempThreshold1;
  final double? tempThreshold2;
  final double? humiThreshold1;
  final double? humiThreshold2;
  final double? dustThreshold1;
  final double? dustThreshold2;
  final bool autoWarning;
  final int? updateInterval;

  DeviceSettings({
    this.tempThreshold1,
    this.tempThreshold2,
    this.humiThreshold1,
    this.humiThreshold2,
    this.dustThreshold1,
    this.dustThreshold2,
    this.autoWarning = false,
    this.updateInterval,
  });

  factory DeviceSettings.fromJson(Map<String, dynamic> json) {
    return DeviceSettings(
      tempThreshold1: _parseDouble(json['tempThreshold1']),
      tempThreshold2: _parseDouble(json['tempThreshold2']),
      humiThreshold1: _parseDouble(json['humiThreshold1']),
      humiThreshold2: _parseDouble(json['humiThreshold2']),
      dustThreshold1: _parseDouble(json['dustThreshold1']),
      dustThreshold2: _parseDouble(json['dustThreshold2']),
      autoWarning: json['autoWarning'] as bool? ?? false,
      updateInterval: _parseInt(json['updateInterval']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tempThreshold1': tempThreshold1,
      'tempThreshold2': tempThreshold2,
      'humiThreshold1': humiThreshold1,
      'humiThreshold2': humiThreshold2,
      'dustThreshold1': dustThreshold1,
      'dustThreshold2': dustThreshold2,
      'autoWarning': autoWarning,
      'updateInterval': updateInterval,
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Default settings
  static DeviceSettings defaultSettings() {
    return DeviceSettings(
      tempThreshold1: 18.0,  // Minimum temperature
      tempThreshold2: 28.0,  // Maximum temperature
      humiThreshold1: 40.0,  // Minimum humidity
      humiThreshold2: 70.0,  // Maximum humidity
      dustThreshold1: 35.0,  // PM2.5 warning level
      dustThreshold2: 100.0, // PM2.5 critical level
      autoWarning: true,
      updateInterval: 30,    // seconds
    );
  }

  DeviceSettings copyWith({
    double? tempThreshold1,
    double? tempThreshold2,
    double? humiThreshold1,
    double? humiThreshold2,
    double? dustThreshold1,
    double? dustThreshold2,
    bool? autoWarning,
    int? updateInterval,
  }) {
    return DeviceSettings(
      tempThreshold1: tempThreshold1 ?? this.tempThreshold1,
      tempThreshold2: tempThreshold2 ?? this.tempThreshold2,
      humiThreshold1: humiThreshold1 ?? this.humiThreshold1,
      humiThreshold2: humiThreshold2 ?? this.humiThreshold2,
      dustThreshold1: dustThreshold1 ?? this.dustThreshold1,
      dustThreshold2: dustThreshold2 ?? this.dustThreshold2,
      autoWarning: autoWarning ?? this.autoWarning,
      updateInterval: updateInterval ?? this.updateInterval,
    );
  }
}

