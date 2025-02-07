import 'dart:convert';
import 'package:flutter/material.dart';
import 'add_heavy_equipment_rental_page.dart';
import 'edit_heavy_equipment_rental_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';

class HeavyEquipmentRentalPage extends StatefulWidget {
  const HeavyEquipmentRentalPage({Key? key}) : super(key: key);

  @override
  _HeavyEquipmentRentalPageState createState() => _HeavyEquipmentRentalPageState();
}

class _HeavyEquipmentRentalPageState extends State<HeavyEquipmentRentalPage> {
  late Future<List<dynamic>> _rentalsFuture;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _rentalsFuture = _fetchRentals();
  }

  Future<List<dynamic>> _fetchRentals() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      String url = '${Config.baseUrl}/heavy-equipment-rentals';
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
        throw Exception('Failed to load rentals');
      }
    } catch (error) {
      print('Network error: $error');
      throw Exception('Network error occurred');
    }
  }

  Future<void> _refreshRentals() async {
    setState(() {
      _rentalsFuture = _fetchRentals();
    });
  }

  Future<void> _deleteRental(int rentalId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/heavy-equipment-rentals/$rentalId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      _refreshRentals();
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
              onPressed: () => Navigator.of(context).pop(),
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
      _refreshRentals();
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _refreshRentals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biaya Sewa Alat Berat'),
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
                onRefresh: _refreshRentals,
                child: FutureBuilder<List<dynamic>>(
                  future: _rentalsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No rentals found'));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final rental = snapshot.data![index];
                        return _buildRentalCard(rental);
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
                  MaterialPageRoute(
                    builder: (context) => AddHeavyEquipmentRentalPage(
                      refreshRentals: _refreshRentals,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'Add Rental',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalCard(dynamic rental) {
    final cost = double.parse(rental['cost'].toString());
    final formattedCost = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(cost);

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          rental['equipment_name'],
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cost: $formattedCost'),
            Text('Date: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(rental['rental_date']).toLocal())}'),
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
                    builder: (context) => EditHeavyEquipmentRentalPage(
                      rental: rental,
                      refreshRentals: _refreshRentals,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(rental['id']),
            ),
          ],
        ),
      ),
    );
  }
}
