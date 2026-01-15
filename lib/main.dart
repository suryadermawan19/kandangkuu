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

        // Sensor Data Stream Provider
        StreamProvider<SensorModel>(
          create: (context) => Provider.of<FirebaseService>(
            context,
            listen: false,
          ).getSensorStream(),
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
        ),
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
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    // Show login screen if not authenticated
    if (user == null) {
      return const LoginScreen();
    }

    // Show dashboard if authenticated
    return const DarkDashboardScreen();
  }
}
