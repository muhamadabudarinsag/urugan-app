import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';
import '../../../utils/idr_input_formatter.dart';

enum CostType {
  daily,
  selectedDate,
  monthly
}

class AddDriverCostPage extends StatefulWidget {
  @override
  _AddDriverCostPageState createState() => _AddDriverCostPageState();
}

class _AddDriverCostPageState extends State<AddDriverCostPage> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> _drivers = [];
  String? _selectedDriverId;
  CostType _costType = CostType.daily;
  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  double _amount = 0.0;
  bool _isLoading = false;
  double? _driverDailyRate;
  double? _driverMonthlyRate;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/drivers'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _drivers = jsonDecode(response.body);
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading drivers: $error')),
      );
    }
  }

  void _updateAmount() {
    if (_selectedDriverId == null) return;

    final selectedDriver = _drivers.firstWhere(
      (driver) => driver['id'].toString() == _selectedDriverId,
      orElse: () => null,
    );

    if (selectedDriver != null) {
      _driverDailyRate = double.parse(selectedDriver['price_per_day'].toString());
      _driverMonthlyRate = double.parse(selectedDriver['price_per_month'].toString());

      setState(() {
        switch (_costType) {
          case CostType.daily:
            _amount = _driverDailyRate ?? 0;
            break;
          case CostType.selectedDate:
            int days = _endDate.difference(_startDate).inDays + 1;
            _amount = (_driverDailyRate ?? 0) * days;
            break;
          case CostType.monthly:
            _amount = _driverMonthlyRate ?? 0;
            break;
        }
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

      List<DateTime> datesToAdd = [];

      // Generate dates based on cost type
      switch (_costType) {
        case CostType.daily:
          datesToAdd = [_selectedDate];
          break;
        case CostType.selectedDate:
          for (var date = _startDate;
              date.isBefore(_endDate.add(Duration(days: 1)));
              date = date.add(Duration(days: 1))) {
            datesToAdd.add(date);
          }
          break;
        case CostType.monthly:
          int daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
          for (int i = 1; i <= daysInMonth; i++) {
            datesToAdd.add(DateTime(_selectedYear, _selectedMonth, i));
          }
          break;
      }

      // Check for existing dates
      List<DateTime> existingDates = [];
      for (var date in datesToAdd) {
        final checkResponse = await http.get(
          Uri.parse('${Config.baseUrl}/driver-costs/check-date')
              .replace(queryParameters: {
            'driver_id': _selectedDriverId,
            'date': DateFormat('yyyy-MM-dd').format(date),
          }),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (checkResponse.statusCode == 200) {
          final data = jsonDecode(checkResponse.body);
          if (data['exists']) {
            existingDates.add(date);
          }
        }
      }

      // If there are existing dates, show warning dialog
      if (existingDates.isNotEmpty) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Duplicate Dates Found'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('The following dates already have entries:'),
                    SizedBox(height: 8),
                    ...existingDates.map((date) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• ${DateFormat('dd MMM yyyy').format(date)}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )),
                    SizedBox(height: 16),
                    Text('These dates will be skipped. Continue with remaining dates?'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text('Continue'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        );

        if (shouldContinue != true) {
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Remove existing dates
        datesToAdd.removeWhere((date) =>
            existingDates.any((existingDate) =>
                date.year == existingDate.year &&
                date.month == existingDate.month &&
                date.day == existingDate.day));
      }

      if (datesToAdd.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All selected dates already have entries')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Add entries for remaining dates
      int successCount = 0;
      for (var date in datesToAdd) {
        final response = await http.post(
          Uri.parse('${Config.baseUrl}/driver-costs'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'driver_id': _selectedDriverId,
            'cost_type': _costType.toString().split('.').last,
            'amount': _costType == CostType.monthly ? _amount / datesToAdd.length : _amount,
            'date': DateFormat('yyyy-MM-dd').format(date),
          }),
        );

        if (response.statusCode == 201) {
          successCount++;
        }
      }

      String message = 'Added $successCount new entries.';
      if (existingDates.isNotEmpty) {
        message += ' Skipped ${existingDates.length} existing entries.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding driver costs: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateAmount();
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _updateAmount();
      });
    }
  }

  Widget _buildRentalTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cost Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        SegmentedButton<CostType>(
          segments: [
            ButtonSegment(
              value: CostType.daily,
              label: Text('Single Day'),
              icon: Icon(Icons.calendar_today),
            ),
            ButtonSegment(
              value: CostType.selectedDate,
              label: Text('Date Range'),
              icon: Icon(Icons.date_range),
            ),
            ButtonSegment(
              value: CostType.monthly,
              label: Text('Monthly'),
              icon: Icon(Icons.calendar_month),
            ),
          ],
          selected: {_costType},
          onSelectionChanged: (Set<CostType> newSelection) {
            setState(() {
              _costType = newSelection.first;
              _updateAmount();
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    switch (_costType) {
      case CostType.daily:
        return ListTile(
          title: Text('Select Date'),
          subtitle: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
          trailing: Icon(Icons.calendar_today),
          onTap: _selectDate,
        );
      case CostType.selectedDate:
        return ListTile(
          title: Text('Date Range'),
          subtitle: Text(
            '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
          ),
          trailing: Icon(Icons.calendar_today),
          onTap: _selectDateRange,
        );
      case CostType.monthly:
        return _buildMonthSelector();
    }
  }

  Widget _buildMonthSelector() {
    int currentMonth = DateTime.now().month;
    
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
                items: List.generate(currentMonth, (index) {
                  return DropdownMenuItem(
                    value: index + 1,
                    child: Text(DateFormat('MMMM').format(DateTime(2024, index + 1))),
                  );
                }),
                onChanged: (value) {
                  setState(() {
                    _selectedMonth = value!;
                    _updateAmount();
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
                    _updateAmount();
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
        title: Text('Add Driver Cost'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Select Driver',
                  border: OutlineInputBorder(),
                ),
                value: _selectedDriverId,
                items: _drivers.map((driver) {
                  return DropdownMenuItem<String>(
                    value: driver['id'].toString(),
                    child: Text(driver['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDriverId = value;
                    _updateAmount();
                  });
                },
                validator: (value) {
                  if (value == null) return 'Please select a driver';
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              _buildRentalTypeSelector(),
              SizedBox(height: 24),

              _buildDateSelector(),
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
                        ).format(_amount),
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
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Submit', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
