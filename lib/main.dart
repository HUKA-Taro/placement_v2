import 'dart:async';

import 'shared/app_version_gate.dart';
import 'package:flutter/material.dart';
import 'services/notifications/custom_push_service.dart';

import 'locator.dart';
import 'shared/app_theme.dart';
import 'services/routing/navigationService.dart';
import 'services/routing/placement_routes.dart';
import 'services/auth/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppTheme.load();
  } catch (error) {
    debugPrint('Could not load appearance settings: $error');
  }
  runApp(ValueListenableBuilder<ThemeMode>(
    valueListenable: AppTheme.mode,
    builder: (_, mode, __) => AppVersionGate(
      start: _initializeApp,
      themeMode: mode,
      app: () => MyApp(themeMode: mode),
    ),
  ));
}

Future<void> _initializeApp() async {
  // TODO: Look for more consistent method that prevent race condition when phone is sleeping
  setupLocator();
  await AuthService().initState();
  try {
    await CustomPushService.initialize();
  } catch (error) {
    debugPrint('[push] setup failed; app will continue without push: $error');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.themeMode});

  final ThemeMode themeMode;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(AuthService().reportDeviceActivityOpened());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AuthService().refreshToken();
      unawaited(AuthService().reportDeviceActivityOpened());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: locator<NavigationService>().navigatorKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: widget.themeMode,
      title: 'Placement V2',
      initialRoute: '/',
      onGenerateRoute: RouteGeneratorPlacement.getRoutes,
      debugShowCheckedModeBanner: false,
    );
  }
}
