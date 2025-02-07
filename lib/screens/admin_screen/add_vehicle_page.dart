import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';
import '../../../utils/idr_input_formatter.dart';

class AddVehiclePage extends StatefulWidget {
  final Function refreshVehicles;

  const AddVehiclePage({Key? key, required this.refreshVehicles}) : super(key: key);

  @override
  _AddVehiclePageState createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final TextEditingController vehicleNameController = TextEditingController();
  final TextEditingController licensePlateController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController providerController = TextEditingController();
  final TextEditingController pricePerDayController = TextEditingController();
  final TextEditingController pricePerMonthController = TextEditingController();
  final TextEditingController pricePerHourController = TextEditingController();
  List<dynamic> drivers = [];
  String? selectedDriverId;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse(Config.getDriversEndpoint),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        drivers = json.decode(response.body);
      });
    } else {
      _showSnackbar(context, 'Failed to load drivers: ${response.body}');
    }
  }

  Future<void> _submitForm() async {
    if (vehicleNameController.text.isEmpty || licensePlateController.text.isEmpty || selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse(Config.addVehicleEndpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'vehicle_name': vehicleNameController.text,
        'license_plate': licensePlateController.text,
        'driver_id': selectedDriverId,
        'length': double.parse(lengthController.text),
        'width': double.parse(widthController.text),
        'height': double.parse(heightController.text),
        'provider': providerController.text,
        'price_per_day': double.tryParse(pricePerDayController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
        'price_per_month': double.tryParse(pricePerMonthController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
        'price_per_hour': double.tryParse(pricePerHourController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
      }),
    );

    if (response.statusCode == 201) {
      widget.refreshVehicles();
      Navigator.pop(context);
    } else {
      _showSnackbar(context, 'Failed to add vehicle: ${response.body}');
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Vehicle'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: vehicleNameController,
              decoration: InputDecoration(
                labelText: 'Vehicle Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: licensePlateController,
              decoration: InputDecoration(
                labelText: 'License Plate',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Driver',
                border: OutlineInputBorder(),
              ),
              value: selectedDriverId,
              items: drivers.map((driver) {
                return DropdownMenuItem<String>(
                  value: driver['id'].toString(),
                  child: Text(driver['name']),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedDriverId = newValue;
                });
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: lengthController,
              decoration: InputDecoration(
                labelText: 'Length (m)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: widthController,
              decoration: InputDecoration(
                labelText: 'Width (m)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: heightController,
              decoration: InputDecoration(
                labelText: 'Height (m)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: providerController,
              decoration: InputDecoration(
                labelText: 'Provider (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: pricePerDayController,
              decoration: InputDecoration(
                labelText: 'Price per Day',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [IDRInputFormatter()],
            ),
            SizedBox(height: 16),
            TextField(
              controller: pricePerMonthController,
              decoration: InputDecoration(
                labelText: 'Price per Month',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [IDRInputFormatter()],
            ),
            SizedBox(height: 16),
            TextField(
              controller: pricePerHourController,
              decoration: InputDecoration(
                labelText: 'Price per Hour',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [IDRInputFormatter()],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  'Add Vehicle',
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
}
