import 'package:flutter/material.dart';

import '../../../models/companyWiseStudentModel.dart';
import '../../../resources/endpoints.dart';
import '../../../services/api_models/fetchService.dart';
import '../../../shared/ErrorWidget.dart';
import '../../../shared/loadingPage.dart';

class ResultDetailsCompanyWise extends StatefulWidget {
  final dynamic args;
  ResultDetailsCompanyWise({super.key, required this.args});

  @override
  _ResultDetailsCompanyWiseState createState() =>
      _ResultDetailsCompanyWiseState();
}

class _ResultDetailsCompanyWiseState extends State<ResultDetailsCompanyWise> {
  final _fetch = FetchService();
  List<CompantWiseStudentModel> _results = [];
  late Future<void> _resultsFuture;
  bool _isSearching = false;
  String _query = '';

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
                    hintText: 'Search by name or branch',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  onChanged: (value) {
                    setState(() => _query = value.trim().toLowerCase());
                  },
                )
              : const Text('Company Results'),
          actions: [
            if (!_isSearching)
              IconButton(
                onPressed: () => setState(() => _isSearching = true),
                icon: const Icon(Icons.search_rounded),
                tooltip: 'Search results',
              ),
          ],
        ),
        body: _companyResults(context),
      ),
    );
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _query = '';
    });
  }

  Widget _companyResults(BuildContext context) {
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
                    result.studentBranchName.toLowerCase().contains(_query);
              }).toList();
        if (results.isEmpty) {
          return Center(
            child: Text(
              _query.isEmpty ? 'No results available' : 'No matching results',
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          padding: EdgeInsets.all(0),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.only(bottom: 1),
              elevation: 0.2,
              child: ListTile(
                title: Text(
                  results[index].studentName,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Container(
                  padding: EdgeInsets.only(bottom: 5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        results[index].studentBranchName,
                        style: TextStyle(height: 1.6),
                      ),
                      Text(
                        "Accepted: " + results[index].hasAccepted,
                        style: TextStyle(height: 1.6),
                      ),
                    ],
                  ),
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
    List<CompantWiseStudentModel> _studentResults = [];
    var _data = await _fetch
        .fetchDataService(EndPoints.RESULTS_HOST + widget.args['url']);
    if (_data == null || _data == -1) {
      throw Exception('Failed to fetch company results');
    }
    for (var r in _data) {
      _studentResults.add(CompantWiseStudentModel.fromJson(r));
    }
    if (widget.args['sort'] == 1) {
      _studentResults.sort((a, b) => a.studentName.compareTo(b.studentName));
    }
    if (!mounted) return;
    setState(() => _results = _studentResults);
  }
}
