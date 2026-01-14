import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kandangku/models/sensor_model.dart';
import 'package:kandangku/services/firebase_service.dart';
import 'package:kandangku/ui/screens/dashboard_screen.dart';
import 'package:kandangku/ui/theme/app_theme.dart';
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
        Provider<FirebaseService>(create: (_) => FirebaseService()),
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
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Dashboard PoultryVision',
        theme: AppTheme.theme, // Use Industrial-Nature theme
        home: const DashboardScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
