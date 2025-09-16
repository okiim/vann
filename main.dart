import 'package:flutter/material.dart';
import 'dashboard_page.dart';

void main() {
  runApp(const LibrarySystemApp());
}

class LibrarySystemApp extends StatelessWidget {
  const LibrarySystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Library Management System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
        ),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}