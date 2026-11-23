import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_version_gate.dart';

class ProfileAppUpdate extends StatefulWidget {
  const ProfileAppUpdate({super.key});

  @override
  State<ProfileAppUpdate> createState() => _ProfileAppUpdateState();
}

class _ProfileAppUpdateState extends State<ProfileAppUpdate> {
  late final _version = const MethodChannel('channeli/app_info')
      .invokeMethod<String>('version')
      .onError<PlatformException>((_, __) => null)
      .onError<MissingPluginException>((_, __) => null);
  bool _checking = false;
  String? _status;
  Uri? _download;

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _status = null;
      _download = null;
    });
    try {
      final policy = await AppVersionPolicy.fetch();
      if (await AppVersionPolicy.buildNumber() < policy.minimumBuild) {
        _status = 'Version ${policy.version} is available.';
        _download = policy.download;
      } else {
        _status = 'Your version is up to date.';
      }
    } catch (_) {
      _status = 'Could not check for updates. Try again later.';
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
    if (mounted) setState(() => _status = 'Could not open the APK download.');
  }

  @override
  Widget build(BuildContext context) {
    if (!AppVersionPolicy.isAndroid) return const SizedBox.shrink();
    return FutureBuilder<String?>(
      future: _version,
      builder: (context, snapshot) {
        final version = snapshot.data;
        if (version == null) return const SizedBox.shrink();
        final download = _download;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: _checking ? null : _check,
                child: Text(_checking ? 'Checking...' : 'Check for updates'),
              ),
              if (_status != null)
                Semantics(
                    liveRegion: true,
                    child: Text(_status!, textAlign: TextAlign.center)),
              if (download != null)
                TextButton(
                  onPressed: () => _openDownload(download),
                  child: const Text('Install latest version'),
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
