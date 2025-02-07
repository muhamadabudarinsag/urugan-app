import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/idr_input_formatter.dart';

class AddDriverPage extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController licenseNumberController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController pricePerDayController = TextEditingController();
  final TextEditingController pricePerMonthController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Driver'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add a New Driver',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              _buildTextField('Driver Name', nameController),
              SizedBox(height: 16),
              _buildTextField('License Number', licenseNumberController, isNumeric: true),
              SizedBox(height: 16),
              _buildTextField('Phone Number', phoneNumberController, isNumeric: true),
              SizedBox(height: 16),
              
              // Add price per day field
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
              
              // Add price per month field
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
                  onTap: () async {
                    await _addDriver(context);
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

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumeric ? [FilteringTextInputFormatter.digitsOnly] : [],
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

  Future<void> _addDriver(BuildContext context) async {
    if (nameController.text.isEmpty || licenseNumberController.text.isEmpty || phoneNumberController.text.isEmpty) {
      _showSnackbar(context, 'Please fill in all required fields.');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // Parse the price values, removing currency formatting
    double pricePerDay = double.tryParse(pricePerDayController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    double pricePerMonth = double.tryParse(pricePerMonthController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

    final response = await http.post(
      Uri.parse(Config.addDriverEndpoint),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'name': nameController.text,
        'license_number': licenseNumberController.text,
        'phone_number': phoneNumberController.text,
        'price_per_day': pricePerDay,
        'price_per_month': pricePerMonth,
      }),
    );

    if (response.statusCode == 201) {
      _showSnackbar(context, 'Driver added successfully!');
      Navigator.pop(context);
    } else {
      _showSnackbar(context, 'Failed to add driver: ${response.body}');
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
      backgroundColor: Colors.blueAccent,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
