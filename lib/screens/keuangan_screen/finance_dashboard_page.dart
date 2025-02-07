import 'package:flutter/material.dart';
import '../base_page.dart';
import '../../models/user_role.dart';
import 'rental_cost/rental_costs_page.dart';
import 'driver_cost/driver_costs_page.dart';
import 'office_operational_cost/office_operational_costs_page.dart';
import 'invoice_page.dart';
import 'invoice/invoice_list_page.dart'; // Add this import
import 'heavy_equipment_rental/heavy_equipment_rental_page.dart';
import 'heavy_equipment_fuel/heavy_equipment_fuel_page.dart'; // Add this import

class FinanceDashboardPage extends BasePage {
  const FinanceDashboardPage({super.key});

  @override
  String get title => 'Dashboard Keuangan';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: AppBar(
            toolbarHeight: 80,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pengelolaan Keuangan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundImage: AssetImage('assets/profile_picture.png'),
                    radius: 25,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildHeaderCard(context),
            SizedBox(height: 20),
            _buildInfoCard(
              title: 'Biaya Sewa Armada',
              icon: Icons.directions_car,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RentalCostsPage()),
                );
              },
            ),
            _buildInfoCard(
              title: 'Biaya Sewa Alat Berat',
              icon: Icons.construction,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HeavyEquipmentRentalPage()),
                );
              },
            ),
            _buildInfoCard(
              title: 'Biaya Solar Alat Berat',
              icon: Icons.local_gas_station,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HeavyEquipmentFuelPage()),
                );
              },
            ),
            _buildInfoCard(
              title: 'Biaya Supir',
              icon: Icons.person,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DriverCostsPage()),
                );
              },
            ),
            _buildInfoCard(
              title: 'Kebutuhan Operasional Kantor',
              icon: Icons.business,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OfficeOperationalCostsPage()),
                );
              },
            ),
            _buildInfoCard(
              title: 'Invoice Penagihan',
              icon: Icons.receipt,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InvoiceListPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.lightBlueAccent],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Kelola biaya dan invoice',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade100, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Icon(icon, size: 36, color: Colors.blue.shade700),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      color: Colors.blue.shade700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.blue.shade700),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool canAccess(UserRole role) {
    return role == UserRole.finance;
  }
}
