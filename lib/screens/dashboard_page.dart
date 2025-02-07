import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_mobile_app/screens/ground_screen/GroundDashboardPage.dart';
import 'admin_screen/admin_dashboard_page.dart';
import 'keuangan_screen/finance_dashboard_page.dart';
import 'history_page.dart';
import 'notifications_page.dart';
import 'account_page.dart';
import '../models/user_role.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DashboardPage extends StatefulWidget {
  final UserRole role;

  const DashboardPage({Key? key, required this.role}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final Map<UserRole, List<Widget>> _rolePagesMapping = {
    UserRole.admin: [
      const AdminDashboardPage(),
      const HistoryPage(),
      const NotificationsPage(),
      const AccountPage(),
    ],
    UserRole.finance: [
      const FinanceDashboardPage(),
      const HistoryPage(),
      const NotificationsPage(),
      const AccountPage(),
    ],
    UserRole.ground: [
      const GroundDashboardPage(),
      const HistoryPage(),
      const NotificationsPage(),
      const AccountPage(),
    ],
    UserRole.director: [const HistoryPage()],
    UserRole.investor: [const HistoryPage()],
  };

  late List<Widget> _availablePages;

  @override
  void initState() {
    super.initState();
    _setAvailablePages();
  }

  void _setAvailablePages() {
    _availablePages = _rolePagesMapping[widget.role] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _getCurrentPage()),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _getCurrentPage() {
    return _availablePages.isNotEmpty ? _availablePages[_selectedIndex] : Container();
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
       
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: _buildBottomNavItems(),
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.normal),
        unselectedLabelStyle: GoogleFonts.poppins(),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.lightBlue,
      ),
    );
  }

  List<BottomNavigationBarItem> _buildBottomNavItems() {
    return [
      BottomNavigationBarItem(
        icon: _buildNavIcon('assets/icons/home.svg', 0),
        label: 'Beranda',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon('assets/icons/activity.svg', 1),
        label: 'Aktifitas',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon('assets/icons/history.svg', 2),
        label: 'Histori',
      ),
      BottomNavigationBarItem(
        icon: _buildNavIcon('assets/icons/profile.svg', 3),
        label: 'Akun',
      ),
    ];
  }

  Widget _buildNavIcon(String assetPath, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(3),
      child: Transform.scale(
        scale: _selectedIndex == index ? 1.3 : 1.0,
        child: SvgPicture.asset(
          assetPath,
          height: 20,
          color: _selectedIndex == index ? Colors.white : Colors.white70,
        ),
      ),
    );
  }
}
