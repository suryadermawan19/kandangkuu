import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:kandangku/models/sensor_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  FirebaseService() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Collection and Doc references
  static const String _collectionName = 'coops';
  static const String _docId = 'kandang_01';

  // Stream of sensor data
  Stream<SensorModel> getSensorStream() {
    return _firestore.collection(_collectionName).doc(_docId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return SensorModel.fromJson(snapshot.data()!);
      } else {
        // Return default/empty model if doc doesn't exist yet
        return SensorModel(
          temperature: 0,
          humidity: 0,
          ammonia: 0,
          feedWeight: 0,
          waterLevel: 'Unknown',
          visionScore: 0,
          imagePath: '',
        );
      }
    });
  }

  // Get Latest Image URL
  Future<String?> getLatestVisionImageUrl() async {
    try {
      // Path defined in prompt: vision/latest.jpg
      String downloadUrl = await _storage
          .ref('vision/latest.jpg')
          .getDownloadURL();
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching image URL: $e');
      }
      return null;
    }
  }

  // Actuator Control (Manual Override)
  Future<void> updateActuatorState({
    bool? isFanOn,
    bool? isHeaterOn,
    bool? isAutoMode,
  }) async {
    Map<String, dynamic> updates = {};
    if (isFanOn != null) updates['fan_status'] = isFanOn;
    if (isHeaterOn != null) updates['heater_status'] = isHeaterOn;
    if (isAutoMode != null) updates['is_auto_mode'] = isAutoMode;

    if (updates.isNotEmpty) {
      await _firestore
          .collection(_collectionName)
          .doc(_docId)
          .set(updates, SetOptions(merge: true));
    }
  }

  // Initialize FCM
  Future<void> initializeFCM() async {
    // Request permission for iOS (Android 13+ also needs permission)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }
      // Subscribe to alerts topic
      await _messaging.subscribeToTopic('alerts');
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted permission');
      }
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }
      if (message.notification != null) {
        if (kDebugMode) {
          print(
            'Message also contained a notification: ${message.notification}',
          );
        }
      }
    });
  }

  // Fetch History for Chart
  Future<List<Map<String, dynamic>>> getTelemetryHistory() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('telemetry_history')
          .orderBy('last_update', descending: true)
          .limit(20) // Limit to last 20 readings for the chart
          .get();

      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching history: $e');
      }
      return [];
    }
  }
}
