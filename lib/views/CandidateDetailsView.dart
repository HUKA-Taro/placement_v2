import '../shared/profile_app_update.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../shared/app_theme.dart';
import '../resources/strings.dart';
import '../shared/loadingPage.dart';
import '../viewmodels/CandidateDetailsViewModel.dart';
import 'baseView.dart';
import '../services/notifications/custom_push_service.dart';
import '../services/notifications/notification_settings.dart';

class CandidateDetailsView extends StatelessWidget {
  const CandidateDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    var _width = MediaQuery.of(context).size.width;

    return BaseView<CandidateDetailsViewModel>(
      onModelReady: (model) {
        model.fetchCandidate();
      },
      builder: (context, model, child) =>
          _detailScaffold(context, model, _width),
    );
  }

  Widget _detailScaffold(
      BuildContext context, CandidateDetailsViewModel model, double _width) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints.expand(),
        child: (model.isBusy)
            ? Center(
                child: LoadingPage(),
              )
            : (model.candidate == null)
                ? _errorColumn(context, model, _width)
                : _profileBody(context, model, _width),
      ),
    );
  }

  Widget _errorColumn(
      BuildContext context, CandidateDetailsViewModel model, double _width) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            height: 30,
          ),
          const Center(
            child: Text("Something went Wrong"),
          ),
          const SizedBox(
            height: 20,
          ),
          _menu(context, model, _width),
        ],
      ),
    );
  }

  Widget _profileBody(BuildContext context, dynamic model, double _width) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            height: 30,
          ),
          _headerAndIcon(context, model.candidate, _width),
          const SizedBox(
            height: 20,
          ),
          _studentInfo(context, model.candidate, _width),
          const SizedBox(
            height: 20,
          ),
          _myApplicationsButton(context, model.candidate, _width),
          const SizedBox(
            height: 20,
          ),
          _myResumesButton(context, model.candidate, _width),
          const SizedBox(
            height: 20,
          ),
          _menu(context, model, _width),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, dynamic model, double _width) {
    return SizedBox(
      width: _width * 0.9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (CustomPushService.supported) ...[
            _divider(),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
              leading: const Icon(Icons.notifications_outlined),
              title: Text(
                'Notification settings',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotificationSettings(),
              )),
            ),
          ],
          _divider(),
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            subtitle: ValueListenableBuilder<ThemeMode>(
              valueListenable: AppTheme.mode,
              builder: (_, mode, __) => Text(_themeLabel(mode)),
            ),
            onTap: () => _chooseTheme(context),
          ),
          _divider(),
          ListTile(
            contentPadding: EdgeInsets.fromLTRB(10, 5, 5, 5),
            leading: Icon(Icons.feedback_outlined),
            title: Text(
              "Feedback",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            onTap: () async {
              await model.launchURL(Strings.FEEDBACK_LINK);
            },
          ),
          _divider(),
          ListTile(
            contentPadding: EdgeInsets.fromLTRB(10, 5, 5, 5),
            leading: Icon(Icons.info),
            title: Text(
              "About Us",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            onTap: () {
              model.launchURL(Strings.ABOUT_US_LINK);
            },
          ),
          _divider(),
          ListTile(
            contentPadding: EdgeInsets.fromLTRB(10, 5, 5, 5),
            leading: Icon(Icons.exit_to_app),
            title: Text(
              "Log Out",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            onTap: () async {
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AlertDialog(
                        content: Text("Do you wish to Log out?"),
                        actions: <Widget>[
                          TextButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text("Sure"),
                            onPressed: () async {
                              await model.logout();
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/wrapper', (Route<dynamic> route) => false);
                            },
                          ),
                        ],
                      ));
            },
          ),
          _divider(),
          const ProfileAppUpdate(),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  Future<void> _chooseTheme(BuildContext context) async {
    final current = AppTheme.mode.value;
    final selection = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Theme'),
        children: [
          for (final mode in ThemeMode.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(mode),
              child: Row(children: [
                Expanded(child: Text(_themeLabel(mode))),
                if (mode == current) const Icon(Icons.check),
              ]),
            ),
        ],
      ),
    );
    if (selection == null || !context.mounted) return;
    try {
      await AppTheme.save(selection);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save theme.')),
        );
      }
    }
  }

  Widget _divider() {
    return const Divider(
      color: Color(0xFFe6e6e6),
      thickness: 1,
      indent: 10,
      height: 0,
      endIndent: 10,
    );
  }

  Widget _myApplicationsButton(
      BuildContext context, dynamic model, double _width) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/profileApplied');
      },
      child: _button(context, "My Applications", _width),
    );
  }

  Widget _myResumesButton(BuildContext context, dynamic model, double _width) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/resumes');
      },
      child: _button(context, "My Resumes", _width),
    );
  }

  Widget _button(BuildContext context, String heading, double _width) {
    return Container(
      width: _width * 0.9,
      decoration: BoxDecoration(
          color: const Color.fromRGBO(115, 161, 253, 0.1),
          borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.only(left: 20),
              child: Text(
                heading,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17),
              ),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF73A1FD),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentInfo(BuildContext context, dynamic model, double _width) {
    return SizedBox(
      width: _width * 0.9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            model.degreeName,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            model.departmentName,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(
            height: 10,
          ),
          _statusRows(context, "Status: ", model.season + ", " + model.internshipStatus),
          const SizedBox(
            height: 5,
          ),
          _statusRows(context, "Pool A Credits: ", model.creditsPoolA.toString()),
          const SizedBox(
            height: 5,
          ),
          _statusRows(context, "Pool B Credits: ", model.creditsPoolB.toString()),
        ],
      ),
    );
  }

  Widget _statusRows(BuildContext context, String heading, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          heading,
          style: TextStyle(fontSize: 17, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _headerAndIcon(BuildContext context, dynamic model, double _width) {
    final String? displayPicture = model.displayPicture;
    return SizedBox(
      width: _width * 0.9,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                    color: Color(0xFFE0E0E0), shape: BoxShape.circle),
                child: Icon(
                  Icons.account_circle,
                  size: 60,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              if (displayPicture != null)
              CachedNetworkImage(
                imageUrl: displayPicture,
                placeholder: _imagePlaceHolder,
                errorWidget: (context, url, error) => _imagePlaceHolder(context, url),
                imageBuilder: (context, imageProvider) {
                  return CircleAvatar(
                    backgroundImage: imageProvider,
                    radius: 30,
                  );
                },
              ),
            ],
          ),
          const SizedBox(
            width: 10,
          ),
          Flexible(
            child: Text(
              model.candidateName ?? '',
              style: const TextStyle(fontSize: 30),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceHolder(BuildContext context, String str) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.account_circle,
        size: 60,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}
