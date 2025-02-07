import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import 'base_page.dart';
import '../models/user_role.dart';

class HistoryPage extends BasePage {
  const HistoryPage({super.key});

  @override
  String get title => 'Riwayat Aktivitas';

  @override
  Widget build(BuildContext context) {
    return _HistoryPageContent();
  }

  @override
  bool canAccess(UserRole role) {
    return true;
  }
}

class _HistoryPageContent extends StatefulWidget {
  @override
  _HistoryPageContentState createState() => _HistoryPageContentState();
}

class _HistoryPageContentState extends State<_HistoryPageContent> {
  late Future<List<dynamic>> _activityLogsFuture;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = null;
    _endDate = null;
    _activityLogsFuture = _fetchActivityLogs();
  }

  Future<List<dynamic>> _fetchActivityLogs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      String url = '${Config.baseUrl}/activity-logs';
      if (_startDate != null && _endDate != null) {
        url += '?start_date=${DateFormat('yyyy-MM-dd').format(_startDate!)}&end_date=${DateFormat('yyyy-MM-dd').format(_endDate!)}';
      } else {
        DateTime today = DateTime.now();
        url += '?start_date=${DateFormat('yyyy-MM-dd').format(today)}&end_date=${DateFormat('yyyy-MM-dd').format(today)}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load activity logs');
      }
    } catch (error) {
      print('Error fetching activity logs: $error');
      throw Exception('Failed to load activity logs');
    }
  }

  Future<void> _refreshActivityLogs() async {
    setState(() {
      _activityLogsFuture = _fetchActivityLogs();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _refreshActivityLogs();
    }
  }

  void _resetDateFilter() {
    setState(() {
      _startDate = DateTime.now();
      _endDate = DateTime.now();
    });
    _refreshActivityLogs();
  }

  Icon _getActivityIcon(String action) {
    switch (action.toLowerCase()) {
      case 'add':
        return Icon(Icons.add_circle, color: Colors.green);
      case 'edit':
        return Icon(Icons.edit, color: Colors.blue);
      case 'delete':
        return Icon(Icons.delete, color: Colors.red);
      case 'login':
        return Icon(Icons.login, color: Colors.purple);
      case 'logout':
        return Icon(Icons.logout, color: Colors.orange);
      default:
        return Icon(Icons.info, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: AppBar(
            toolbarHeight: 80,
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: Text(
              'Riwayat Aktivitas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.date_range),
                onPressed: () => _selectDateRange(context),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _resetDateFilter,
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_startDate != null && _endDate != null)
              Text(
                'Periode: ${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              )
            else
              Text(
                'Data: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshActivityLogs,
                child: FutureBuilder<List<dynamic>>(
                  future: _activityLogsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('Tidak ada aktivitas.'));
                    }

                    final activities = snapshot.data!;
                    return ListView.builder(
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final activity = activities[index];
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: _getActivityIcon(activity['action']),
                            title: Text(
                              activity['description'],
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('dd MMM yyyy HH:mm').format(
                                    DateTime.parse(activity['created_at']),
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Oleh: ${activity['username']}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
