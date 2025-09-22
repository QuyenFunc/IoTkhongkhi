import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'features/air_monitor/viewmodels/main_viewmodel.dart';
import 'features/air_monitor/viewmodels/threshold_viewmodel.dart';
import 'features/air_monitor/screens/main_air_monitor_screen.dart';
import 'features/notifications/services/background_notification_service.dart';
import 'services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize background notification service
  final notificationService = BackgroundNotificationService();
  await notificationService.initialize();
  
  // Initialize deep link service for Google Assistant
  final deepLinkService = DeepLinkService();
  await deepLinkService.initialize();
  
  runApp(const OptimizedAirMonitorApp());
}

class OptimizedAirMonitorApp extends StatelessWidget {
  const OptimizedAirMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MainViewModel()),
        ChangeNotifierProvider(create: (_) => ThresholdViewModel()),
      ],
      child: MaterialApp(
        title: 'Air Monitor - Optimized',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: const CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const MainAirMonitorScreen(),
      ),
    );
  }
}
