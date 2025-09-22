import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FullscreenAlertScreen extends StatefulWidget {
  final String reason;
  final VoidCallback onDismiss;
  
  const FullscreenAlertScreen({
    super.key,
    required this.reason,
    required this.onDismiss,
  });

  @override
  State<FullscreenAlertScreen> createState() => _FullscreenAlertScreenState();
}

class _FullscreenAlertScreenState extends State<FullscreenAlertScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  Timer? _colorTimer;
  Color _backgroundColor = Colors.red;
  
  @override
  void initState() {
    super.initState();
    
    // Set fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Rotation animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(_rotationController);
    
    // Color alternation
    _colorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _backgroundColor = _backgroundColor == Colors.red 
            ? Colors.orange 
            : Colors.red;
      });
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _colorTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: _backgroundColor.withOpacity(0.9),
        body: SafeArea(
          child: Stack(
            children: [
              // Background pattern
              ...List.generate(
                20,
                (index) => Positioned(
                  left: (index % 5) * 80.0,
                  top: (index ~/ 5) * 150.0,
                  child: AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Icon(
                          Icons.warning,
                          size: 40,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated warning icon
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 80,
                              color: _backgroundColor,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Alert title
                    const Text(
                      'CẢNH BÁO KHẨN CẤP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Alert reason
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        widget.reason,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.5,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Dismiss button
                    GestureDetector(
                      onLongPress: () {
                        widget.onDismiss();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: _backgroundColor,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Giữ để tắt cảnh báo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Text(
                      'Chất lượng không khí vượt ngưỡng an toàn!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
