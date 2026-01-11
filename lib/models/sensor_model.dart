class SensorModel {
  final double temperature;
  final double humidity;
  final double ammonia;
  final double feedWeight;
  final String waterLevel;
  final int visionScore;
  final String imagePath;
  final bool isFanOn; // Helper status if available, optional
  final bool isHeaterOn; // Helper status if available, optional
  final bool isAutoMode;

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
  });

  // Factory method to map from Firestore JSON
  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      ammonia: (json['ammonia'] as num?)?.toDouble() ?? 0.0,
      feedWeight: (json['feed_weight'] as num?)?.toDouble() ?? 0.0,
      waterLevel: json['water_level'] as String? ?? 'Unknown',
      visionScore: (json['vision_score'] as num?)?.toInt() ?? 0,
      imagePath: json['image_path'] as String? ?? '',
      // assuming auxiliary actuator status might be in the same doc or separate
      // For now defaulting to false if not in doc
      isFanOn: json['fan_status'] as bool? ?? false,
      isHeaterOn: json['heater_status'] as bool? ?? false,
      isAutoMode: json['is_auto_mode'] as bool? ?? true,
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
    };
  }
}
