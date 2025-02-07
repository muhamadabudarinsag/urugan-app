import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';
import 'add_driver_cost.dart';
import 'edit_driver_cost.dart';

class DriverCostsPage extends StatefulWidget {
  const DriverCostsPage({Key? key}) : super(key: key);

  @override
  _DriverCostsPageState createState() => _DriverCostsPageState();
}

class _DriverCostsPageState extends State<DriverCostsPage> {
  late Future<List<dynamic>> _driverCostsFuture;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _driverCostsFuture = _fetchDriverCosts();
  }

  Future<List<dynamic>> _fetchDriverCosts() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    String url = '${Config.baseUrl}/driver-costs';
    
    // If no date range is selected, use today's date
    if (_startDate == null || _endDate == null) {
      DateTime today = DateTime.now();
      String formattedToday = DateFormat('yyyy-MM-dd').format(today);
      url += '?start_date=$formattedToday&end_date=$formattedToday';
    } else {
      url += '?start_date=${DateFormat('yyyy-MM-dd').format(_startDate!)}&end_date=${DateFormat('yyyy-MM-dd').format(_endDate!)}';
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
      throw Exception('Failed to load driver costs');
    }
  } catch (error) {
    print('Error fetching driver costs: $error');
    throw Exception('Failed to load driver costs');
  }
}

  Future<void> _refreshDriverCosts() async {
    setState(() {
      _driverCostsFuture = _fetchDriverCosts();
    });
  }

  Future<void> _deleteDriverCost(int costId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('${Config.baseUrl}/driver-costs/$costId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _refreshDriverCosts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver cost deleted successfully')),
        );
      } else {
        throw Exception('Failed to delete driver cost');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting driver cost: $error')),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(int costId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus biaya supir ini?'),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Hapus'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteDriverCost(costId);
              },
            ),
          ],
        );
      },
    );
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
      _refreshDriverCosts();
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _refreshDriverCosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biaya Supir'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _clearFilters,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_startDate != null && _endDate != null)
              Text(
                'Period: ${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshDriverCosts,
                child: FutureBuilder<List<dynamic>>(
                  future: _driverCostsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No driver costs found'));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final cost = snapshot.data![index];
                        return _buildCostCard(cost);
                      },
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddDriverCostPage()),
                ).then((_) => _refreshDriverCosts());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'Add Driver Cost',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostCard(dynamic cost) {
  return Card(
    margin: EdgeInsets.only(bottom: 16),
    child: ListTile(
      title: Text(cost['driver_name'] ?? 'Unknown Driver'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cost Type: ${cost['cost_type']}'),
          Text('Amount: ${_formatCurrency(cost['amount'])}'),
          Text('Date: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(cost['date']).toLocal())}'), // Updated date format
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditDriverCostPage(cost: cost),
                ),
              ).then((_) => _refreshDriverCosts());
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmationDialog(cost['id']),
          ),
        ],
      ),
    ),
  );
}

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'N/A';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(double.parse(amount.toString()));
  }
}
