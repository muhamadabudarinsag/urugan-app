import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';

class CreateInvoicePage extends StatefulWidget {
  final Function refreshInvoices;

  const CreateInvoicePage({Key? key, required this.refreshInvoices}) : super(key: key);

  @override
  _CreateInvoicePageState createState() => _CreateInvoicePageState();
}

class _CreateInvoicePageState extends State<CreateInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> _suppliers = [];
  String? _selectedSupplierId;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(Duration(days: 30));
  List<dynamic> _dischargeData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  Future<void> _fetchSuppliers() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/suppliers'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _suppliers = jsonDecode(response.body);
        });
      }
    } catch (error) {
      print('Error fetching suppliers: $error');
    }
  }

  Future<void> _fetchDischargeData() async {
    if (_selectedSupplierId == null) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/vehicle-discharge/summary').replace(
          queryParameters: {
            'start_date': DateFormat('yyyy-MM-dd').format(_startDate),
            'end_date': DateFormat('yyyy-MM-dd').format(_endDate),
          },
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _dischargeData = jsonDecode(response.body);
        });
      }
    } catch (error) {
      print('Error fetching discharge data: $error');
    }
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/invoices'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'supplier_id': _selectedSupplierId,
          'due_date': DateFormat('yyyy-MM-dd').format(_dueDate),
          'start_period': DateFormat('yyyy-MM-dd').format(_startDate),
          'end_period': DateFormat('yyyy-MM-dd').format(_endDate),
          'items': _dischargeData.map((item) => {
            'material_name': item['material_name'],
            'total_volume': item['total_volume'],
            'unit_price': item['price_sell_per_m3'],
            'total_price': item['total_price'],
          }).toList(),
        }),
      );

      if (response.statusCode == 201) {
        widget.refreshInvoices();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice created successfully')),
        );
      } else {
        throw Exception('Failed to create invoice');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating invoice: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchDischargeData();
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(double.parse(amount.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Invoice'),
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
                  labelText: 'Select Supplier',
                  border: OutlineInputBorder(),
                ),
                value: _selectedSupplierId,
                items: _suppliers.map((supplier) {
                  return DropdownMenuItem<String>(
                    value: supplier['id'].toString(),
                    child: Text(supplier['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSupplierId = value;
                  });
                  _fetchDischargeData();
                },
                validator: (value) {
                  if (value == null) return 'Please select a supplier';
                  return null;
                },
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Period'),
                subtitle: Text(
                  '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectDateRange,
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Due Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_dueDate)),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectDueDate,
              ),
              SizedBox(height: 24),
              if (_dischargeData.isNotEmpty) ...[
                Text(
                  'Material Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _dischargeData.length,
                  itemBuilder: (context, index) {
                    final item = _dischargeData[index];
                    return Card(
                      child: ListTile(
                        title: Text(item['material_name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Volume: ${(item['total_volume'] / 1000000).toStringAsFixed(2)} m³'),
                            Text('Price per m³: ${_formatCurrency(item['price_sell_per_m3'])}'),
                            Text('Total: ${_formatCurrency(item['total_price'])}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _createInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Create Invoice', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
