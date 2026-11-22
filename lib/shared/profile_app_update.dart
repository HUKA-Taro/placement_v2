import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ProfileAppUpdate extends StatefulWidget {
  const ProfileAppUpdate({super.key});

  @override
  State<ProfileAppUpdate> createState() => _ProfileAppUpdateState();
}

class _ProfileAppUpdateState extends State<ProfileAppUpdate> {
  static const repo = 'HUKA-Taro/placementv2';
  final _version = const MethodChannel('channeli/app_info')
      .invokeMethod<String>('version')
      .onError<PlatformException>((_, __) => null)
      .onError<MissingPluginException>((_, __) => null);
  bool _checking = false;
  String? _status;
  Uri? _release;

  List<int>? _versionParts(String value) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$').firstMatch(value);
    if (match == null) return null;
    return [for (var i = 1; i <= 3; i++) int.parse(match[i]!)];
  }

  int _compare(List<int> installed, List<int> published) {
    for (var i = 0; i < 3; i++) {
      final difference = installed[i].compareTo(published[i]);
      if (difference != 0) return difference;
    }
    return 0;
  }

  Future<void> _check(String version) async {
    setState(() {
      _checking = true;
      _status = null;
      _release = null;
    });
    var status = 'Could not check for updates. Try again later.';
    Uri? release;
    try {
      final response = await http
          .get(Uri.https('api.github.com', '/repos/$repo/releases/latest'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 404) {
        status = 'No public release is available.';
      } else if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final tag = body is Map<String, dynamic> ? body['tag_name'] : null;
        final installed = _versionParts(version);
        final published = tag is String ? _versionParts(tag) : null;
        if (installed == null || published == null) {
          status = 'Could not compare app versions.';
        } else {
          final comparison = _compare(installed, published);
          if (comparison < 0) {
            status = 'Version ${published.join('.')} is available.';
            release = Uri.https('github.com', '/$repo/releases/tag/$tag');
          } else if (comparison > 0) {
            status = 'This build is newer than the GitHub release.';
          } else {
            status = 'You have the latest version.';
          }
        }
      }
    } on Exception {
      // Keep the retry message when GitHub cannot be reached.
    }
    if (!mounted) return;
    setState(() {
      _checking = false;
      _status = status;
      _release = release;
    });
  }

  Future<void> _openRelease(Uri release) async {
    try {
      if (await launchUrl(release, mode: LaunchMode.externalApplication))
        return;
    } on PlatformException {
      // Show the same error if the browser cannot open.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the GitHub release.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<String?>(
      future: _version,
      builder: (context, snapshot) {
        final version = snapshot.data;
        if (version == null) return const SizedBox.shrink();
        final release = _release;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: _checking ? null : () => _check(version),
                child: Text(_checking ? 'Checking…' : 'Check for updates'),
              ),
              if (_status != null)
                Semantics(
                  liveRegion: true,
                  child: Text(_status!, textAlign: TextAlign.center),
                ),
              if (release != null)
                TextButton(
                  onPressed: () => _openRelease(release),
                  child: const Text('View release on GitHub'),
                ),
              const SizedBox(height: 8),
              Text('Version $version',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}
