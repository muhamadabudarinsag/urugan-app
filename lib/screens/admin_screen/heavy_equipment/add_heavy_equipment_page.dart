import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config.dart';
import '../../../utils/idr_input_formatter.dart';
import 'package:intl/intl.dart';

class AddHeavyEquipmentPage extends StatefulWidget {
  @override
  _AddHeavyEquipmentPageState createState() => _AddHeavyEquipmentPageState();
}

class _AddHeavyEquipmentPageState extends State<AddHeavyEquipmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _fuelCapacityController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _pricePerDayController = TextEditingController();
  final _pricePerMonthController = TextEditingController();
  final _notesController = TextEditingController();
  List<dynamic> _drivers = [];
  String? _selectedDriverId;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/drivers'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _drivers = jsonDecode(response.body);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // Clean price values by removing currency formatting
      double hourlyRate = double.tryParse(_hourlyRateController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      double pricePerDay = double.tryParse(_pricePerDayController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      double pricePerMonth = double.tryParse(_pricePerMonthController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/add-heavy-equipment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'license_plate': _licensePlateController.text,
          'driver_id': _selectedDriverId,
          'fuel_capacity': int.parse(_fuelCapacityController.text),
          'hourly_rate': hourlyRate,
          'price_per_day': pricePerDay,
          'price_per_month': pricePerMonth,
          'notes': _notesController.text,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Heavy equipment added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add heavy equipment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Heavy Equipment'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Equipment Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter equipment name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _licensePlateController,
                decoration: InputDecoration(
                  labelText: 'License Plate',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter license plate';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Driver',
                  border: OutlineInputBorder(),
                ),
                value: _selectedDriverId,
                items: _drivers.map<DropdownMenuItem<String>>((driver) {
                  return DropdownMenuItem<String>(
                    value: driver['id'].toString(),
                    child: Text(driver['name']),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDriverId = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a driver';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _fuelCapacityController,
                decoration: InputDecoration(
                  labelText: 'Fuel Capacity (L)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter fuel capacity';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _hourlyRateController,
                decoration: InputDecoration(
                  labelText: 'Hourly Rate (IDR)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [IDRInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter hourly rate';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _pricePerDayController,
                decoration: InputDecoration(
                  labelText: 'Price per Day (IDR)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [IDRInputFormatter()],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _pricePerMonthController,
                decoration: InputDecoration(
                  labelText: 'Price per Month (IDR)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [IDRInputFormatter()],
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    'Submit',
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
      ),
    );
  }
}
