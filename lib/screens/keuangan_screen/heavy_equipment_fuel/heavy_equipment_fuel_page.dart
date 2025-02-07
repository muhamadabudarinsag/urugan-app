import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';
import 'add_heavy_equipment_fuel_page.dart';
import 'edit_heavy_equipment_fuel_page.dart';

class HeavyEquipmentFuelPage extends StatefulWidget {
  const HeavyEquipmentFuelPage({Key? key}) : super(key: key);

  @override
  _HeavyEquipmentFuelPageState createState() => _HeavyEquipmentFuelPageState();
}

class _HeavyEquipmentFuelPageState extends State<HeavyEquipmentFuelPage> {
  late Future<List<dynamic>> _fuelCostsFuture;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fuelCostsFuture = _fetchFuelCosts();
  }

  Future<List<dynamic>> _fetchFuelCosts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      String url = Config.getHeavyEquipmentFuelCostsEndpoint;
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
        throw Exception('Failed to load fuel costs');
      }
    } catch (error) {
      print('Network error: $error');
      throw Exception('Network error occurred');
    }
  }

  Future<void> _refreshFuelCosts() async {
    setState(() {
      _fuelCostsFuture = _fetchFuelCosts();
    });
  }

  Future<void> _deleteFuelCost(int costId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('${Config.deleteHeavyEquipmentFuelCostEndpoint}/$costId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _refreshFuelCosts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fuel cost deleted successfully')),
        );
      } else {
        throw Exception('Failed to delete fuel cost');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting fuel cost: $error')),
      );
    }
  }

  void _confirmDelete(int costId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this fuel cost?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFuelCost(costId);
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
      _refreshFuelCosts();
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _refreshFuelCosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Biaya Solar Alat Berat'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_startDate != null && _endDate != null)
                Text(
                  'Period: ${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                )
              else
                Text(
                  'Data: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshFuelCosts,
                  child: FutureBuilder<List<dynamic>>(
                    future: _fuelCostsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                'Error: ${snapshot.error}',
                                style: TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_gas_station,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No fuel costs found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final fuelCost = snapshot.data![index];
                          return _buildFuelCostCard(fuelCost);
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
                      builder: (context) => AddHeavyEquipmentFuelPage(
                        refreshFuelCosts: _refreshFuelCosts,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Add Fuel Cost',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFuelCostCard(dynamic fuelCost) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fuelCost['equipment_name'] ?? 'Unknown Equipment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              Text(
                'License Plate: ${fuelCost['license_plate'] ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Text(
                'Fuel Amount: ${fuelCost['fuel_amount']} liters',
                style: TextStyle(color: Colors.grey[800]),
              ),
              Text(
                'Total Cost: ${_formatCurrency(fuelCost['total_cost'])}',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Date: ${DateFormat('dd MMMM yyyy').format(DateTime.parse(fuelCost['date']).toLocal())}',
                style: TextStyle(color: Colors.grey[600]),
              ),
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
                      builder: (context) => EditHeavyEquipmentFuelPage(
                        fuelCost: fuelCost,
                        refreshFuelCosts: _refreshFuelCosts,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(fuelCost['id']),
              ),
            ],
          ),
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
