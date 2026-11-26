import 'package:flutter/material.dart';

import '../../shared/loadingPage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/wrapper', (_) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const PlacementStartupScreen();
}

class PlacementStartupScreen extends StatelessWidget {
  const PlacementStartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/applogoaspect.png', width: 100, height: 100),
                  const SizedBox(height: 8),
                  Text('Placement V2',
                      style: TextStyle(color: colors.primary, fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Column(
                children: [
                  LoadingPage(),
                  const SizedBox(height: 24),
                  Text('Updated by', style: TextStyle(color: colors.onSurfaceVariant)),
                  Text('HUKA_Taro', style: TextStyle(
                      color: colors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
