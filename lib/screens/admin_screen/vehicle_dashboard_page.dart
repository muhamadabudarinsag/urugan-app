import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_vehicle_page.dart';
import 'edit_vehicle_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../../config.dart';

class VehicleDashboardPage extends StatefulWidget {
  const VehicleDashboardPage({super.key});

  @override
  _VehicleDashboardPageState createState() => _VehicleDashboardPageState();
}

class _VehicleDashboardPageState extends State<VehicleDashboardPage> {
  late Future<List<dynamic>> _vehiclesFuture;

  @override
  void initState() {
    super.initState();
    _vehiclesFuture = _fetchVehicles();
  }

  Future<List<dynamic>> _fetchVehicles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse(Config.getVehiclesEndpoint),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  Future<void> _refreshVehicles() async {
    setState(() {
      _vehiclesFuture = _fetchVehicles();
    });
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('${Config.getVehiclesEndpoint}/$vehicleId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      _refreshVehicles(); // Refresh the vehicle list
      _showSnackBar('Vehicle deleted successfully');
    } else {
      _showSnackBar('Failed to delete vehicle');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmDelete(String vehicleId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this vehicle?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteVehicle(vehicleId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Kendaraan'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Kendaraan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshVehicles,
                child: FutureBuilder<List<dynamic>>(
                  future: _vehiclesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerEffect();
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No vehicles found.'));
                    }

                    final vehicles = snapshot.data!;

                    return ListView.builder(
                      itemCount: vehicles.length,
                      itemBuilder: (context, index) {
                        return _buildVehicleCard(context, vehicles[index]);
                      },
                    );
                  },
                ),
              ),
            ),
            _buildAddVehicleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddVehicleButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddVehiclePage(refreshVehicles: _refreshVehicles),
            ),
          );
          _refreshVehicles();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlueAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: const Center(
            child: Text(
              'Tambah',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 123,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 8,
              color: Colors.white,
              child: const ListTile(
                title: SizedBox(height: 20, child: Placeholder()),
                subtitle: SizedBox(height: 15, child: Placeholder()),
                trailing: SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, color: Colors.grey),
                      SizedBox(width: 10),
                      Icon(Icons.delete, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Update the _buildVehicleCard method in the VehicleDashboardPage class
Widget _buildVehicleCard(BuildContext context, dynamic vehicle) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 8,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.3),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vehicle['vehicle_name'] ?? 'Unnamed Vehicle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
            ),
            Text(
              vehicle['license_plate'] ?? 'N/A',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            if (vehicle['provider'] != null && vehicle['provider'].toString().isNotEmpty)
              Text(
                'Provider: ${vehicle['provider']}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            SizedBox(height: 10),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver: ${vehicle['driver_name'] ?? 'No driver assigned'}'),
            Text('Dimensions: ${vehicle['length']}m × ${vehicle['width']}m × ${vehicle['height']}m'),
            if (vehicle['price_per_day'] != null)
              Text(
                'Price per Day: ${_formatCurrency(vehicle['price_per_day'])}',
                style: TextStyle(color: Colors.green),
              ),
            if (vehicle['price_per_month'] != null)
              Text(
                'Price per Month: ${_formatCurrency(vehicle['price_per_month'])}',
                style: TextStyle(color: Colors.green),
              ),
            if (vehicle['price_per_hour'] != null)
              Text(
                'Price per Hour: ${_formatCurrency(vehicle['price_per_hour'])}',
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
                    builder: (context) => EditVehiclePage(
                      vehicleId: vehicle['id'],
                      vehicleName: vehicle['vehicle_name'] ?? '',
                      licensePlate: vehicle['license_plate'] ?? '',
                      selectedDriverId: vehicle['driver_id']?.toString(),
                      length: vehicle['length']?.toString(),
                      width: vehicle['width']?.toString(),
                      height: vehicle['height']?.toString(),
                      provider: vehicle['provider']?.toString(),
                      pricePerDay: vehicle['price_per_day']?.toString(),
                      pricePerMonth: vehicle['price_per_month']?.toString(),
                      pricePerHour: vehicle['price_per_hour']?.toString(),
                    ),
                  ),
                ).then((_) => _refreshVehicles());
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                String vehicleId = vehicle['id'].toString();
                _confirmDelete(vehicleId);
              },
            ),
            IconButton(
              icon: Icon(Icons.qr_code, color: Colors.green),
              onPressed: () {
                String vehicleName = vehicle['vehicle_name'] ?? 'Unnamed Vehicle';
                _showBarcode(vehicle['barcode'], vehicleName);
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
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(double.parse(amount.toString()));
}

void _showBarcode(String barcode, String vehicleName) async {
  final response = await http.get(Uri.parse('${Config.getBarcodeEndpoint}/$barcode'));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final base64Image = data['qrImageUrl'];

    // Extract the base64 data (removing the prefix)
    final String base64Str = base64Image.split(',').last;

    // Convert the Base64 string to bytes
    final imageBytes = base64Decode(base64Str);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Barcode'), // Display the vehicle name here
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(imageBytes),
              const SizedBox(height: 16),
              Text('$vehicleName'), // Display the vehicle name below the barcode
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  } else {
    _showSnackBar('Failed to load barcode');
  }
}

}
