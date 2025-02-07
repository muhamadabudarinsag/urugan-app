import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';
import 'idr_input_formatter.dart'; // Import the formatter

class AddOperationalCostPage extends StatefulWidget {
  final Future<void> Function() refreshCosts;

  const AddOperationalCostPage({Key? key, required this.refreshCosts}) : super(key: key);

  @override
  _AddOperationalCostPageState createState() => _AddOperationalCostPageState();
}

class _AddOperationalCostPageState extends State<AddOperationalCostPage> {
  final _formKey = GlobalKey<FormState>();
  String? _costName;
  String? _amount; // This will store the raw input for processing
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    // Set the initial date to today
    _date = DateTime.now();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse(Config.addOperationalCostEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cost_name': _costName,
          'cost_amount': double.tryParse(_amount?.replaceAll(RegExp(r'[^\d]'), '') ?? '') ?? 0.0,
          'date': _date != null ? DateFormat('yyyy-MM-dd').format(_date!) : null,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Operational cost added successfully')),
        );
        await widget.refreshCosts();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add operational cost')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(), // This will now default to today's date
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biaya Operational'),
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
                    return 'Silakan masukkan nama biaya';
                  }
                  return null;
                },
                onSaved: (value) {
                  _costName = value;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Jumlah (IDR)',
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
                    return 'Harap isi jumlah';
                  }
                  return null;
                },
                onSaved: (value) {
                  _amount = value; // Store the raw input
                },
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Tangal',
                      hintText: 'Select a date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    controller: TextEditingController(
                      text: _date != null ? DateFormat('yyyy-MM-dd').format(_date!) : '',
                    ), // Set the initial date
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please select a date';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: _submit,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.lightBlueAccent],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: Text(
                      'Tambah',
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
