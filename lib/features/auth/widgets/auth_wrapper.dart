import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../presentation/pages/login_page.dart';
import '../../dashboard/presentation/pages/main_dashboard_page.dart';
import '../../devices/services/device_pairing_service.dart';

/// Authentication wrapper that handles user authentication state
/// and routes users to appropriate screens based on their auth status
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show error if there's an error
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi xác thực',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đã xảy ra lỗi khi kiểm tra trạng thái đăng nhập',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Restart the app or navigate to login
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }

        // Check if user is signed in
        final User? user = snapshot.data;
        
        if (user != null) {
          // User is signed in, show dashboard with device pairing service
          return const DevicePairingWrapper(
            child: MainDashboardPage(),
          );
        } else {
          // User is not signed in, show login page
          return const LoginPage();
        }
      },
    );
  }
}

/// Authentication state provider for the entire app
class AuthStateProvider extends StatelessWidget {
  final Widget child;

  const AuthStateProvider({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return child;
      },
    );
  }
}

/// Device Pairing Service Wrapper
/// Manages DevicePairingService lifecycle based on user authentication
class DevicePairingWrapper extends StatefulWidget {
  final Widget child;

  const DevicePairingWrapper({
    super.key,
    required this.child,
  });

  @override
  State<DevicePairingWrapper> createState() => _DevicePairingWrapperState();
}

class _DevicePairingWrapperState extends State<DevicePairingWrapper> {
  final DevicePairingService _pairingService = DevicePairingService();

  @override
  void initState() {
    super.initState();
    _startPairingService();
  }

  @override
  void dispose() {
    _pairingService.dispose();
    super.dispose();
  }

  void _startPairingService() async {
    // Note: Device pairing service now uses user-specific listeners
    // Started when needed in device setup screen
    try {
      if (kDebugMode) {
        print('🔗 Device pairing service ready');
      }
    } catch (e) {
      if (mounted) {
        debugPrint('❌ Failed to start device pairing service: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Helper widget to show user info in debug mode
class UserInfoDebugWidget extends StatelessWidget {
  const UserInfoDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        
        if (user == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Debug: User Info',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'UID: ${user.uid}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Email: ${user.email ?? 'N/A'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Name: ${user.displayName ?? 'N/A'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Verified: ${user.emailVerified}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
