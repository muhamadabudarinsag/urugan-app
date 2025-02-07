import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';
import 'idr_input_formatter.dart'; // Import the IDRInputFormatter

class Vehicle {
  final String id;
  final String name;
  final String licensePlate; // Add license plate

  Vehicle({required this.id, required this.name, required this.licensePlate});
}

class EditRentalPage extends StatefulWidget {
  final int rentalId;
  final String vehicleName;
  final String rentalDate;
  final String cost;

  const EditRentalPage({
    super.key,
    required this.rentalId,
    required this.vehicleName,
    required this.rentalDate,
    required this.cost,
  });

  @override
  _EditRentalPageState createState() => _EditRentalPageState();
}

class _EditRentalPageState extends State<EditRentalPage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedVehicleId;
  String? selectedVehicleLicensePlate;
  late double _cost;
  List<Vehicle> vehicles = [];
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Parse the rental date in UTC and convert to local
    DateTime dateTime = DateTime.parse(widget.rentalDate).toLocal();
    
    _cost = double.tryParse(widget.cost) ?? 0.0;
    _dateController.text = DateFormat('yyyy-MM-dd').format(dateTime); // Set initial value for date controller
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/vehicles'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      setState(() {
        vehicles = jsonList.map((json) => Vehicle(
          id: json['id'].toString(),
          name: json['vehicle_name'],
          licensePlate: json['license_plate'],
        )).toList();

        final selectedVehicle = vehicles.firstWhere(
          (vehicle) => vehicle.name == widget.vehicleName,
          orElse: () => vehicles.first,
        );
        selectedVehicleId = selectedVehicle.id;
        selectedVehicleLicensePlate = selectedVehicle.licensePlate;
      });
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  Future<void> _updateRental() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      try {
        final response = await http.put(
          Uri.parse('${Config.updateRentalEndpoint}${widget.rentalId}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'vehicle_id': selectedVehicleId,
            'rental_date': _dateController.text, // Keep the rental date unchanged
            'cost': _cost.toString(),
          }),
        );

        if (response.statusCode == 200) {
          Navigator.pop(context); // Go back after updating
        } else {
          print('Error: ${response.statusCode}');
          print('Response body: ${response.body}');
          throw Exception('Failed to update rental: ${response.body}');
        }
      } catch (error) {
        print('Caught error: $error');
        throw Exception('Failed to update rental');
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perbaharui Sewa'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Disabled "Pilih Kendaraan" Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Pilih Kendaraan',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  value: selectedVehicleId,
                  items: vehicles.map((Vehicle vehicle) {
                    return DropdownMenuItem<String>(
                      value: vehicle.id,
                      child: Text(vehicle.name),
                    );
                  }).toList(),
                  onChanged: null, // Disable the dropdown
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a vehicle';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                // Display selected vehicle and its license plate
                if (selectedVehicleLicensePlate != null) ...[
                  Text(
                    'License Plate: $selectedVehicleLicensePlate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                // Removed "Tanggal Sewa" field, no longer in the form
                SizedBox(height: 16),
                // Biaya (Cost) Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Biaya',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [IDRInputFormatter()],
                  onChanged: (value) {
                    String cleanedText = value.replaceAll(RegExp(r'[^\d]'), '');
                    _cost = double.tryParse(cleanedText) ?? 0.0;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a cost';
                    }
                    return null;
                  },
                  controller: TextEditingController(
                    text: NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(_cost.toInt()), // Format as IDR initially
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateRental,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Perbaharui',
                    style: TextStyle(color: Colors.white),
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
