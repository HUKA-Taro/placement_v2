import 'package:firebase_messaging/firebase_messaging.dart'
    hide NotificationSettings;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../resources/R.dart';
import 'backend_status_tile.dart';
import 'custom_push_service.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings>
    with WidgetsBindingObserver {
  static const _notifications = MethodChannel('placement_v2/notifications');
  bool _allowed = false;
  bool _permissionDialog = false;
  final _values = <String, bool>{};
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy) _load();
  }

  Future<bool> _isAllowed() async =>
      await _notifications.invokeMethod<bool>('allowed') ?? false;

  Future<void> _explainPermission() async {
    if (!mounted ||
        _permissionDialog ||
        ModalRoute.of(context)?.isCurrent != true) return;
    _permissionDialog = true;
    try {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable notifications'),
          content: const Text(
              'Allow notifications in Android settings to receive alerts.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Open Settings')),
          ],
        ),
      );
      if (openSettings == true && mounted) {
        await _notifications.invokeMethod<void>('openSettings');
      }
    } finally {
      _permissionDialog = false;
    }
  }

  Future<bool> _requestPermission() async {
    if (!await _isAllowed()) {
      await FirebaseMessaging.instance.requestPermission();
    }
    _allowed = await _isAllowed();
    if (!_allowed) await _explainPermission();
    return _allowed;
  }

  Future<void> _testNotification() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await _requestPermission() || !mounted) return;
      await _notifications.invokeMethod<void>('show', {
        'title': 'Placement test notification',
        'body': 'This notification was sent by the app.',
      });
    } catch (_) {
      _error = 'Could not display the test notification.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      _allowed = await _isAllowed();
      _error = null;
      for (final topic in CustomPushService.topics.keys) {
        _values[topic] = await CustomPushService.enabled(topic);
      }
      if (!_allowed) await _explainPermission();
    } catch (_) {
      _error =
          'Could not load notification settings. Reopen this screen to retry.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _update(String topic, bool value) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (value && !await _requestPermission()) return;
      await CustomPushService.setEnabled(topic, value);
      _values[topic] = value;
    } catch (_) {
      _error = 'Could not sync with Firebase. Try again or reopen the app.';
      try {
        _values[topic] = await CustomPushService.enabled(topic);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: R.primaryCol,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('Notification settings'),
        ),
        body: ListView(
          children: [
            for (final entry in CustomPushService.topics.entries)
              SwitchListTile(
                title: Text(entry.value,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                activeThumbColor: R.primaryCol,
                contentPadding: const EdgeInsets.fromLTRB(24, 5, 24, 5),
                value: _allowed && (_values[entry.key] ?? false),
                onChanged: _busy || !_values.containsKey(entry.key)
                    ? null
                    : (value) => _update(entry.key, value),
              ),
            const BackendStatusTile(),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Send test notification'),
              onTap: _busy ? null : _testNotification,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
          ],
        ),
      );
}
