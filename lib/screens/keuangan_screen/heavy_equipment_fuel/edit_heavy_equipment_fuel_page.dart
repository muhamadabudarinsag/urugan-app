import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';
import '../../../utils/idr_input_formatter.dart';

class EditHeavyEquipmentFuelPage extends StatefulWidget {
  final dynamic fuelCost;
  final Function refreshFuelCosts;

  const EditHeavyEquipmentFuelPage({
    Key? key,
    required this.fuelCost,
    required this.refreshFuelCosts,
  }) : super(key: key);

  @override
  _EditHeavyEquipmentFuelPageState createState() => _EditHeavyEquipmentFuelPageState();
}

class _EditHeavyEquipmentFuelPageState extends State<EditHeavyEquipmentFuelPage> {
  final _formKey = GlobalKey<FormState>();
  final _fuelAmountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  double? _currentFuelPrice;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fuelAmountController.text = widget.fuelCost['fuel_amount'].toString();
    _selectedDate = DateTime.parse(widget.fuelCost['date']).toLocal();
    _fetchCurrentFuelPrice();
  }

  Future<void> _fetchCurrentFuelPrice() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/fuel-prices/current'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _currentFuelPrice = double.parse(data['price_per_liter'].toString());
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading fuel price: $error')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (_currentFuelPrice == null) {
        throw Exception('Current fuel price not available');
      }

      final fuelAmount = double.parse(_fuelAmountController.text);
      final totalCost = fuelAmount * _currentFuelPrice!;

      final response = await http.put(
        Uri.parse('${Config.updateHeavyEquipmentFuelCostEndpoint}/${widget.fuelCost['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fuel_amount': fuelAmount,
          'price_per_liter': _currentFuelPrice,
          'total_cost': totalCost,
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        }),
      );

      if (response.statusCode == 200) {
        widget.refreshFuelCosts();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fuel cost updated successfully')),
        );
      } else {
        throw Exception('Failed to update fuel cost');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating fuel cost: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Edit Fuel Cost'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Equipment Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.fuelCost['equipment_name'],
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'License Plate: ${widget.fuelCost['license_plate']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Fuel Price',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _currentFuelPrice != null
                              ? NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(_currentFuelPrice)
                              : 'Loading...',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _fuelAmountController,
                          decoration: InputDecoration(
                            labelText: 'Fuel Amount (Liters)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter fuel amount';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        // Disabled Date Field
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade200, // Change color to indicate disabled state
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd MMMM yyyy').format(_selectedDate),
                                style: TextStyle(color: Colors.grey), // Make text color grey to indicate it's disabled
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: Colors.grey, // Change icon color to grey
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Update',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
