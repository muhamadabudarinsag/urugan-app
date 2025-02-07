import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../../config.dart';
import 'add_heavy_equipment_page.dart';
import 'edit_heavy_equipment_page.dart';
import 'package:intl/intl.dart';

class HeavyEquipmentDashboardPage extends StatefulWidget {
  const HeavyEquipmentDashboardPage({super.key});

  @override
  _HeavyEquipmentDashboardPageState createState() => _HeavyEquipmentDashboardPageState();
}

class _HeavyEquipmentDashboardPageState extends State<HeavyEquipmentDashboardPage> {
  late Future<List<dynamic>> _equipmentFuture;

  @override
  void initState() {
    super.initState();
    _equipmentFuture = _fetchEquipment();
  }

  Future<List<dynamic>> _fetchEquipment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/heavy-equipment'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load heavy equipment');
    }
  }

  Future<void> _refreshEquipment() async {
    setState(() {
      _equipmentFuture = _fetchEquipment();
    });
  }

  Future<void> _deleteEquipment(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/heavy-equipment/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      _refreshEquipment();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Heavy equipment deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete heavy equipment')),
      );
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this equipment?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEquipment(id);
              },
            ),
          ],
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Alat Berat'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshEquipment,
                child: FutureBuilder<List<dynamic>>(
                  future: _equipmentFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerEffect();
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No heavy equipment found'));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final equipment = snapshot.data![index];
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              equipment['name'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('License Plate: ${equipment['license_plate']}'),
                                Text('Driver: ${equipment['driver_name'] ?? 'No driver assigned'}'),
                                Text('Fuel Capacity: ${equipment['fuel_capacity']} L'),
                                Text('Hourly Rate: ${_formatCurrency(equipment['hourly_rate'])}'),
                                Text('Price per Day: ${_formatCurrency(equipment['price_per_day'])}'),
                                Text('Price per Month: ${_formatCurrency(equipment['price_per_month'])}'),
                                if (equipment['notes'] != null && equipment['notes'].toString().isNotEmpty)
                                  Text('Notes: ${equipment['notes']}'),
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
                                        builder: (context) => EditHeavyEquipmentPage(
                                          equipment: equipment,
                                        ),
                                      ),
                                    ).then((_) => _refreshEquipment());
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(equipment['id']),
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
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddHeavyEquipmentPage()),
                ).then((_) => _refreshEquipment());
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  'Add Heavy Equipment',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Container(
              height: 120,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
