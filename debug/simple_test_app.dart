import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_debug_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with your config
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDL1iwM9wuJzg2fw2mP-aIM69Y16fU6Kdg",
      authDomain: "iotsmart-7a145.firebaseapp.com",
      databaseURL: "https://iotsmart-7a145-default-rtdb.asia-southeast1.firebasedatabase.app",
      projectId: "iotsmart-7a145",
      storageBucket: "iotsmart-7a145.appspot.com",
      messagingSenderId: "1065572269710",
      appId: "1:1065572269710:web:abc123def456",
    ),
  );
  
  runApp(const SimpleTestApp());
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Data Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const FirebaseDebugScreen(),
    );
  }
}
