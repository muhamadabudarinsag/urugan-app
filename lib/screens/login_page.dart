import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Untuk SocketException
import 'dashboard_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../config.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _checkLoginStatus(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        return _buildLoginForm(context);
      },
    );
  }

  Future<void> _checkLoginStatus(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? loginTime = prefs.getInt('loginTime');
    String? roleString = prefs.getString('userRole');

    if (loginTime != null && roleString != null) {
      if (DateTime.now().millisecondsSinceEpoch - loginTime < 86400000) {
        UserRole role = _getUserRole(roleString);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage(role: role)),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  UserRole _getUserRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'finance':
        return UserRole.finance;
      case 'ground':
        return UserRole.ground;
      case 'director':
        return UserRole.director;
      case 'investor':
        return UserRole.investor;
      default:
        return UserRole.investor; // Fallback
    }
  }

  Widget _buildLoginForm(BuildContext context) {
    final TextEditingController _usernameController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    String _message = '';

    Future<void> _login() async {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        _showNoConnectionDialog(context);
        return;
      }

      try {
        final response = await http.post(
          Uri.parse(Config.getLoginEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': 'bismillahbhqA2lnx9m',
          },
          body: jsonEncode({
            'username': _usernameController.text,
            'password': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          String token = responseData['token'];
          String roleString = responseData['role'];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setInt('loginTime', DateTime.now().millisecondsSinceEpoch);
          await prefs.setString('userRole', roleString);
          await prefs.setString('token', token);

          UserRole role = _getUserRole(roleString);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => DashboardPage(role: role)),
            (Route<dynamic> route) => false,
          );
        } else {
          _showErrorSnackBar(context, 'Invalid username or password');
        }
      } catch (e) {
        if (e is SocketException) {
          _showNoConnectionDialog(context);
        } else {
          _showErrorSnackBar(context, 'Network error: ${e.toString()}');
        }
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blueAccent.shade100,
              Colors.blueAccent.shade400,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/splash.png',
                  height: 80,
                ),
                SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8), // Transparansi
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Selamat Datang!',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        SizedBox(height: 30),
                        _buildTextField('Username', _usernameController, false),
                        SizedBox(height: 20),
                        _buildTextField('Password', _passwordController, true),
                        SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: Colors.blue.shade700,
                            elevation: 5,
                          ),
                          child: Text(
                            'Login',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          _message,
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoConnectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Internet Connection'),
          content: Text('Please turn on your internet connection to proceed.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildTextField(String label, TextEditingController controller, bool obscureText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        labelText: label,
        labelStyle: TextStyle(color: Colors.blue.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(
          label == 'Username' ? Icons.person : Icons.lock,
          color: Colors.blue.shade700,
        ),
      ),
      obscureText: obscureText,
    );
  }
}
