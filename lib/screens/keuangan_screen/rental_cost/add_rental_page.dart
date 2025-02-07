import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';
import 'idr_input_formatter.dart';

class Vehicle {
  final String id;
  final String name;
  final String licensePlate;
  final double? pricePerDay;
  final double? pricePerMonth;
  final double? pricePerHour;

  Vehicle({
    required this.id, 
    required this.name, 
    required this.licensePlate,
    this.pricePerDay,
    this.pricePerMonth,
    this.pricePerHour,
  });
}

enum RentalType {
  range,
  month,
  day
}

class AddRentalPage extends StatefulWidget {
  final Function refreshRentals;

  const AddRentalPage({super.key, required this.refreshRentals});

  @override
  _AddRentalPageState createState() => _AddRentalPageState();
}

class _AddRentalPageState extends State<AddRentalPage> {
  String? selectedVehicleId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isFullDay = true;
  int _hours = 1;
  double _cost = 0.0;
  List<Vehicle> vehicles = [];
  String? selectedVehicleLicensePlate;
  RentalType _selectedRentalType = RentalType.day;
  Vehicle? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(Config.getVehiclesEndpoint),
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
            pricePerDay: json['price_per_day'] != null ? 
                double.tryParse(json['price_per_day'].toString()) : null,
            pricePerMonth: json['price_per_month'] != null ? 
                double.tryParse(json['price_per_month'].toString()) : null,
            pricePerHour: json['price_per_hour'] != null ? 
                double.tryParse(json['price_per_hour'].toString()) : null,
          )).toList();
        });
      } else {
        throw Exception('Failed to load vehicles');
      }
    } catch (error) {
      print('Error fetching vehicles: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load vehicles')),
      );
    }
  }

  void _updateCost() {
    if (_selectedVehicle == null) return;

    switch (_selectedRentalType) {
      case RentalType.range:
        int days = _endDate.difference(_startDate).inDays + 1;
        if (_selectedVehicle!.pricePerDay != null) {
          setState(() {
            _cost = _selectedVehicle!.pricePerDay! * days;
          });
        }
        break;
      
      case RentalType.month:
        if (_selectedVehicle!.pricePerMonth != null) {
          setState(() {
            _cost = _selectedVehicle!.pricePerMonth!;
          });
        }
        break;
      
      case RentalType.day:
        if (_isFullDay && _selectedVehicle!.pricePerDay != null) {
          setState(() {
            _cost = _selectedVehicle!.pricePerDay!;
          });
        } else if (!_isFullDay && _selectedVehicle!.pricePerHour != null) {
          setState(() {
            _cost = _selectedVehicle!.pricePerHour! * _hours;
          });
        }
        break;
    }
  }

  Future<void> _addRental() async {
    if (selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    switch (_selectedRentalType) {
      case RentalType.range:
        // Handle date range rental - create multiple entries
        DateTime currentDate = _startDate;
        while (currentDate.isBefore(_endDate.add(Duration(days: 1)))) {
          final response = await http.post(
            Uri.parse(Config.addRentalEndpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'vehicle_id': selectedVehicleId,
              'cost': _selectedVehicle!.pricePerDay,
              'rental_date': DateFormat('yyyy-MM-dd').format(currentDate),
            }),
          );

          if (response.statusCode != 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add rental for ${DateFormat('yyyy-MM-dd').format(currentDate)}')),
            );
            return;
          }
          currentDate = currentDate.add(Duration(days: 1));
        }
        break;

      case RentalType.month:
        // Calculate days in selected month
        int daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
        double dailyCost = (_selectedVehicle!.pricePerMonth ?? 0) / daysInMonth;

        // Create entry for each day of the month
        for (int day = 1; day <= daysInMonth; day++) {
          DateTime currentDate = DateTime(_selectedYear, _selectedMonth, day);
          final response = await http.post(
            Uri.parse(Config.addRentalEndpoint),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'vehicle_id': selectedVehicleId,
              'cost': dailyCost,
              'rental_date': DateFormat('yyyy-MM-dd').format(currentDate),
            }),
          );

          if (response.statusCode != 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to add rental for ${DateFormat('yyyy-MM-dd').format(currentDate)}')),
            );
            return;
          }
        }
        break;

      case RentalType.day:
        final response = await http.post(
          Uri.parse(Config.addRentalEndpoint),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'vehicle_id': selectedVehicleId,
            'cost': _isFullDay ? _selectedVehicle!.pricePerDay : (_selectedVehicle!.pricePerHour! * _hours),
            'rental_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          }),
        );

        if (response.statusCode != 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add daily rental')),
          );
          return;
        }
        break;
    }

    widget.refreshRentals();
    Navigator.pop(context);
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _updateCost();
      });
    }
  }

  Widget _buildRentalTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rental Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        SegmentedButton<RentalType>(
          segments: [
            ButtonSegment(
              value: RentalType.range,
              label: Text('Date Range'),
              icon: Icon(Icons.date_range),
            ),
            ButtonSegment(
              value: RentalType.month,
              label: Text('Monthly'),
              icon: Icon(Icons.calendar_month),
            ),
            ButtonSegment(
              value: RentalType.day,
              label: Text('Daily'),
              icon: Icon(Icons.today),
            ),
          ],
          selected: {_selectedRentalType},
          onSelectionChanged: (Set<RentalType> newSelection) {
            setState(() {
              _selectedRentalType = newSelection.first;
              _updateCost();
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text('Date Range'),
          subtitle: Text(
            '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
          ),
          trailing: Icon(Icons.calendar_today),
          onTap: () => _selectDateRange(context),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Month',
                  border: OutlineInputBorder(),
                ),
                value: _selectedMonth,
                items: List.generate(DateTime.now().month, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(DateFormat('MMMM').format(DateTime(2024, index + 1))),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    _selectedMonth = value!;
                    _updateCost();
                  });
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                value: _selectedYear,
                items: [DateTime.now().year].map((year) {
                  return DropdownMenuItem(value: year, child: Text(year.toString()));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value!;
                    _updateCost();
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text('Full Day'),
          value: _isFullDay,
          onChanged: (bool value) {
            setState(() {
              _isFullDay = value;
              _updateCost();
            });
          },
        ),
        if (!_isFullDay)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Number of Hours',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _hours.toString(),
                  onChanged: (value) {
                    setState(() {
                      _hours = int.tryParse(value) ?? 1;
                      _updateCost();
                    });
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Armada', style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Pilih Kendaraan',
                border: OutlineInputBorder(),
              ),
              value: selectedVehicleId,
              items: vehicles.map((Vehicle vehicle) {
                return DropdownMenuItem<String>(
                  value: vehicle.id,
                  child: Text('${vehicle.name} (${vehicle.licensePlate})'),
                );
              }).toList(),
              onChanged: (value) {
                final vehicle = vehicles.firstWhere((v) => v.id == value);
                setState(() {
                  selectedVehicleId = value;
                  selectedVehicleLicensePlate = vehicle.licensePlate;
                  _selectedVehicle = vehicle;
                  _updateCost();
                });
              },
            ),
            SizedBox(height: 24),
            
            _buildRentalTypeSelector(),
            SizedBox(height: 24),

            if (_selectedRentalType == RentalType.range)
              _buildDateRangeSelector()
            else if (_selectedRentalType == RentalType.month)
              _buildMonthSelector()
            else if (_selectedRentalType == RentalType.day)
              _buildDaySelector(),

            SizedBox(height: 24),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Cost:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(_cost),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _addRental,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'Add Rental',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
