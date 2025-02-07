import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';
import '../../../utils/idr_input_formatter.dart';

class EditHeavyEquipmentRentalPage extends StatefulWidget {
  final dynamic rental;
  final Function refreshRentals;

  const EditHeavyEquipmentRentalPage({
    Key? key,
    required this.rental,
    required this.refreshRentals,
  }) : super(key: key);

  @override
  _EditHeavyEquipmentRentalPageState createState() =>
      _EditHeavyEquipmentRentalPageState();
}

class _EditHeavyEquipmentRentalPageState
    extends State<EditHeavyEquipmentRentalPage> {
  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize the cost controller with the rental's current cost
    _costController.text = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(double.parse(widget.rental['cost'].toString()));
  }

  // Function to submit the form with updated data (only cost)
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('${Config.baseUrl}/heavy-equipment-rentals/${widget.rental['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cost': double.parse(_costController.text.replaceAll(RegExp(r'[^\d]'), '')),
        }),
      );

      if (response.statusCode == 200) {
        widget.refreshRentals();  // Call the refresh function passed to the page
        Navigator.pop(context);  // Go back to the previous page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rental updated successfully')),
        );
      } else {
        throw Exception('Failed to update rental');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating rental: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Heavy Equipment Rental'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Equipment ID is no longer editable
              TextFormField(
                initialValue: widget.rental['equipment_name'],  // Display the equipment name
                decoration: InputDecoration(
                  labelText: 'Equipment',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,  // Make the equipment field read-only
              ),
              SizedBox(height: 16),
              // Cost input field (this is the only editable field now)
              TextFormField(
                controller: _costController,
                decoration: InputDecoration(
                  labelText: 'Cost',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [IDRInputFormatter()],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cost';
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
                  'Update Rental',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
