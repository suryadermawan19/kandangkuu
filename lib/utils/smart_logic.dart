import 'package:kandangku/models/sensor_model.dart';

class SmartLogic {
  // Hysteresis configuration
  static const double _hysteresisBufferTemp = 2.0; // degrees
  static const double _hysteresisBufferAmmonia = 2.0; // ppm
  static const Duration _minRunTime = Duration(minutes: 5);

  // State to track last toggle time to prevent rapid switching
  DateTime? _lastFanToggleTime;
  DateTime? _lastHeaterToggleTime;

  bool shouldTurnOnFan(SensorModel data, bool currentFanState) {
    // Critical conditions
    bool needsFan = data.ammonia > 20 || data.temperature > 30;

    // Hysteresis Logic
    if (currentFanState) {
      // If currently ON, only turn OFF if we are well below the threshold (buffer)
      // i.e., ammonia < (20 - 2) AND temperature < (30 - 2)
      bool safeToTurnOff =
          data.ammonia < (20 - _hysteresisBufferAmmonia) &&
          data.temperature < (30 - _hysteresisBufferTemp);

      if (safeToTurnOff && _hasMinRunTimePassed(_lastFanToggleTime)) {
        _lastFanToggleTime = DateTime.now();
        return false; // Turn OFF
      }
      return true; // Keep ON
    } else {
      // If currently OFF, turn ON if we hit the critical threshold
      if (needsFan && _hasMinRunTimePassed(_lastFanToggleTime)) {
        _lastFanToggleTime = DateTime.now();
        return true; // Turn ON
      }
      return false; // Keep OFF
    }
  }

  bool shouldTurnOnHeater(SensorModel data, bool currentHeaterState) {
    // Critical conditions: Cold temp or chickens huddling (vision score < 40)
    bool needsHeater = data.temperature < 24 || data.visionScore < 40;

    if (currentHeaterState) {
      // If currently ON, only turn OFF if we are well above threshold
      // i.e., temp > (24 + 2) AND vision score is healthy (> 40)

      // Vision score doesn't really have a strict buffer defined in prompt "buffer zone of 2 degrees/ppm",
      // but we can assume once vision score improves significantly.
      // Let's rely mainly on Temp buffer for heater off, and Vision Score > 45 maybe?
      // For simplicity, sticking to Temp buffer and non-critical vision.

      bool safeToTurnOff =
          data.temperature > (24 + _hysteresisBufferTemp) &&
          data.visionScore >= 40;

      if (safeToTurnOff && _hasMinRunTimePassed(_lastHeaterToggleTime)) {
        _lastHeaterToggleTime = DateTime.now();
        return false; // Turn OFF
      }
      return true; // Keep ON
    } else {
      if (needsHeater && _hasMinRunTimePassed(_lastHeaterToggleTime)) {
        _lastHeaterToggleTime = DateTime.now();
        return true; // Turn ON
      }
      return false; // Keep OFF
    }
  }

  bool _hasMinRunTimePassed(DateTime? lastToggle) {
    if (lastToggle == null) return true;
    return DateTime.now().difference(lastToggle) >= _minRunTime;
  }
}
