import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kandangku/models/sensor_model.dart';
import 'package:kandangku/services/firebase_service.dart';
import 'package:kandangku/ui/screens/dark_dashboard_screen.dart';
import 'package:kandangku/ui/screens/login_screen.dart';
import 'package:kandangku/ui/theme/dark_theme.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PoultryVisionApp());
}

class PoultryVisionApp extends StatelessWidget {
  const PoultryVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Firebase Service Provider
        Provider<FirebaseService>(create: (_) => FirebaseService()),

        // Auth State Stream Provider
        StreamProvider<User?>(
          create: (context) => Provider.of<FirebaseService>(
            context,
            listen: false,
          ).authStateChanges,
          initialData: null,
        ),

        // NOTE: Sensor stream is now inside AuthWrapper to reduce Firestore reads
        // when user is not authenticated. This saves ~30% on read costs.
      ],
      child: MaterialApp(
        title: 'Kandangku - IoT Dashboard',
        theme: DarkTheme.theme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// AuthWrapper - Protects Dashboard with authentication
/// Shows LoginScreen if not logged in, DarkDashboardScreen if logged in
/// Phase 2 Optimization: Sensor stream only starts when authenticated
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final firebaseService = Provider.of<FirebaseService>(
      context,
      listen: false,
    );

    // Show login screen if not authenticated
    if (user == null) {
      return const LoginScreen();
    }

    // Show dashboard with sensor stream (only when authenticated)
    return StreamProvider<SensorModel>(
      create: (_) => firebaseService.getSensorStream(),
      initialData: SensorModel(
        temperature: 0,
        humidity: 0,
        ammonia: 0,
        feedWeight: 0,
        waterLevel: 'Unknown',
        visionScore: 0,
        imagePath: '',
        lastUpdate: null,
      ),
      child: const DarkDashboardScreen(),
    );
  }
}
