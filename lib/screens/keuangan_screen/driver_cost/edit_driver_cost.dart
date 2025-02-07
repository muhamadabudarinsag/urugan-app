import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';
import '../../../utils/idr_input_formatter.dart';

class EditDriverCostPage extends StatefulWidget {
  final Map<String, dynamic> cost;

  const EditDriverCostPage({Key? key, required this.cost}) : super(key: key);

  @override
  _EditDriverCostPageState createState() => _EditDriverCostPageState();
}

class _EditDriverCostPageState extends State<EditDriverCostPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the amount controller with formatted currency
    _amountController.text = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(double.parse(widget.cost['amount'].toString()));
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // Clean the amount value by removing currency formatting
      String cleanedAmount = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
      double amount = double.parse(cleanedAmount);

      final response = await http.put(
        Uri.parse('${Config.baseUrl}/driver-costs/${widget.cost['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver cost updated successfully')),
        );
      } else {
        throw Exception('Failed to update driver cost');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating driver cost: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Driver Cost'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Disabled driver name field
              TextFormField(
                initialValue: widget.cost['driver_name'] ?? 'Unknown Driver',
                decoration: InputDecoration(
                  labelText: 'Driver',
                  border: OutlineInputBorder(),
                ),
                enabled: false, // Make it read-only
              ),
              SizedBox(height: 16),
              
              // Amount field with currency formatting
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [IDRInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'Update',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
