import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../screens/splash/splash.dart';
import 'app_theme.dart';

const _appInfo = MethodChannel('channeli/app_info');

class AppVersionPolicy {
  AppVersionPolicy._(this.minimumBuild, this.version, this.download);

  static const _project = String.fromEnvironment('CHECKER_STATUS_PROJECT',
      defaultValue: 'placement-apps');
  static const _database = String.fromEnvironment('CHECKER_STATUS_DATABASE',
      defaultValue: 'checker-status');

  final int minimumBuild;
  final String version;
  final Uri download;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<int> buildNumber() async =>
      (await _appInfo.invokeMethod<int>('buildNumber'))!;

  static AppVersionPolicy _parse(Map<String, dynamic> data) {
    final build = data['minimum_build'] as int;
    final version = data['version'] as String;
    final download = Uri.parse(data['download_url'] as String);
    if (build <= 0 ||
        !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version) ||
        download.scheme != 'https' ||
        download.host != 'github.com' ||
        download.userInfo.isNotEmpty ||
        !download.path.contains('/releases/download/') ||
        !download.path.endsWith('.apk')) {
      throw const FormatException('Invalid app version policy');
    }
    return AppVersionPolicy._(build, version, download);
  }

  static Future<AppVersionPolicy> fetch() async {
    final uri = Uri.https('firestore.googleapis.com',
        '/v1/projects/$_project/databases/$_database/documents/app_versions/placementv2');
    final response = await http.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      throw const FormatException('App version policy unavailable');
    }
    final fields = jsonDecode(response.body)['fields'];
    final payload = <String, dynamic>{
      'minimum_build': int.parse(fields['minimum_build']['integerValue']),
      'version': fields['version']['stringValue'],
      'download_url': fields['download_url']['stringValue'],
    };
    final policy = _parse(payload);
    await _appInfo.invokeMethod<void>(
        'writeVersionPolicy', {'policy': jsonEncode(payload)});
    return policy;
  }

  static Future<AppVersionPolicy> fetchOrCached() async {
    try {
      return await fetch();
    } catch (_) {
      final encoded = await _appInfo.invokeMethod<String>('readVersionPolicy');
      if (encoded == null) rethrow;
      return _parse(jsonDecode(encoded) as Map<String, dynamic>);
    }
  }
}

class AppVersionGate extends StatefulWidget {
  const AppVersionGate({super.key, required this.start, required this.app, required this.themeMode});

  final ThemeMode themeMode;

  final Future<void> Function() start;
  final Widget Function() app;

  @override
  State<AppVersionGate> createState() => _AppVersionGateState();
}

class _AppVersionGateState extends State<AppVersionGate> {
  bool _checking = true;
  bool _allowed = false;
  AppVersionPolicy? _required;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _error = null;
      _required = null;
    });
    try {
      if (AppVersionPolicy.isAndroid) {
        final policy = await AppVersionPolicy.fetchOrCached();
        if (await AppVersionPolicy.buildNumber() < policy.minimumBuild) {
          if (mounted) setState(() => _required = policy);
          return;
        }
      }
      await widget.start();
      if (mounted) setState(() => _allowed = true);
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = 'Could not check for updates or start the app.');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _openDownload(Uri download) async {
    try {
      if (await launchUrl(download, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _error = 'Could not open the APK download.');
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed) return widget.app();
    final required = _required;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: widget.themeMode,
      home: _checking ? const PlacementStartupScreen() : Scaffold(
        body: SafeArea(
          child: Center(
            child: AlertDialog(
                    title: Text(required == null
                        ? 'App unavailable'
                        : 'This version is no longer supported'),
                    content: Text(_error ??
                        'Install version ${required!.version} to continue.'),
                    actions: [
                      TextButton(onPressed: _check, child: const Text('Retry')),
                      if (required != null)
                        FilledButton(
                          onPressed: () => _openDownload(required.download),
                          child: const Text('Install latest version'),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
