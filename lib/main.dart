import 'package:flutter/material.dart';
import 'login_screen.dart';

void main() => runApp(const BarTillApp());

class BarTillApp extends StatelessWidget {
  const BarTillApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bar Till',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.amber, useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}