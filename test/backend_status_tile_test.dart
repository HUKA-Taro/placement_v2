import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:placement/services/notifications/backend_status_tile.dart';

void main() {
  final cases = [
    (200, 5, true, 'Notification backend is online'),
    (200, 5, false, 'Backend is online, but the feed is not ready'),
    (200, 120, true, 'Notification backend is offline'),
    (404, 0, false, 'Notification backend is not up yet'),
    (503, 0, false, 'Could not verify notification backend status'),
  ];

  for (final (status, age, healthy, label) in cases) {
    testWidgets(label, (tester) async {
      final client = MockClient((request) async {
        expect(request.url.path, endsWith('/documents/checker_status/public'));
        return http.Response(
            jsonEncode({
              'fields': {
                'updated_at': {
                  'timestampValue': DateTime.now()
                      .toUtc()
                      .subtract(Duration(seconds: age))
                      .toIso8601String(),
                },
                'placement_company': {'booleanValue': healthy},
              },
            }),
            status);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(const MaterialApp(
          home: Scaffold(body: BackendStatusTile()),
        ));
        await tester.pump();
        expect(find.text(label), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }, () => client);
    });
  }
}
