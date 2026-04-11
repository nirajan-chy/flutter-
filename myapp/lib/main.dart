import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'core/network/api_client.dart';
import 'core/services/notification_service.dart';
import 'screen/dashboard/dashboard.dart';
import 'screen/welcome/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _home = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    await ApiClient.hydrateTokenFromStorage();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;
    setState(() {
      _home = token != null && token.isNotEmpty
          ? const DashboardScreen()
          : const WelcomeScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _home,
    );
  }
}
