import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config.dart';
import 'add_bank_account_page.dart';
import 'edit_bank_account_page.dart';
import 'package:shimmer/shimmer.dart';

class BankAccountManagementPage extends StatefulWidget {
  const BankAccountManagementPage({Key? key}) : super(key: key);

  @override
  _BankAccountManagementPageState createState() => _BankAccountManagementPageState();
}

class _BankAccountManagementPageState extends State<BankAccountManagementPage> {
  late Future<List<dynamic>> _bankAccountsFuture;

  @override
  void initState() {
    super.initState();
    _bankAccountsFuture = _fetchBankAccounts();
  }

  Future<List<dynamic>> _fetchBankAccounts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/bank-accounts'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load bank accounts');
      }
    } catch (error) {
      print('Error fetching bank accounts: $error');
      throw Exception('Network error occurred');
    }
  }

  Future<void> _refreshBankAccounts() async {
    setState(() {
      _bankAccountsFuture = _fetchBankAccounts();
    });
  }

  Future<void> _deleteBankAccount(int id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.delete(
        Uri.parse('${Config.baseUrl}/bank-accounts/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _refreshBankAccounts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bank account deleted successfully')),
        );
      } else {
        throw Exception('Failed to delete bank account');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting bank account: $error')),
      );
    }
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this bank account?'),
          actions: [ <boltAction type="file" filePath="lib/screens/admin_screen/bank_management/bank_account_management_page.dart">
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBankAccount(id);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerEffect() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: Container(
              height: 100,
              width: double.infinity,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bank Account Management'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshBankAccounts,
                child: FutureBuilder<List<dynamic>>(
                  future: _bankAccountsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerEffect();
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No bank accounts found'));
                    }

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final bankAccount = snapshot.data![index];
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              bankAccount['bank_name'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Account Number: ${bankAccount['account_number']}'),
                                Text('Account Name: ${bankAccount['account_name']}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditBankAccountPage(
                                          bankAccount: bankAccount,
                                          refreshBankAccounts: _refreshBankAccounts,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(bankAccount['id']),
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
                    builder: (context) => AddBankAccountPage(
                      refreshBankAccounts: _refreshBankAccounts,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'Add Bank Account',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
