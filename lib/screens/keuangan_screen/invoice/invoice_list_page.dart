import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../config.dart';
import 'create_invoice_page.dart';
import 'package:printing/printing.dart';
import 'invoice_pdf.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({Key? key}) : super(key: key);

  @override
  _InvoiceListPageState createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> {
  late Future<List<dynamic>> _invoicesFuture;

  @override
  void initState() {
    super.initState();
    _invoicesFuture = _fetchInvoices();
  }

  Future<List<dynamic>> _fetchInvoices() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/invoices'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load invoices');
      }
    } catch (error) {
      print('Error fetching invoices: $error');
      throw Exception('Network error occurred');
    }
  }

  Future<void> _refreshInvoices() async {
    setState(() {
      _invoicesFuture = _fetchInvoices();
    });
  }

  Future<void> _updateInvoiceStatus(int invoiceId, String newStatus) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('${Config.baseUrl}/invoices/$invoiceId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        _refreshInvoices();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice status updated successfully')),
        );
      } else {
        throw Exception('Failed to update invoice status');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating invoice status: $error')),
      );
    }
  }

  Future<void> _handlePDFAction(String action, Map<String, dynamic> invoice) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/invoices/${invoice['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final invoiceData = jsonDecode(response.body);
        final pdfBytes = await InvoicePDF.generate(
          invoice: invoiceData,
          items: invoiceData['items'] ?? [],
        );

        if (action == 'view') {
          await Printing.layoutPdf(
            onLayout: (format) => pdfBytes,
          );
        } else if (action == 'download') {
          await Printing.sharePdf(
            bytes: pdfBytes,
            filename: 'invoice_${invoice['invoice_number']}.pdf',
          );
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error handling PDF: $error')),
      );
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(num.parse(amount.toString()));
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice Penagihan'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshInvoices,
                child: FutureBuilder<List<dynamic>>(
                  future: _invoicesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No invoices found'));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final invoice = snapshot.data![index];
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              'Invoice #${invoice['invoice_number']}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Supplier: ${invoice['supplier_name']}'),
                                Text('Due Date: ${DateFormat('dd MMM yyyy').format(DateTime.parse(invoice['due_date']))}'),
                                Text('Amount: ${_formatCurrency(invoice['total_amount'])}'),
                                Row(
                                  children: [
                                    Text('Status: '),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(invoice['status']),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        invoice['status'].toUpperCase(),
                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(Icons.visibility),
                                          SizedBox(width: 8),
                                          Text('View PDF'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'download',
                                      child: Row(
                                        children: [
                                          Icon(Icons.download),
                                          SizedBox(width: 8),
                                          Text('Download'),
                                        ],
                                      ),
                                    ),
                                    if (invoice['status'] == 'draft') ...[
                                      PopupMenuItem(
                                        value: 'sent',
                                        child: Row(
                                          children: [
                                            Icon(Icons.send),
                                            SizedBox(width: 8),
                                            Text('Mark as Sent'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (invoice['status'] == 'sent') ...[
                                      PopupMenuItem(
                                        value: 'paid',
                                        child: Row(
                                          children: [
                                            Icon(Icons.payment),
                                            SizedBox(width: 8),
                                            Text('Mark as Paid'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    PopupMenuItem(
                                      value: 'cancelled',
                                      child: Row(
                                        children: [
                                          Icon(Icons.cancel),
                                          SizedBox(width: 8),
                                          Text('Cancel Invoice'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'view' || value == 'download') {
                                      _handlePDFAction(value.toString(), invoice);
                                    } else {
                                      _updateInvoiceStatus(invoice['id'], value.toString());
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateInvoicePage(
                      refreshInvoices: _refreshInvoices,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'Create New Invoice',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
