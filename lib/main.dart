import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kandangku/models/sensor_model.dart';
import 'package:kandangku/services/firebase_service.dart';
import 'package:kandangku/ui/screens/dark_dashboard_screen.dart';
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
            lastUpdate:
                null, // Will show "loading" state until first data arrives
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Kandangku - IoT Dashboard',
        theme: DarkTheme.theme, // Industrial Green Dark Theme
        home: const DarkDashboardScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
