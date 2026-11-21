import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BackendStatusTile extends StatefulWidget {
  const BackendStatusTile({super.key});

  @override
  State<BackendStatusTile> createState() => _BackendStatusTileState();
}

class _BackendStatusTileState extends State<BackendStatusTile> {
  static const _project = String.fromEnvironment(
    'CHECKER_STATUS_PROJECT',
    defaultValue: 'placement-apps',
  );
  static const _database = String.fromEnvironment(
    'CHECKER_STATUS_DATABASE',
    defaultValue: 'checker-status',
  );
  static const _feed = 'placement_company';
  late final Timer _timer;
  final _client = http.Client();
  bool _checking = false;
  String _status = 'Checking backend status…';

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_checking) return;
    _checking = true;
    String status;
    try {
      final url = Uri.https('firestore.googleapis.com',
          '/v1/projects/$_project/databases/$_database/documents/checker_status/public');
      final response =
          await _client.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 404) {
        status = 'Notification backend is not up yet';
      } else if (response.statusCode != 200) {
        status = 'Could not verify notification backend status';
      } else {
        final fields = (jsonDecode(response.body) as Map)['fields'] as Map;
        final updated = DateTime.parse(fields['updated_at']['timestampValue']);
        final age = DateTime.now().toUtc().difference(updated);
        if (age > const Duration(seconds: 90)) {
          status = 'Notification backend is offline';
        } else if (fields[_feed]?['booleanValue'] != true) {
          status = 'Backend is online, but the feed is not ready';
        } else {
          status = 'Notification backend is online';
        }
      }
    } catch (_) {
      status = 'Could not verify notification backend status';
    } finally {
      _checking = false;
    }
    if (mounted) setState(() => _status = status);
  }

  @override
  void dispose() {
    _timer.cancel();
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListTile(
        leading: const Icon(Icons.cloud_outlined),
        title: Text(_status),
        trailing: IconButton(
          tooltip: 'Refresh backend status',
          icon: const Icon(Icons.refresh),
          onPressed: _refresh,
        ),
      );
}
