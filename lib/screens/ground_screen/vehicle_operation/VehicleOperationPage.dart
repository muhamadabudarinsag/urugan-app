import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../config.dart';
import 'AddVehicleOperationPage.dart'; // Assuming this is your "Add Vehicle Operation" page

class VehicleOperationPage extends StatefulWidget {
  const VehicleOperationPage({super.key});

  @override
  _VehicleOperationPageState createState() => _VehicleOperationPageState();
}

class _VehicleOperationPageState extends State<VehicleOperationPage> {
  late Future<List<Map<String, dynamic>>> _vehicleOperationsFuture;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
   // Load vehicle operations based on today's date if no date is selected
    _selectedDate = DateTime.now(); // Default to today's date
    _vehicleOperationsFuture = _fetchVehicleOperations(date: _selectedDate);
  }

  // Fetching all vehicle operations from the API
  Future<List<Map<String, dynamic>>> _fetchVehicleOperations({DateTime? date}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final dateString = date != null
          ? DateFormat('yyyy-MM-dd').format(date) // Format the selected date as 'YYYY-MM-DD'
          : null;
      final url = Uri.parse(Config.getVehicleOperationsEndpoint);

      final response = await http.get(
        url.replace(queryParameters: {'date': dateString}), // Pass the date as a query parameter
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load vehicle operations');
      }
    } catch (error) {
      print('Network error: $error');
      throw Exception('Network error occurred');
    }
  }

  // Navigate to AddVehicleOperationPage for adding or editing
  void _navigateToAddVehicleOperation({Map<String, dynamic>? operation}) async {
  // Wait for the result from the AddVehicleOperationPage
  bool? result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddVehicleOperationPage(operation: operation),
    ),
  );

  // If the result is true, that means the operation was added successfully
  if (result == true) {
    setState(() {
      _selectedDate = DateTime.now(); // Default to today's date
    _vehicleOperationsFuture = _fetchVehicleOperations(date: _selectedDate);
    });
  }
}


  // Open Date Picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _vehicleOperationsFuture = _fetchVehicleOperations(date: _selectedDate); // Fetch filtered operations
      });
    }
  }

  // Reset Date Filter
  void _resetDateFilter() {
    setState(() {
      _selectedDate = DateTime.now(); // Default to today's date
    _vehicleOperationsFuture = _fetchVehicleOperations(date: _selectedDate);
    
    });
  }

  Future<void> _toggleStatus(String operationId, String currentStatus) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      // Determine the new status (toggle between 'Beroperasi' and 'Tidak Beroperasi')
      String newStatus = currentStatus == 'Beroperasi' ? 'Tidak Beroperasi' : 'Beroperasi';

      // Prepare the API URL and body
      final url = Uri.parse('${Config.updateVehicleOperationStatusEndpoint}/$operationId');
      final body = jsonEncode({'status': newStatus});

      // Log the request URL and body for debugging
      print('Sending request to update status...');
      print('URL: $url');
      print('Body: $body');

      // Send the PUT request to update the status
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      // Log the response status code and body for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        setState(() {
          _selectedDate = DateTime.now(); // Default to today's date
    _vehicleOperationsFuture = _fetchVehicleOperations(date: _selectedDate);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status updated to $newStatus'),
        ));
      } else {
        throw Exception('Failed to update vehicle operation status. Response: ${response.body}');
      }
    } catch (error) {
      print('Error updating status: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to update status: $error'),
      ));
    }
  }

  // Delete Vehicle Operation
  Future<void> _deleteVehicleOperation(String operationId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.delete(
        Uri.parse('${Config.deleteVehicleOperationEndpoint}/$operationId'), // Endpoint to delete the operation
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
         _selectedDate = DateTime.now(); // Default to today's date
    _vehicleOperationsFuture = _fetchVehicleOperations(date: _selectedDate);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Vehicle operation deleted successfully!'),
        ));
      } else {
        throw Exception('Failed to delete vehicle operation');
      }
    } catch (error) {
      print('Error deleting operation: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to delete vehicle operation.'),
      ));
    }
  }

  // Show Delete Confirmation Dialog
  Future<void> _showDeleteConfirmationDialog(String operationId) async {
    showDialog(
      context: context,
      barrierDismissible: false, // User must confirm before closing
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this vehicle operation?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without deleting
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteVehicleOperation(operationId); // Proceed with deletion
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Status Kendaraan'),
      backgroundColor: Colors.blue,
      actions: [
        IconButton(
          icon: Icon(Icons.calendar_today),
          onPressed: _selectDate,
        ),
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: _resetDateFilter,
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_selectedDate != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.start, // Align to the left
              children: [
                Text(
                  'Data tanggal : ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                  style: TextStyle(
                    fontSize: 12, // Smaller text
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          SizedBox(height: 20),
          // Use Expanded to take available space for the list view
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _vehicleOperationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Belum ada kendaraan beroprasi.'));
                }

                final vehicleOperations = snapshot.data!;
                return ListView.builder(
                  itemCount: vehicleOperations.length,
                  itemBuilder: (context, index) {
                    final operation = vehicleOperations[index];
                    return _buildVehicleOperationCard(context, operation);
                  },
                );
              },
            ),
          ),
          SizedBox(height: 20),
          // Button stays at the bottom
          ElevatedButton(
            onPressed: () => _navigateToAddVehicleOperation(), // Navigate to add page
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
              textStyle: TextStyle(fontSize: 16),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text('Tambah Kendaraan', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


  // Build card for each vehicle operation
  Widget _buildVehicleOperationCard(BuildContext context, dynamic operation) {
     final DateTime operationDate = DateTime.parse(operation['operation_date']).toLocal(); // Convert to local time
    final String formattedDate = DateFormat('dd MMMM yyyy').format(operationDate);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 8,
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Text(
          'Nama: ${operation['vehicle_name']}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status with bold black text and colored status text
            Row(
              children: [
                Text(
                  'Status: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Keeping the "Status" text black and bold
                  ),
                ),
                Text(
                  '${operation['status']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: operation['status'] == 'Beroperasi' ? Colors.blue : Colors.red,
                  ),
                ),
              ],
            ),

            // Date in "dd MMMM yyyy" format
            Text(
              'Date: $formattedDate',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Toggle Button (running or unrunning)
            IconButton(
              icon: Icon(
                operation['status'] == 'Beroperasi' ? Icons.check_circle : Icons.remove_circle,
                color: operation['status'] == 'Beroperasi' ? Colors.blue : Colors.red,
              ),
              onPressed: () => _toggleStatus(operation['id'].toString(), operation['status']),
            ),
            // Delete Button with confirmation
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmationDialog(operation['id'].toString()), // Show confirmation dialog
            ),
          ],
        ),
      ),
    );
  }
}
