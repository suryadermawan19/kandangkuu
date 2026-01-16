import 'package:cloud_firestore/cloud_firestore.dart';

class SensorModel {
  final double temperature;
  final double humidity;
  final double ammonia;
  final double feedWeight;
  final String waterLevel;
  final int visionScore;
  final String imagePath;
  final bool isFanOn;
  final bool isHeaterOn;
  final bool isAutoMode;

  // Servo automation states
  final bool servoPakanTrigger;
  final bool servoAirTrigger;

  // UX Fix #1: Connectivity tracking
  final DateTime? lastUpdate;

  // Offline resilience
  final bool isFromCache;

  // Default threshold: data older than 5 minutes = stale
  static const int staleThresholdMinutes = 5;

  SensorModel({
    required this.temperature,
    required this.humidity,
    required this.ammonia,
    required this.feedWeight,
    required this.waterLevel,
    required this.visionScore,
    required this.imagePath,
    this.isFanOn = false,
    this.isHeaterOn = false,
    this.isAutoMode = true,
    this.servoPakanTrigger = false,
    this.servoAirTrigger = false,
    this.lastUpdate,
    this.isFromCache = false,
  });

  /// Check if sensor data is stale (older than threshold)
  bool get isStale {
    if (lastUpdate == null) return true;
    final difference = DateTime.now().difference(lastUpdate!);
    return difference.inMinutes >= staleThresholdMinutes;
  }

  /// Check if device is online (data updated within threshold)
  bool get isOnline => !isStale;

  /// Human-readable time since last update
  String get timeSinceUpdate {
    if (lastUpdate == null) return 'Belum ada data';

    final difference = DateTime.now().difference(lastUpdate!);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j lalu';
    } else {
      return '${difference.inDays}h lalu';
    }
  }

  // Factory method to map from Firestore JSON
  // Now accepts optional isFromCache parameter
  factory SensorModel.fromJson(
    Map<String, dynamic> json, {
    bool isFromCache = false,
  }) {
    // Parse timestamp from Firestore
    DateTime? parsedTimestamp;
    if (json['last_update'] != null) {
      if (json['last_update'] is Timestamp) {
        parsedTimestamp = (json['last_update'] as Timestamp).toDate();
      } else if (json['last_update'] is int) {
        parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(
          json['last_update'],
        );
      }
    }

    return SensorModel(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      ammonia: (json['ammonia'] as num?)?.toDouble() ?? 0.0,
      feedWeight: (json['feed_weight'] as num?)?.toDouble() ?? 0.0,
      waterLevel: json['water_level'] as String? ?? 'Unknown',
      visionScore: (json['vision_score'] as num?)?.toInt() ?? 0,
      imagePath: json['image_path'] as String? ?? '',
      isFanOn: json['fan_status'] as bool? ?? false,
      isHeaterOn: json['heater_status'] as bool? ?? false,
      isAutoMode: json['is_auto_mode'] as bool? ?? true,
      servoPakanTrigger: json['servo_pakan_trigger'] as bool? ?? false,
      servoAirTrigger: json['servo_air_trigger'] as bool? ?? false,
      lastUpdate: parsedTimestamp,
      isFromCache: isFromCache,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'ammonia': ammonia,
      'feed_weight': feedWeight,
      'water_level': waterLevel,
      'vision_score': visionScore,
      'image_path': imagePath,
      'fan_status': isFanOn,
      'heater_status': isHeaterOn,
      'is_auto_mode': isAutoMode,
      'servo_pakan_trigger': servoPakanTrigger,
      'servo_air_trigger': servoAirTrigger,
      'last_update': lastUpdate != null
          ? Timestamp.fromDate(lastUpdate!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated actuator states (for optimistic updates)
  SensorModel copyWith({
    double? temperature,
    double? humidity,
    double? ammonia,
    double? feedWeight,
    String? waterLevel,
    int? visionScore,
    String? imagePath,
    bool? isFanOn,
    bool? isHeaterOn,
    bool? isAutoMode,
    bool? servoPakanTrigger,
    bool? servoAirTrigger,
    DateTime? lastUpdate,
    bool? isFromCache,
  }) {
    return SensorModel(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      ammonia: ammonia ?? this.ammonia,
      feedWeight: feedWeight ?? this.feedWeight,
      waterLevel: waterLevel ?? this.waterLevel,
      visionScore: visionScore ?? this.visionScore,
      imagePath: imagePath ?? this.imagePath,
      isFanOn: isFanOn ?? this.isFanOn,
      isHeaterOn: isHeaterOn ?? this.isHeaterOn,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      servoPakanTrigger: servoPakanTrigger ?? this.servoPakanTrigger,
      servoAirTrigger: servoAirTrigger ?? this.servoAirTrigger,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}
