import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

import '../../../models/branchWiseStudentModel.dart';
import '../../../resources/endpoints.dart';
import '../../../services/api_models/fetchService.dart';
import '../../../shared/ErrorWidget.dart';
import '../../../shared/loadingPage.dart';

class ResultDetailsBranchWise extends StatefulWidget {
  final dynamic args;
  ResultDetailsBranchWise({super.key, required this.args});

  @override
  _ResultDetailsBranchWiseState createState() =>
      _ResultDetailsBranchWiseState();
}

class _ResultDetailsBranchWiseState extends State<ResultDetailsBranchWise> {
  final _fetch = FetchService();
  List<BranchWiseStudentModel> _results = [];
  late Future<void> _resultsFuture;
  bool _isSearching = false;
  String _query = '';
  bool _profileLinks = false;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _fetchResults();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSearching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Close search',
                  onPressed: _closeSearch,
                )
              : null,
          title: _isSearching
              ? TextField(
                  autofocus: true,
                  maxLines: 1,
                  cursorColor: Colors.white,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search by name or company',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  onChanged: (value) {
                    setState(() => _query = value.trim().toLowerCase());
                  },
                )
              : const Text('Branch Results'),
          actions: [
            IconButton(
              isSelected: _profileLinks,
              tooltip: _profileLinks ? 'Disable profile links' : 'Enable profile links',
              icon: const Icon(Icons.link_off),
              selectedIcon: const Icon(Icons.link),
              onPressed: () => setState(() => _profileLinks = !_profileLinks),
            ),
            if (!_isSearching)
              IconButton(
                onPressed: () => setState(() => _isSearching = true),
                icon: const Icon(Icons.search_rounded),
                tooltip: 'Search results',
              ),
          ],
        ),
        body: _branchResults(context),
      ),
    );
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _query = '';
    });
  }

  Widget _branchResults(BuildContext context) {
    return FutureBuilder(
      future: _resultsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return LoadingPage();
        }
        if (snapshot.hasError) {
          return ErrorWidgetWithRefreshCallback(onRefresh: _refreshResults);
        }
        final results = _query.isEmpty
            ? _results
            : _results.where((result) {
                return result.studentName.toLowerCase().contains(_query) ||
                    result.companyName.toLowerCase().contains(_query);
              }).toList();
        if (results.isEmpty) {
          return Center(
            child: Text(
              _query.isEmpty ? 'No results available' : 'No matching results',
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.all(0),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final id = results[index].studentEnrolmentNumber?.trim() ?? '';
            final canOpen = _profileLinks && id != '0' && RegExp(r'^\d+$').hasMatch(id);
            return Card(
              margin: EdgeInsets.only(bottom: 1),
              elevation: 0.2,
              child: ListTile(
                onTap: canOpen ? () async {
                  final uri = Uri.https('channeli.in', '/student_profile/$id/');
                  var launched = false;
                  try {
                    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {}
                  if (!launched && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open the Channel i profile.')),
                    );
                  }
                } : null,
                title: Text(
                  results[index].studentName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: canOpen ? Theme.of(context).colorScheme.primary : null,
                    decoration: canOpen ? TextDecoration.underline : null,
                  ),
                ),
                subtitle: Text(
                  results[index].companyName,
                  style: TextStyle(height: 1.85),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _refreshResults() async {
    setState(() {
      _resultsFuture = _fetchResults();
    });
    await _resultsFuture;
  }

  Future<void> _fetchResults() async {
    List<BranchWiseStudentModel> _studentResults = [];
    var _data = await _fetch
        .fetchDataService(EndPoints.RESULTS_HOST + widget.args['url']);
    if (_data == null || _data == -1) {
      throw Exception('Failed to fetch branch results');
    }
    for (var r in _data) {
      _studentResults.add(BranchWiseStudentModel.fromJson(r));
    }
    if (widget.args['sort'] == 1) {
      _studentResults.sort((a, b) => a.studentName.compareTo(b.studentName));
    }

    if (!mounted) return;
    setState(() => _results = _studentResults);
  }
}
