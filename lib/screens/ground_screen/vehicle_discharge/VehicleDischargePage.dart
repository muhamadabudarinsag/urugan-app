import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../config.dart';
import 'VolumeSubmissionPage.dart';

class VehicleDischargePage extends StatefulWidget {
  const VehicleDischargePage({super.key});

  @override
  _VehicleDischargePageState createState() => _VehicleDischargePageState();
}

class _VehicleDischargePageState extends State<VehicleDischargePage> {
  late Future<Map<String, dynamic>> _vehicleOperationsFuture;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _vehicleOperationsFuture = _fetchVehicleOperations();
  }

  Future<Map<String, dynamic>> _fetchVehicleOperations() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse(Config.getVehicleOperationsEndpoint).replace(
        queryParameters: {
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'status': 'Beroperasi',
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return {'operations': data};
      } else {
        throw Exception('Failed to load vehicle operations');
      }
    } catch (error) {
      print('Network error: $error');
      throw Exception('Network error occurred');
    }
  }

  Future<Map<String, dynamic>> _fetchVehicleDischargeData(int vehicleId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/vehicle-discharge/$vehicleId')
            .replace(queryParameters: {'date': formattedDate}),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        return {'discharges': [], 'summary': null};
      }
    } catch (e) {
      print('Error fetching discharge data: $e');
      return {'discharges': [], 'summary': null};
    }
  }

  Future<void> _refreshVehicleOperations() async {
    setState(() {
      _vehicleOperationsFuture = _fetchVehicleOperations();
    });
  }

  String _convertToLocalTime(String utcTime) {
    try {
      if (utcTime.contains(":") && !utcTime.contains("-")) {
        final String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
        utcTime = "$currentDate $utcTime";
      }
      DateTime utcDateTime = DateTime.parse(utcTime).toLocal();
      return DateFormat('dd MMM yyyy HH:mm').format(utcDateTime);
    } catch (e) {
      print("Error parsing date: $e");
      return 'Invalid time format';
    }
  }

  Widget _buildDischargeCard(Map<String, dynamic> discharge, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ritase $index',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueAccent,
                ),
              ),
              Text(
                _convertToLocalTime(discharge['discharge_date']),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Divider(height: 16),
          _buildInfoRow('Material', discharge['material_name'] ?? 'N/A'),
          _buildInfoRow('Volume', '${(double.parse(discharge['volume'].toString()) / 1000000).toStringAsFixed(2)} m³'),
          _buildInfoRow('Height Overload', '${discharge['height_overload']} m'),
          _buildInfoRow('Entry Time', _convertToLocalTime(discharge['entry_time'] ?? 'N/A')),
          _buildInfoRow('Exit Time', _convertToLocalTime(discharge['exit_time'] ?? 'N/A')),
          _buildInfoRow('Unloading Time', _convertToLocalTime(discharge['unloading_time'] ?? 'N/A')),
          Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buy Price: ${_formatCurrency(discharge['price_buy'])}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    'Sell Price: ${_formatCurrency(discharge['price_sell'])}',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                  Text(
                    'Profit: ${_formatCurrency(discharge['profit'])}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(height: 12),
            _buildSummaryRow('Total Volume', '${(summary['total_volume'] / 1000000).toStringAsFixed(2)} m³'),
            _buildSummaryRow('Total Buy', _formatCurrency(summary['total_price_buy'])),
            _buildSummaryRow('Total Sell', _formatCurrency(summary['total_price_sell'])),
            Divider(),
            _buildSummaryRow(
              'Total Profit',
              _formatCurrency(summary['total_profit']),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue[700] : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(double.parse(amount.toString()));
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catat Ritase'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildDateHeader(),
              Expanded(
                child: _buildVehicleList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.blueAccent, size: 20),
          SizedBox(width: 8),
          Text(
            DateFormat('dd MMMM yyyy').format(_selectedDate),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _vehicleOperationsFuture,
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
                  'Error loading data',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!['operations'].isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.no_transfer, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No vehicles operating today',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        List<dynamic> operations = snapshot.data!['operations'];

        return RefreshIndicator(
          onRefresh: _refreshVehicleOperations,
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: operations.length,
            itemBuilder: (context, index) {
              final operation = operations[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ExpansionTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          operation['vehicle_name'] ?? 'Unknown Vehicle',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          operation['license_plate'] ?? 'No plate',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    trailing: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VolumeSubmissionPage(
                              vehicleId: operation['vehicle_id'],
                              vehicleName: operation['vehicle_name'],
                              licensePlate: operation['license_plate'],
                            ),
                          ),
                        ).then((result) {
                          if (result == true) {
                            _refreshVehicleOperations();
                          }
                        });
                      },
                      icon: Icon(Icons.add, size: 18),
                      label: Text('Add Ritase'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    children: [
                      FutureBuilder<Map<String, dynamic>>(
                        future: _fetchVehicleDischargeData(operation['vehicle_id']),
                        builder: (context, dischargeSnapshot) {
                          if (dischargeSnapshot.connectionState == ConnectionState.waiting) {
                            return Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (!dischargeSnapshot.hasData || dischargeSnapshot.data!['discharges'].isEmpty) {
                            return Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No discharge data available',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }

                          List<dynamic> discharges = dischargeSnapshot.data!['discharges'];
                          Map<String, dynamic>? summary = dischargeSnapshot.data!['summary'];

                          return Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: discharges.length,
                                itemBuilder: (context, index) {
                                  return _buildDischargeCard(discharges[index], index + 1);
                                },
                              ),
                              if (summary != null) _buildSummaryCard(summary),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
