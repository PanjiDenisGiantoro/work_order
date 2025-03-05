import 'package:flutter/material.dart';
import 'package:testing/splash_screen.dart'; // Import splash screen

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
  
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Splash Screen',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(), // Set SplashScreen sebagai halaman pertama
    );
  }
}
