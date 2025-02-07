import 'dart:convert';
import 'package:flutter/material.dart';
import 'add_operational_cost_page.dart';
import 'edit_operational_cost_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';

class OfficeOperationalCostsPage extends StatefulWidget {
  const OfficeOperationalCostsPage({Key? key}) : super(key: key);

  @override
  _OfficeOperationalCostsPageState createState() => _OfficeOperationalCostsPageState();
}

class _OfficeOperationalCostsPageState extends State<OfficeOperationalCostsPage> {
  late Future<List<dynamic>> _operationalCostsFuture;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Set default start and end date to today
    _startDate = null;
      _endDate = null;
  
    _operationalCostsFuture = _fetchOperationalCosts();
  }

  Future<List<dynamic>> _fetchOperationalCosts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      String url = Config.getOperationalCostsEndpoint;
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
        throw Exception('Failed to load operational costs: ${response.body}');
      }
    } catch (error) {
      print('Network error: $error');
      throw Exception('Network error occurred');
    }
  }

  Future<void> _refreshOperationalCosts() async {
    setState(() {
      _operationalCostsFuture = _fetchOperationalCosts();
    });
  }

  Future<void> _deleteOperationalCost(int costId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('${Config.deleteOperationalCostEndpoint}/$costId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      _refreshOperationalCosts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Operational cost deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete operational cost')),
      );
    }
  }

  void _confirmDelete(int costId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this operational cost?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteOperationalCost(costId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
  DateTimeRange? picked;

  // Jika _startDate dan _endDate sudah ada, gunakan untuk inisialisasi
  if (_startDate != null && _endDate != null) {
    picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
    );
  } else {
    // Jika tidak ada tanggal yang dipilih, gunakan tanggal hari ini
    DateTime today = DateTime.now();
    picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: today, end: today),
    );
  }

  // Periksa apakah picked tidak null sebelum mengakses start dan end
  if (picked != null) {
    setState(() {
      _startDate = picked?.start;
      _endDate = picked?.end;
    });
  }
}


  void _resetDateRange() {
    setState(() {
      _startDate = DateTime.now();
      _endDate = DateTime.now();
    });
    _refreshOperationalCosts(); // Refresh the list after resetting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biaya Operasional'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: () async {
              await _selectDateRange(context);
              _refreshOperationalCosts(); // Refresh the list after date selection
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetDateRange, // Reset filter date
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
                'Selected: ${DateFormat('dd MMMM yyyy').format(_startDate!)} - ${DateFormat('dd MMMM yyyy').format(_endDate!)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              )
            else
              Text(
                'Data : ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshOperationalCosts,
                child: FutureBuilder<List<dynamic>>(
                  future: _operationalCostsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('Blm ada data.'));
                    }

                    final operationalCosts = snapshot.data!;

                    return ListView.builder(
                      itemCount: operationalCosts.length,
                      itemBuilder: (context, index) {
                        return _buildOperationalCostCard(context, operationalCosts[index]);
                      },
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddOperationalCostPage(refreshCosts: _refreshOperationalCosts),
                    ),
                  );
                  _refreshOperationalCosts(); // Refresh UI after returning
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlueAccent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: Text(
                      'Tambah',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalCostCard(BuildContext context, dynamic operationalCost) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 8,
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.3),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          title: Text(
            '${operationalCost['cost_name'] ?? 'Unnamed Cost'}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ${_formatCurrency(operationalCost['cost_amount'])}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              Text(
                'Date: ${operationalCost['date'] != null ? 
                    DateFormat('dd MMMM yyyy').format(DateTime.parse('${operationalCost['date']}').toLocal()) : 
                    'No date provided'}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blueAccent),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditOperationalCostPage(
                        costId: operationalCost['id'],
                        costName: operationalCost['cost_name'] ?? '',
                        costAmount: operationalCost['cost_amount']?.toString() ?? '',
                        refreshCosts: _refreshOperationalCosts,
                      ),
                    ),
                  ).then((_) => _refreshOperationalCosts());
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  int costId = operationalCost['id'];
                  _confirmDelete(costId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'N/A';
    double? parsedAmount;

    if (amount is String) {
      parsedAmount = double.tryParse(amount);
    } else if (amount is num) {
      parsedAmount = amount.toDouble();
    }

    if (parsedAmount == null) return 'N/A';

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(parsedAmount);
  }
}
