import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kandangku/models/sensor_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseService() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Collection and Doc references
  static const String _collectionName = 'coops';
  static const String _docId = 'kandang_01';

  // ============ AUTH METHODS ============

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  /// Returns null on success, error message string on failure
  Future<String?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Ensure user document exists with default role
      if (userCredential.user != null) {
        await _ensureUserDocument(userCredential.user!);
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      // Return user-friendly error messages in Bahasa Indonesia
      switch (e.code) {
        case 'user-not-found':
          return 'Email tidak terdaftar';
        case 'wrong-password':
          return 'Password salah';
        case 'invalid-email':
          return 'Format email tidak valid';
        case 'user-disabled':
          return 'Akun telah dinonaktifkan';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi nanti';
        case 'invalid-credential':
          return 'Email atau password salah';
        default:
          return e.message ?? 'Terjadi kesalahan. Coba lagi';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sign in error: $e');
      }
      return 'Terjadi kesalahan. Coba lagi';
    }
  }

  /// Ensure user document exists in 'users' collection
  Future<void> _ensureUserDocument(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      // Create new user doc with default 'viewer' role
      // For the VERY first user (or if you want to hardcode specific emails as admin),
      // you can add logic here. For now, default to viewer for safety.
      await userRef.set({
        'email': user.email,
        'role': 'viewer', // 'admin' or 'viewer'
        'created_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
      });
    } else {
      // Update last login
      await userRef.update({'last_login': FieldValue.serverTimestamp()});
    }
  }

  /// Stream of user role ('admin' or 'viewer')
  Stream<String> getUserRoleStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value('viewer');

    return _firestore.collection('users').doc(user.uid).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) {
        // Self-healing: Create document if missing
        _ensureUserDocument(user);
        return 'viewer';
      }
      return snapshot.data()?['role'] as String? ?? 'viewer';
    });
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  /// Returns null on success, error message string on failure
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'Email tidak terdaftar';
        case 'invalid-email':
          return 'Format email tidak valid';
        default:
          return e.message ?? 'Terjadi kesalahan. Coba lagi';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Password reset error: $e');
      }
      return 'Terjadi kesalahan. Coba lagi';
    }
  }

  // ============ CONFIG METHODS ============

  /// Stream of threshold configuration
  Stream<Map<String, dynamic>> getConfigStream() {
    return _firestore.collection('config').doc('thresholds').snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data()!;
      } else {
        // Return defaults if document doesn't exist
        return {'max_temperature': 30.0, 'max_ammonia': 20.0};
      }
    });
  }

  /// Update threshold configuration
  Future<void> updateThresholds(double maxTemp, double maxAmmonia) async {
    await _firestore.collection('config').doc('thresholds').set({
      'max_temperature': maxTemp,
      'max_ammonia': maxAmmonia,
    }, SetOptions(merge: true));
  }

  /// Update feed threshold configuration for servo automation (in grams)
  Future<void> updateFeedThreshold(double minFeedThreshold) async {
    await _firestore.collection('config').doc('thresholds').set({
      'min_feed_threshold': minFeedThreshold,
    }, SetOptions(merge: true));
  }

  // ============ MANUAL SERVO TRIGGERS ============

  /// Trigger manual feed dispensing (one-press trigger)
  /// Returns true on success, false on failure
  /// Includes timestamp for Cloud Functions timeout detection
  Future<bool> triggerManualFeed() async {
    try {
      await _firestore.collection(_collectionName).doc(_docId).set({
        'servo_pakan_trigger': true,
        'servo_pakan_timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      if (kDebugMode) print('Error triggering manual feed: $e');
      return false;
    }
  }

  /// Trigger manual water dispensing (one-press trigger)
  /// Returns true on success, false on failure
  /// Includes timestamp for Cloud Functions timeout detection
  Future<bool> triggerManualWater() async {
    try {
      await _firestore.collection(_collectionName).doc(_docId).set({
        'servo_air_trigger': true,
        'servo_air_timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      if (kDebugMode) print('Error triggering manual water: $e');
      return false;
    }
  }

  // ============ SENSOR DATA METHODS ============

  // Stream of sensor data
  Stream<SensorModel> getSensorStream() {
    return _firestore
        .collection(_collectionName)
        .doc(_docId)
        .snapshots(includeMetadataChanges: true) // Detect offline/cache data
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return SensorModel.fromJson(
              snapshot.data()!,
              isFromCache: snapshot.metadata.isFromCache,
            );
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

  /// Resolve Firebase Storage path to download URL
  /// Handles: full URLs (returns as-is), storage paths (resolves to URL)
  Future<String?> getImageUrl(String imagePath) async {
    if (imagePath.isEmpty) return null;

    // Already a full URL - return as-is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // It's a Storage path - resolve to download URL
    try {
      final ref = _storage.ref().child(imagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      if (kDebugMode) {
        print('Error resolving image URL for $imagePath: $e');
      }
      return null;
    }
  }

  // Actuator Control (Manual Override)
  /// Returns true on success, false on failure
  Future<bool> updateActuatorState({
    bool? isFanOn,
    bool? isHeaterOn,
    bool? isAutoMode,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (isFanOn != null) updates['is_fan_on'] = isFanOn;
      if (isHeaterOn != null) updates['is_heater_on'] = isHeaterOn;
      if (isAutoMode != null) updates['is_auto_mode'] = isAutoMode;

      if (updates.isNotEmpty) {
        await _firestore
            .collection(_collectionName)
            .doc(_docId)
            .set(updates, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating actuator state: $e');
      return false;
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

  // Fetch History for Chart (legacy - limited to 20)
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

  /// Fetch telemetry history for a given time range
  /// [hours] - Number of hours to look back (24, 168 for 7 days, 720 for 30 days)
  /// Returns data ordered chronologically (oldest first) for chart plotting
  Future<List<Map<String, dynamic>>> getTelemetryHistoryForRange(
    int hours,
  ) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(hours: hours));
      final cutoffTimestamp = Timestamp.fromDate(cutoff);

      QuerySnapshot snapshot = await _firestore
          .collection('telemetry_history')
          .where('last_update', isGreaterThanOrEqualTo: cutoffTimestamp)
          .orderBy('last_update', descending: false) // Oldest first for charts
          .limit(200) // Reasonable limit for chart performance
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Ensure timestamp is included for x-axis calculations
        return {
          ...data,
          'timestamp': (data['last_update'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching history for range ($hours hours): $e');
      }
      return [];
    }
  }
}
