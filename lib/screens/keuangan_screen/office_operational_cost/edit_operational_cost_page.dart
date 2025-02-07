import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'idr_input_formatter.dart'; // Import the formatter
import '../../../config.dart';

class EditOperationalCostPage extends StatefulWidget {
  final int costId;
  final String costName;
  final String costAmount;
  final Future<void> Function() refreshCosts;

  const EditOperationalCostPage({
    Key? key,
    required this.costId,
    required this.costName,
    required this.costAmount,
    required this.refreshCosts,
  }) : super(key: key);

  @override
  _EditOperationalCostPageState createState() => _EditOperationalCostPageState();
}

class _EditOperationalCostPageState extends State<EditOperationalCostPage> {
  final _formKey = GlobalKey<FormState>();
  late String _description;
  late String _amount; // Raw input for processing

  @override
  void initState() {
    super.initState();
    _description = widget.costName;
    _amount = widget.costAmount; // This will hold the raw input
    debugPrint('Initialized with description: $_description and amount: $_amount');
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      debugPrint('Form submitted with description: $_description and amount: $_amount');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      debugPrint('Retrieved token: $token');

      final response = await http.put(
        Uri.parse('${Config.updateOperationalCostEndpoint}/${widget.costId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cost_name': _description,
          'cost_amount': double.tryParse(_amount.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0, // Parse amount as double
        }),
      );

      debugPrint('Response status: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Operational cost updated successfully')),
        );
        await widget.refreshCosts();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update operational cost')),
        );
      }
    } else {
      debugPrint('Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Biaya Operasional'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _description,
                decoration: InputDecoration(
                  labelText: 'Nama Biaya',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(double.tryParse(_amount.replaceAll(RegExp(r'[^\d]'), '')) ?? 0), // Format as IDR
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, IDRInputFormatter()],
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
                onSaved: (value) {
                  _amount = value!; // Store the raw input
                },
              ),
              SizedBox(height: 32),
              GestureDetector(
                onTap: _submit,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blueAccent, Colors.lightBlueAccent]),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: Text(
                      'Perbaharui',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
}
