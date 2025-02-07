import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';
import '../../../utils/idr_input_formatter.dart';
import 'package:intl/intl.dart';

class EditVehiclePage extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;
  final String licensePlate;
  final String? selectedDriverId;
  final String? length;
  final String? width;
  final String? height;
  final String? provider;
  final String? pricePerDay;
  final String? pricePerMonth;
  final String? pricePerHour;

  const EditVehiclePage({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
    required this.licensePlate,
    this.selectedDriverId,
    this.length,
    this.width,
    this.height,
    this.provider,
    this.pricePerDay,
    this.pricePerMonth,
    this.pricePerHour,
  });

  @override
  _EditVehiclePageState createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
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
    vehicleNameController.text = widget.vehicleName;
    licensePlateController.text = widget.licensePlate;
    selectedDriverId = widget.selectedDriverId;
    lengthController.text = widget.length ?? '';
    widthController.text = widget.width ?? '';
    heightController.text = widget.height ?? '';
    providerController.text = widget.provider ?? '';

    // Format the price values as IDR currency
    if (widget.pricePerDay != null) {
      double price = double.tryParse(widget.pricePerDay!) ?? 0;
      pricePerDayController.text = _formatCurrency(price);
    }
    if (widget.pricePerMonth != null) {
      double price = double.tryParse(widget.pricePerMonth!) ?? 0;
      pricePerMonthController.text = _formatCurrency(price);
    }
    if (widget.pricePerHour != null) {
      double price = double.tryParse(widget.pricePerHour!) ?? 0;
      pricePerHourController.text = _formatCurrency(price);
    }

    _fetchDrivers();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _fetchDrivers() async {
    try {
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
      }
    } catch (e) {
      print('Error fetching drivers: $e');
    }
  }

  Future<void> _updateVehicle() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // Clean the price values by removing currency formatting
    String cleanPricePerDay = pricePerDayController.text.replaceAll(RegExp(r'[^\d]'), '');
    String cleanPricePerMonth = pricePerMonthController.text.replaceAll(RegExp(r'[^\d]'), '');
    String cleanPricePerHour = pricePerHourController.text.replaceAll(RegExp(r'[^\d]'), '');

    final response = await http.put(
      Uri.parse('${Config.getVehiclesEndpoint}/${widget.vehicleId}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'vehicle_name': vehicleNameController.text,
        'license_plate': licensePlateController.text,
        'driver_id': selectedDriverId,
        'length': double.tryParse(lengthController.text),
        'width': double.tryParse(widthController.text),
        'height': double.tryParse(heightController.text),
        'provider': providerController.text,
        'price_per_day': double.tryParse(cleanPricePerDay),
        'price_per_month': double.tryParse(cleanPricePerMonth),
        'price_per_hour': double.tryParse(cleanPricePerHour),
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Vehicle'),
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
              onPressed: _updateVehicle,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Text(
                  'Update Vehicle',
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
