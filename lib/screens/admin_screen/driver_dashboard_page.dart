import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_driver_page.dart';
import 'edit_driver_page.dart';
import '../../config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  _DriverDashboardPageState createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  late Future<List<dynamic>> _driversFuture;

  @override
  void initState() {
    super.initState();
    _driversFuture = _fetchDrivers();
  }

  Future<List<dynamic>> _fetchDrivers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/drivers'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load drivers: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> _refreshDrivers() async {
    setState(() {
      _driversFuture = _fetchDrivers();
    });
  }

  Future<void> _removeDriver(int driverId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('${Config.baseUrl}/drivers/$driverId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver removed successfully!')),
        );
        _refreshDrivers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove driver: ${response.body}')),
        );
      }
    }
  }

  Widget _buildShimmerDriverCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 8,
          color: Colors.white,
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Container(height: 20, width: double.infinity, color: Colors.white),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: 150, color: Colors.white),
                SizedBox(height: 4),
                Container(height: 16, width: 100, color: Colors.white),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, color: Colors.blueAccent),
                SizedBox(width: 8),
                Icon(Icons.delete, color: Colors.red),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Data Supir'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: _refreshDrivers,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Supir',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _driversFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView.builder(
                        itemCount: 3,
                        itemBuilder: (context, index) => _buildShimmerDriverCard(),
                      );
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No drivers found'));
                    }

                    final drivers = snapshot.data!;

                    return ListView.builder(
                      itemCount: drivers.length,
                      itemBuilder: (context, index) {
                        return _buildDriverCard(context, drivers[index]);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddDriverPage()),
                    ).then((_) => _refreshDrivers());
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
                        'Add Driver',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'N/A';
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(double.parse(amount.toString()));
  }

  Widget _buildDriverCard(BuildContext context, dynamic driver) {
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
          driver['name'],
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nomor HP: ${driver['phone_number']}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            Text(
              'Nomor SIM: ${driver['license_number']}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (driver['price_per_day'] != null)
              Text(
                'Price per Day: ${_formatCurrency(driver['price_per_day'])}',
                style: TextStyle(color: Colors.green),
              ),
            if (driver['price_per_month'] != null)
              Text(
                'Price per Month: ${_formatCurrency(driver['price_per_month'])}',
                style: TextStyle(color: Colors.green),
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
                    builder: (context) => EditDriverPage(
                      driverId: driver['id'],
                      driverName: driver['name'],
                      licenseNumber: driver['license_number'],
                      contactNumber: driver['phone_number'],
                      pricePerDay: _parseDouble(driver['price_per_day']),
                      pricePerMonth: _parseDouble(driver['price_per_month']),
                      onUpdate: _refreshDrivers,
                    ),
                  ),
                ).then((_) => _refreshDrivers());
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _removeDriver(driver['id']);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

// Add this helper method to safely parse double values
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

}
