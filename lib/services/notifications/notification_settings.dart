import 'package:flutter/material.dart';

import '../../resources/R.dart';
import 'backend_status_tile.dart';
import 'custom_push_service.dart';

class NotificationSettings extends StatefulWidget {
  const NotificationSettings({super.key});

  @override
  State<NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<NotificationSettings> {
  final _values = <String, bool>{};
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      for (final topic in CustomPushService.topics.keys) {
        _values[topic] = await CustomPushService.enabled(topic);
      }
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
            const BackendStatusTile(),
            for (final entry in CustomPushService.topics.entries)
              SwitchListTile(
                title: Text(entry.value,
                    style: TextStyle(color: R.textColPrimary)),
                activeThumbColor: R.primaryCol,
                contentPadding: const EdgeInsets.fromLTRB(24, 5, 24, 5),
                value: _values[entry.key] ?? false,
                onChanged: _busy || !_values.containsKey(entry.key)
                    ? null
                    : (value) => _update(entry.key, value),
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
