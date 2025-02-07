import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';
import '../../../utils/idr_input_formatter.dart';

class HeavyEquipment {
  final String id;
  final String name;
  final String licensePlate;
  final double? pricePerDay;
  final double? pricePerMonth;
  final double? pricePerHour;

  HeavyEquipment({
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

class AddHeavyEquipmentRentalPage extends StatefulWidget {
  final Function refreshRentals;

  const AddHeavyEquipmentRentalPage({Key? key, required this.refreshRentals}) : super(key: key);

  @override
  _AddHeavyEquipmentRentalPageState createState() => _AddHeavyEquipmentRentalPageState();
}

class _AddHeavyEquipmentRentalPageState extends State<AddHeavyEquipmentRentalPage> {
  String? selectedEquipmentId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isFullDay = true;
  int _hours = 1;
  double _cost = 0.0;
  List<HeavyEquipment> equipment = [];
  HeavyEquipment? _selectedEquipment;
  RentalType _selectedRentalType = RentalType.day;

  @override
  void initState() {
    super.initState();
    _fetchEquipment();
  }

  Future<void> _fetchEquipment() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/heavy-equipment'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        setState(() {
          equipment = jsonList.map((json) => HeavyEquipment(
            id: json['id'].toString(),
            name: json['name'],
            licensePlate: json['license_plate'],
            pricePerDay: json['price_per_day'] != null ? 
                double.tryParse(json['price_per_day'].toString()) : null,
            pricePerMonth: json['price_per_month'] != null ? 
                double.tryParse(json['price_per_month'].toString()) : null,
            pricePerHour: json['hourly_rate'] != null ? 
                double.tryParse(json['hourly_rate'].toString()) : null,
          )).toList();
        });
      }
    } catch (error) {
      print('Error fetching equipment: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load equipment')),
      );
    }
  }

  void _updateCost() {
    if (_selectedEquipment == null) return;

    switch (_selectedRentalType) {
      case RentalType.range:
        if (_selectedEquipment!.pricePerDay != null) {
          int days = _endDate.difference(_startDate).inDays + 1;
          setState(() {
            _cost = _selectedEquipment!.pricePerDay! * days;
          });
        }
        break;
      
      case RentalType.month:
        if (_selectedEquipment!.pricePerMonth != null) {
          setState(() {
            _cost = _selectedEquipment!.pricePerMonth!;
          });
        }
        break;
      
      case RentalType.day:
        if (_isFullDay && _selectedEquipment!.pricePerDay != null) {
          setState(() {
            _cost = _selectedEquipment!.pricePerDay!;
          });
        } else if (!_isFullDay && _selectedEquipment!.pricePerHour != null) {
          setState(() {
            _cost = _selectedEquipment!.pricePerHour! * _hours;
          });
        }
        break;
    }
  }

  Future<void> _addRental() async {
  if (selectedEquipmentId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please select equipment')),
    );
    return;
  }

  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // Prepare rental data
    Map<String, dynamic> rentalData = {
      'equipment_id': selectedEquipmentId,
      'cost': _cost,
    };

    // Add type-specific data
    switch (_selectedRentalType) {
      case RentalType.range:
        rentalData.addAll({
          'rental_type': 'range',
          'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
          'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
          // Generate rental dates in the range and check for conflicts
          'rental_dates': List.generate(
            _endDate.difference(_startDate).inDays + 1,
            (index) => DateFormat('yyyy-MM-dd')
                .format(_startDate.add(Duration(days: index))),
          ),
        });
        break;

      case RentalType.month:
        rentalData.addAll({
          'rental_type': 'month',
          'rental_month': _selectedMonth,
          'rental_year': _selectedYear,
          // Generate rental dates for the selected month
          'rental_dates': List.generate(
            DateTime(_selectedYear, _selectedMonth + 1, 0).day,
            (index) => DateFormat('yyyy-MM-dd').format(
              DateTime(_selectedYear, _selectedMonth, index + 1),
            ),
          ),
        });
        break;

      case RentalType.day:
        rentalData.addAll({
          'rental_type': 'day',
          'rental_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'is_full_day': _isFullDay,
          'hours': _isFullDay ? null : _hours,
        });
        break;
    }

    // Send rental data to server
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/heavy-equipment-rentals'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(rentalData),
    );

    if (response.statusCode == 201) {
      widget.refreshRentals();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rental added successfully')),
      );
    } else if (response.statusCode == 409) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('A rental already exists for this date')),
      );
    } else {
      throw Exception('Failed to add rental: ${response.body}');
    }
  } catch (error) {
    print('Error adding rental: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error adding rental: $error')),
    );
  }
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
  int currentMonth = DateTime.now().month; // Get the current month
  
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
              items: List.generate(currentMonth, (index) { // Generate months up to the current month
                return DropdownMenuItem(
                  value: index + 1, // Month starts from 1
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
        title: Text('Add Heavy Equipment Rental'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Equipment',
                border: OutlineInputBorder(),
              ),
              value: selectedEquipmentId,
              items: equipment.map((HeavyEquipment equipment) {
                return DropdownMenuItem<String>(
                  value: equipment.id,
                  child: Text(equipment.name),
                );
              }).toList(),
              onChanged: (value) {
                final equipment = this.equipment.firstWhere((e) => e.id == value);
                setState(() {
                  selectedEquipmentId = value;
                  _selectedEquipment = equipment;
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
