import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:barcode_scan2/barcode_scan2.dart'; // For barcode scanning
import '../../../config.dart';

class AddVehicleOperationPage extends StatefulWidget {
  const AddVehicleOperationPage({Key? key, Map<String, dynamic>? operation}) : super(key: key);

  @override
  _AddVehicleOperationPageState createState() =>
      _AddVehicleOperationPageState();
}

class _AddVehicleOperationPageState extends State<AddVehicleOperationPage> {
  final TextEditingController _vehicleNumberController = TextEditingController();
  String? _selectedStatus;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic>? _selectedVehicle;
  List<Map<String, dynamic>> _vehicles = [];
  bool _isBarcodeScanned = false;  // Flag to check if barcode is scanned

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  // Fetch vehicles data from API
  Future<void> _fetchVehicles() async {
    setState(() {
      _isLoading = true;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(Config.getVehiclesEndpoint),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> vehicles = jsonDecode(response.body);
        setState(() {
          _vehicles = List<Map<String, dynamic>>.from(vehicles);
        });
      } else {
        throw Exception('Failed to load vehicles');
      }
    } catch (error) {
      print('Error fetching vehicles: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load vehicles')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle the scan barcode action
  Future<void> _scanBarcode() async {
    try {
      print("Starting barcode scan...");

      final result = await BarcodeScanner.scan(); // Launch the barcode scanner
      print("Scan result: ${result.rawContent}");

      if (result.type == ResultType.Barcode) {
        print("Barcode scanned successfully, content: ${result.rawContent}");

        // Get the authentication token
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');

        if (token == null) {
          print("No authentication token found.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not authenticated')),
          );
          return;
        }

        // If barcode scan is successful, get vehicle details by barcode
        final response = await http.get(
          Uri.parse('${Config.getVehicleBarcodeEndpoint}/${result.rawContent}'), // Call the new endpoint with the scanned barcode
          headers: {
            'Authorization': 'Bearer $token', // Add the Bearer token to the request header
          },
        );

        print("Request URL: ${Config.getVehicleBarcodeEndpoint}/${result.rawContent}");
        print("Response Status Code: ${response.statusCode}");
        print("Response Body: ${response.body}");

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("Vehicle data received: $data");

          setState(() {
            _selectedVehicle = {
              'id': data['id'],
              'vehicle_name': data['vehicle_name'],
              'license_plate': data['license_plate'],
              'driver_name': data['driver_name'],
            };
            _vehicleNumberController.text = _selectedVehicle!['license_plate']; // Fill the vehicle number
            _isBarcodeScanned = true; // Set the flag to true once barcode is scanned
          });

          print("Vehicle info filled: ${_selectedVehicle!['vehicle_name']} - ${_selectedVehicle!['license_plate']}");
        } else {
          // If the response is not successful, print the error
          print("Error fetching vehicle info: ${response.statusCode}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch vehicle info from barcode')),
          );
        }
      } else {
        print("The scanned result is not a valid barcode.");
      }
    } catch (e) {
      print('Error scanning barcode: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan barcode')),
      );
    }
  }

  Future<void> _addVehicleOperation() async {
  if (_vehicleNumberController.text.isEmpty || _selectedStatus == null || _selectedVehicle == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please fill in all fields')),
    );
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final payload = {
      'vehicle_id': _selectedVehicle!['id'], // Use selected vehicle id
      'status': _selectedStatus,
      'operation_date': _selectedDate.toIso8601String(),
    };

    final response = await http.post(
      Uri.parse(Config.addVehicleOperationEndpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      // Operation added successfully, notify parent page to refresh the list
      Navigator.pop(context, true); // Return 'true' to indicate success
    } else {
      // If response status is 400, handle it as a duplicate operation (already exists)
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 400 && responseBody['message'] == 'Vehicle operation for this vehicle on this date already exists.') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This vehicle already has an operation on this date.')),
        );
      } else {
        throw Exception('Failed to add vehicle operation');
      }
    }
  } catch (error) {
    print('Error adding vehicle operation: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to add vehicle operation')),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}



  // Select date from calendar
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kendaraan Beroprasi'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector with calendar icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate.toLocal().toString().split(' ')[0],
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today, color: Colors.blue),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Vehicle Number input field with padding and rounded corners
            if (_selectedVehicle != null) ...[
              _buildTextField(
                controller: _vehicleNumberController,
                label: 'Nomor Kendaraan',
                icon: Icons.local_shipping,
                readOnly: true, // Read-only once vehicle is selected or barcode is scanned
              ),
              SizedBox(height: 16),
            ],

            // Vehicle selection dropdown (manual selection)
            if (!_isBarcodeScanned) ...[
              _buildDropdown<Map<String, dynamic>>(
                value: _selectedVehicle,
                hint: 'Pilih Kendaraan',
                items: _vehicles,
                onChanged: (value) {
                  setState(() {
                    _selectedVehicle = value;
                    _vehicleNumberController.text = value?['license_plate'] ?? '';
                  });
                },
                itemBuilder: (context, vehicle) {
                  return Text(
                    '${vehicle['vehicle_name']} - ${vehicle['license_plate']}',
                    style: TextStyle(fontSize: 16),
                  );
                },
              ),
            ],
            SizedBox(height: 16),

            // Show status dropdown only if a vehicle is selected
            if (_selectedVehicle != null) ...[
              _buildDropdown<String>(
                value: _selectedStatus,
                hint: 'Status',
                items: ['Beroperasi', 'Tidak Beroperasi'],
                onChanged: (value) => setState(() => _selectedStatus = value),
              ),
            ],
            SizedBox(height: 20),

            // Footer section with Scan and Add Operation buttons
            Spacer(),
            _buildActionButton(
              onPressed: _scanBarcode,
              icon: Icons.camera_alt,
              label: 'Scan Barcode',
            ),
            SizedBox(height: 10),
            _buildActionButton(
              onPressed: _isLoading ? null : _addVehicleOperation,
              icon: null,
              label: _isLoading ? 'Processing...' : 'Tambah',
            ),
          ],
        ),
      ),
    );
  }

  // Custom method for Text Fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  // Custom method for Dropdowns
  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required Function(T?) onChanged,
    Widget Function(BuildContext, T)? itemBuilder,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      hint: Text(hint),
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: itemBuilder != null
              ? itemBuilder(context, item)
              : Text(item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // Custom method for action buttons (Scan and Add)
  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData? icon,
    required String label,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue, Colors.lightBlue]),
          borderRadius: BorderRadius.circular(30),
        ),
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Center(
          child: icon == null
              ? Text(label, style: TextStyle(fontSize: 18, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white),
                    SizedBox(width: 8),
                    Text(label, style: TextStyle(fontSize: 18, color: Colors.white)),
                  ],
                ),
        ),
      ),
    );
  }
}
