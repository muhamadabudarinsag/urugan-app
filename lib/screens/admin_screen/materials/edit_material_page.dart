import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config.dart';
import 'package:rcb_mobile_app/utils/idr_input_formatter.dart';

class EditMaterialPage extends StatefulWidget {
  final Map<String, dynamic> material;

  const EditMaterialPage({Key? key, required this.material}) : super(key: key);

  @override
  _EditMaterialPageState createState() => _EditMaterialPageState();
}

class _EditMaterialPageState extends State<EditMaterialPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceBuyController;
  late TextEditingController _priceSellController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.material['name']);
    _priceBuyController = TextEditingController(text: widget.material['price_buy_per_m3'].toString());
    _priceSellController = TextEditingController(text: widget.material['price_sell_per_m3'].toString());
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // Clean the price values by removing currency formatting
      String cleanedPriceBuy = _priceBuyController.text.replaceAll(RegExp(r'[^\d]'), '');
      String cleanedPriceSell = _priceSellController.text.replaceAll(RegExp(r'[^\d]'), '');

      final response = await http.put(
        Uri.parse('${Config.baseUrl}/materials/${widget.material['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'price_buy_per_m3': double.parse(cleanedPriceBuy),
          'price_sell_per_m3': double.parse(cleanedPriceSell),
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Material updated successfully')),
        );
      } else {
        throw Exception('Failed to update material');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating material: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Material'),
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
                  labelText: 'Material Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter material name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _priceBuyController,
                inputFormatters: [IDRInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Price Buy per m³ (Rp)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter buy price';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _priceSellController,
                inputFormatters: [IDRInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Price Sell per m³ (Rp)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter sell price';
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
    _nameController.dispose();
    _priceBuyController.dispose();
    _priceSellController.dispose();
    super.dispose();
  }
}
