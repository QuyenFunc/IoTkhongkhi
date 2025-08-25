import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
import '../../features/auth/pages/forgot_password_page.dart';
import '../../features/dashboard/presentation/pages/main_dashboard_page.dart';
import '../../features/user/screens/profile_setup_screen.dart';
import '../../features/user/screens/profile_screen.dart';
import '../../features/devices/screens/device_list_screen.dart';
// QR Setup Flow temporarily disabled
// import '../../features/devices/screens/qr_setup_flow_screen.dart';
import '../../features/devices/screens/device_discovery_screen.dart';
import '../../features/devices/screens/device_detail_screen.dart';
// QR Scanner temporarily disabled
// import '../../features/devices/screens/qr_scanner_screen.dart';
import '../../shared/models/device_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String devices = '/devices';
  static const String monitoring = '/monitoring';
  static const String alerts = '/alerts';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String profileSetup = '/profile-setup';
  static const String deviceDiscovery = '/device-discovery';
  static const String deviceDetail = '/device-detail';
  static const String qrScanner = '/qr-scanner';
  static const String addDevice = '/add-device';
  static const String forgotPassword = '/forgot-password';

  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginPage(),
      register: (context) => const RegisterPage(),
      forgotPassword: (context) => const ForgotPasswordPage(),
      dashboard: (context) => const MainDashboardPage(),
      profileSetup: (context) => const ProfileSetupScreen(),
      profile: (context) => const ProfileScreen(),
      devices: (context) => const DeviceListScreen(),
      deviceDiscovery: (context) => const DeviceDiscoveryScreen(),
      // QR Scanner temporarily disabled
      // qrScanner: (context) => const QRScannerScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
          settings: settings,
        );
      case register:
        return MaterialPageRoute(
          builder: (context) => const RegisterPage(),
          settings: settings,
        );
      case forgotPassword:
        return MaterialPageRoute(
          builder: (context) => const ForgotPasswordPage(),
          settings: settings,
        );
      case dashboard:
        return MaterialPageRoute(
          builder: (context) => const MainDashboardPage(),
          settings: settings,
        );
      case profileSetup:
        final args = settings.arguments as Map<String, dynamic>?;
        final isFirstTime = args?['isFirstTime'] ?? true;
        return MaterialPageRoute(
          builder: (context) => ProfileSetupScreen(isFirstTime: isFirstTime),
          settings: settings,
        );
      case profile:
        return MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
          settings: settings,
        );
      case devices:
        return MaterialPageRoute(
          builder: (context) => const DeviceListScreen(),
          settings: settings,
        );
      case deviceDiscovery:
        return MaterialPageRoute(
          builder: (context) => const DeviceDiscoveryScreen(),
          settings: settings,
        );
      case deviceDetail:
        final device = settings.arguments as DeviceModel?;
        if (device != null) {
          return MaterialPageRoute(
            builder: (context) => DeviceDetailScreen(device: device),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (context) => const DeviceListScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
          settings: settings,
        );
    }
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      login,
      (route) => false,
    );
  }

  static void navigateToRegister(BuildContext context) {
    Navigator.of(context).pushNamed(register);
  }

  static void navigateToDashboard(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      dashboard,
      (route) => false,
    );
  }

  static void navigateBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  static void navigateToDeviceDetail(BuildContext context, String deviceId) {
    Navigator.of(context).pushNamed(
      deviceDetail,
      arguments: {'deviceId': deviceId},
    );
  }
}
