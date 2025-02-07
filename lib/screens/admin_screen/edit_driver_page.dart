import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/idr_input_formatter.dart';
import 'package:intl/intl.dart';

class EditDriverPage extends StatefulWidget {
  final int driverId;
  final String driverName;
  final String licenseNumber;
  final String contactNumber;
  final double? pricePerDay;
  final double? pricePerMonth;
  final VoidCallback onUpdate;

  const EditDriverPage({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.licenseNumber,
    required this.contactNumber,
    this.pricePerDay,
    this.pricePerMonth,
    required this.onUpdate,
  });

  @override
  _EditDriverPageState createState() => _EditDriverPageState();
}

class _EditDriverPageState extends State<EditDriverPage> {
  late TextEditingController nameController;
  late TextEditingController licenseController;
  late TextEditingController contactController;
  late TextEditingController pricePerDayController;
  late TextEditingController pricePerMonthController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.driverName);
    licenseController = TextEditingController(text: widget.licenseNumber);
    contactController = TextEditingController(text: widget.contactNumber);
    
    // Initialize price controllers with formatted values
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    
    pricePerDayController = TextEditingController(
      text: widget.pricePerDay != null ? formatter.format(widget.pricePerDay) : 'Rp 0'
    );
    
    pricePerMonthController = TextEditingController(
      text: widget.pricePerMonth != null ? formatter.format(widget.pricePerMonth) : 'Rp 0'
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    licenseController.dispose();
    contactController.dispose();
    pricePerDayController.dispose();
    pricePerMonthController.dispose();
    super.dispose();
  }

  Future<void> _updateDriver() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // Parse the price values, removing currency formatting
    double pricePerDay = double.tryParse(pricePerDayController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    double pricePerMonth = double.tryParse(pricePerMonthController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

    final response = await http.put(
      Uri.parse('${Config.baseUrl}/drivers/${widget.driverId}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'name': nameController.text,
        'license_number': licenseController.text,
        'phone_number': contactController.text,
        'price_per_day': pricePerDay,
        'price_per_month': pricePerMonth,
      }),
    );

    if (response.statusCode == 200) {
      widget.onUpdate();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Driver updated successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update driver: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Driver'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Driver Details',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              _buildTextField(
                label: 'Driver Name',
                controller: nameController,
                inputFormatters: [],
              ),
              SizedBox(height: 16),
              _buildTextField(
                label: 'License Number',
                controller: licenseController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 16),
              _buildTextField(
                label: 'Contact Number',
                controller: contactController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 16),
              
              TextField(
                controller: pricePerDayController,
                decoration: InputDecoration(
                  labelText: 'Price per Day (IDR)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [IDRInputFormatter()],
              ),
              SizedBox(height: 16),
              
              TextField(
                controller: pricePerMonthController,
                decoration: InputDecoration(
                  labelText: 'Price per Month (IDR)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [IDRInputFormatter()],
              ),
              SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: GestureDetector(
                  onTap: _updateDriver,
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
                        'Save Changes',
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      ),
    );
  }
}
