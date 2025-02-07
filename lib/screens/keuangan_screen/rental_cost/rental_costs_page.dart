import 'dart:convert';
import 'package:flutter/material.dart';
import 'add_rental_page.dart';
import 'edit_rental_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';

class RentalCostsPage extends StatefulWidget {
  const RentalCostsPage({Key? key}) : super(key: key);

  @override
  _RentalCostsPageState createState() => _RentalCostsPageState();
}

class _RentalCostsPageState extends State<RentalCostsPage> {
  late Future<List<dynamic>> _rentalCostsFuture;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _rentalCostsFuture = _fetchRentalCosts();
  }

  Future<List<dynamic>> _fetchRentalCosts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      String url = Config.getRentalsEndpoint;
      // Use today's date if no range is set
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
        throw Exception('Failed to load rental costs: ${response.body}');
      }
    } catch (error) {
      print('Network error: $error');
      throw Exception('Network error occurred');
    }
  }

  Future<void> _refreshRentalCosts() async {
    setState(() {
      _rentalCostsFuture = _fetchRentalCosts();
    });
  }

  Future<void> _deleteRental(int rentalId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('${Config.deleteRentalEndpoint}/$rentalId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      _refreshRentalCosts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rental deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete rental')),
      );
    }
  }

  void _confirmDelete(int rentalId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this rental?'),
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
                _deleteRental(rentalId);
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
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _refreshRentalCosts(); // Refresh after date selection
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _refreshRentalCosts(); // Refresh the list after clearing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biaya Sewa Armada'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: () => _selectDateRange(context),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _clearFilters, // Clear filters
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
            SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshRentalCosts,
                child: FutureBuilder<List<dynamic>>(
                  future: _rentalCostsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('Belum ada data.'));
                    }

                    final rentalCosts = snapshot.data!;

                    return ListView.builder(
                      itemCount: rentalCosts.length,
                      itemBuilder: (context, index) {
                        return _buildRentalCostCard(context, rentalCosts[index]);
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
                      builder: (context) => AddRentalPage(refreshRentals: _refreshRentalCosts),
                    ),
                  );
                  _refreshRentalCosts(); // Refresh UI after returning
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blueAccent, Colors.lightBlueAccent]),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: Text('Tambah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';

    // Assuming dateString is in UTC
    DateTime dateTime = DateTime.parse(dateString).toLocal();
    return DateFormat('dd MMMM yyyy').format(dateTime);
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

  Widget _buildRentalCostCard(BuildContext context, dynamic rental) {
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${rental['vehicle_name'] ?? 'Unnamed Vehicle'}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
              ),
              Text(
                '${rental['license_plate'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              SizedBox(height: 10),
            ],
          ),
          subtitle: Text(
            'Biaya: ${_formatCurrency(rental['cost'])}',
            style: TextStyle(color: Colors.grey[700]),
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
                      builder: (context) => EditRentalPage(
                        rentalId: rental['id'],
                        vehicleName: rental['vehicle_name'] ?? '',
                        rentalDate: rental['rental_date'] ?? '',
                        cost: rental['cost']?.toString() ?? '',
                      ),
                    ),
                  ).then((_) => _refreshRentalCosts());
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  int rentalId = rental['id'];
                  _confirmDelete(rentalId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
