import 'package:flutter/material.dart';
import 'notepad_screen.dart'; // ✅ Note Pad screen import

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Routes for bottom nav
  static const List<String> _routes = [
    '/dashboard', // Home/Dashboard
    '/inventory',
    '/salesHistory',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigate only if not dashboard
    if (_routes[index] != '/dashboard') {
      Navigator.pushNamed(context, _routes[index]);
    }
  }

  Widget card(String title, IconData icon, String route) {
    return GestureDetector(
      onTap: () {
        if (route == '/notepad') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NotePadScreen()), // ✅ Note Pad
          );
        } else {
          Navigator.pushNamed(context, route);
        }
      },
      child: Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.blue.shade100, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.lightBlue.shade200, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: Colors.black),
              ),
              SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skyBlue = Colors.lightBlue[400];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventory Dashboard',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: skyBlue,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16),
            card('Inventory', Icons.inventory, '/inventory'),
            card('Sales', Icons.point_of_sale, '/sales'),
            card('Sales History', Icons.history, '/salesHistory'),
            card('Note Pad', Icons.note, '/notepad'), // ✅ Note Pad card
            SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: skyBlue,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,   // Selected icon black
        unselectedItemColor: Colors.white, // Unselected icons white
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Sales History',
          ),
        ],
      ),
    );
  }
}
