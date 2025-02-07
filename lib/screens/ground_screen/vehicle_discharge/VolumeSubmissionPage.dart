import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../config.dart';

class VolumeSubmissionPage extends StatefulWidget {
  final int vehicleId;
  final String vehicleName;
  final String licensePlate;

  const VolumeSubmissionPage({
    Key? key,
    required this.vehicleId,
    required this.vehicleName,
    required this.licensePlate,
  }) : super(key: key);

  @override
  _VolumeSubmissionPageState createState() => _VolumeSubmissionPageState();
}

class _VolumeSubmissionPageState extends State<VolumeSubmissionPage> {
  final _heightOverloadController = TextEditingController();
  final _entryTimeController = TextEditingController();
  final _exitTimeController = TextEditingController();
  final _unloadingTimeController = TextEditingController();
  
  Map<String, dynamic>? _vehicleDetails;
  List<Map<String, dynamic>> _materials = [];
  String? _selectedMaterialId;
  List<Map<String, dynamic>> _ritaseList = [];
  double _totalVolume = 0;
  double _buyPrice = 0.0;
  double _sellPrice = 0.0;
  double _profit = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchVehicleDetails();
    _fetchMaterials();
  }

  Future<void> _fetchVehicleDetails() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('${Config.getVehiclesEndpoint}/${widget.vehicleId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _vehicleDetails = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching vehicle details: $e');
    }
  }

  Future<void> _fetchMaterials() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/materials'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _materials = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      }
    } catch (e) {
      print('Error fetching materials: $e');
    }
  }

  void _updateSummary() {
    if (_selectedMaterialId == null) return;

    var selectedMaterial = _materials.firstWhere(
      (m) => m['id'].toString() == _selectedMaterialId,
      orElse: () => {'price_buy_per_m3': 0, 'price_sell_per_m3': 0, 'name': 'Unknown'},
    );
    
    double priceBuyPerM3 = 0.0;
    double priceSellPerM3 = 0.0;
    
    var rawBuyPrice = selectedMaterial['price_buy_per_m3'];
    var rawSellPrice = selectedMaterial['price_sell_per_m3'];
    
    if (rawBuyPrice is num) {
      priceBuyPerM3 = rawBuyPrice.toDouble();
    } else if (rawBuyPrice is String) {
      priceBuyPerM3 = double.tryParse(rawBuyPrice) ?? 0.0;
    }
    
    if (rawSellPrice is num) {
      priceSellPerM3 = rawSellPrice.toDouble();
    } else if (rawSellPrice is String) {
      priceSellPerM3 = double.tryParse(rawSellPrice) ?? 0.0;
    }

    double totalVolume = 0.0;
    if (_vehicleDetails != null) {
      double length = (_vehicleDetails!['length'] is num) ? 
        (_vehicleDetails!['length'] as num).toDouble() : 
        double.tryParse(_vehicleDetails!['length']) ?? 0.0;
      
      double width = (_vehicleDetails!['width'] is num) ? 
        (_vehicleDetails!['width'] as num).toDouble() : 
        double.tryParse(_vehicleDetails!['width']) ?? 0.0;
      
      double height = (_vehicleDetails!['height'] is num) ? 
        (_vehicleDetails!['height'] as num).toDouble() : 
        double.tryParse(_vehicleDetails!['height']) ?? 0.0;

      double heightOverload = double.tryParse(_heightOverloadController.text) ?? 0;
      totalVolume = length * width * (height + heightOverload);
    }

    double volumeInM3 = totalVolume / 1000000;
    double buyPrice = volumeInM3 * priceBuyPerM3;
    double sellPrice = volumeInM3 * priceSellPerM3;
    double profit = sellPrice - buyPrice;

    setState(() {
      _totalVolume = totalVolume;
      _buyPrice = buyPrice;
      _sellPrice = sellPrice;
      _profit = profit;
    });
  }

  Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submitDischarge() async {
    if (_selectedMaterialId == null || _heightOverloadController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      double length = (_vehicleDetails!['length'] is num) ? 
        (_vehicleDetails!['length'] as num).toDouble() : 
        double.tryParse(_vehicleDetails!['length']) ?? 0.0;
      
      double width = (_vehicleDetails!['width'] is num) ? 
        (_vehicleDetails!['width'] as num).toDouble() : 
        double.tryParse(_vehicleDetails!['width']) ?? 0.0;
      
      double height = (_vehicleDetails!['height'] is num) ? 
        (_vehicleDetails!['height'] as num).toDouble() : 
        double.tryParse(_vehicleDetails!['height']) ?? 0.0;

      double heightOverload = double.tryParse(_heightOverloadController.text) ?? 0;
      double totalVolume = length * width * (height + heightOverload);

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/vehicle-discharge'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'vehicle_id': widget.vehicleId,
          'discharge_length': length,
          'discharge_width': width,
          'discharge_height': height,
          'height_overload': heightOverload,
          'volume': totalVolume,
          'entry_time': _entryTimeController.text,
          'exit_time': _exitTimeController.text,
          'unloading_time': _unloadingTimeController.text,
          'material_id': int.parse(_selectedMaterialId!),
          'total_price': _sellPrice,
          'buy_price': _buyPrice,
          'sell_price': _sellPrice,
          'profit': _profit,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Discharge data submitted successfully')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to submit discharge data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${NumberFormat('#,###').format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_vehicleDetails == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.vehicleName} - ${widget.licensePlate}'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vehicle Dimensions:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Length: ${_vehicleDetails!['length']} m'),
                      Text('Width: ${_vehicleDetails!['width']} m'),
                      Text('Height: ${_vehicleDetails!['height']} m'),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Material',
                border: OutlineInputBorder(),
              ),
              value: _selectedMaterialId,
              items: _materials.map((material) {
                double price = 0.0;
                var rawPrice = material['price_sell_per_m3'];
                if (rawPrice is num) {
                  price = rawPrice.toDouble();
                } else if (rawPrice is String) {
                  price = double.tryParse(rawPrice) ?? 0.0;
                }
                
                return DropdownMenuItem<String>(
                  value: material['id'].toString(),
                  child: Text('${material['name']} - ${_formatCurrency(price)} per m³'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMaterialId = value;
                  _updateSummary();
                });
              },
            ),
            SizedBox(height: 20),

            TextField(
              controller: _heightOverloadController,
              decoration: InputDecoration(
                labelText: 'Height Overload (m)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                _updateSummary();
              },
            ),
            SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _entryTimeController,
                    decoration: InputDecoration(
                      labelText: 'Entry Time',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(_entryTimeController),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _exitTimeController,
                    decoration: InputDecoration(
                      labelText: 'Exit Time',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () => _selectTime(_exitTimeController),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _unloadingTimeController,
              decoration: InputDecoration(
                labelText: 'Unloading Time',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
              onTap: () => _selectTime(_unloadingTimeController),
            ),
            SizedBox(height: 20),

            Container(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      if (_selectedMaterialId != null)
                        Text('Material: ${_materials.firstWhere((m) => m['id'].toString() == _selectedMaterialId)['name']}'),
                      Text('Total Volume: ${(_totalVolume / 1000000).toStringAsFixed(2)} m³'),
                      Text('Buy Price: ${_formatCurrency(_buyPrice)}'),
                      Text('Sell Price: ${_formatCurrency(_sellPrice)}'),
                      Text(
                        'Profit: ${_formatCurrency(_profit)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_selectedMaterialId != null && 
                         _heightOverloadController.text.isNotEmpty && 
                         !_isLoading) 
                ? _submitDischarge 
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Submit Discharge Data',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _heightOverloadController.dispose();
    _entryTimeController.dispose();
    _exitTimeController.dispose();
    _unloadingTimeController.dispose();
    super.dispose();
  }
}
