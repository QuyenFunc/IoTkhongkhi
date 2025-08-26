import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/widgets/auth_wrapper.dart';
import 'core/routes/app_routes.dart';
import 'core/firebase/firebase_initializer.dart';
import 'utils/firebase_config_validator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 APP STARTING - Main function called');

  // Initialize Firebase with proper region configuration
  try {
    print('🚀 Initializing Firebase...');
    await FirebaseInitializer.initialize();

    // Validate Firebase configuration in debug mode
    FirebaseConfigValidator.quickCheck();

    // Print configuration info for debugging
    FirebaseInitializer.printConfigInfo();

    // Validate database URL
    final isValidURL = FirebaseInitializer.validateDatabaseURL();
    if (!isValidURL) {
      print('⚠️ Warning: Database URL validation failed');
    }
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue running the app even if Firebase fails to initialize
  }

  // TODO: Initialize Hive for local storage later
  // await Hive.initFlutter();

  // TODO: Open Hive boxes later
  // await Hive.openBox(HiveBoxes.userBox);
  // await Hive.openBox(HiveBoxes.deviceBox);
  // await Hive.openBox(HiveBoxes.sensorDataBox);
  // await Hive.openBox(HiveBoxes.settingsBox);
  // await Hive.openBox(HiveBoxes.cacheBox);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  print('🚀 Starting AirQualityApp...');
  runApp(const AirQualityApp());
}

class AirQualityApp extends StatelessWidget {
  const AirQualityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AirQuality',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const AuthWrapper(),
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

class SimpleSplashPage extends StatefulWidget {
  const SimpleSplashPage({super.key});

  @override
  State<SimpleSplashPage> createState() => _SimpleSplashPageState();
}

class _SimpleSplashPageState extends State<SimpleSplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // Start animation
    _animationController.forward();

    // Navigate to login after delay
    _navigateToLogin();
  }

  void _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.air,
                        size: 60,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // App Title
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'AirQuality',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Subtitle
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Giám sát chất lượng không khí thông minh',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),

            const SizedBox(height: 80),

            // Loading indicator
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


