import "dart:convert";
import "package:flutter/material.dart";
import 'package:project/AdminReports.dart';
import "package:project/DocsPage.dart";
import "package:project/checkedin.dart";
import "package:project/create_events.dart";
import "package:project/env.dart";
import "package:http/http.dart" as http;
import "package:project/main.dart";
import "package:shared_preferences/shared_preferences.dart";

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({Key? key}) : super(key: key);
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  static const backgroundColor = Color(0xFFcddcd0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: backgroundColor,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.start,
            children: [
              _buildDashboardCard(
                title: "Arrow Attendance Report",
                icon: Icons.pie_chart,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminReports(),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                title: "Get CheckedIn Volunteers",
                icon: Icons.settings,
                onTap: () {
                  // Future feature
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckedInPage(),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                title: "Documents Page",
                icon: Icons.person,
                onTap: () {
                  // Future feature
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocsPage(),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                title: "Events Page",
                icon: Icons.person,
                onTap: () {
                  // Future feature
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateEventsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: backgroundColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton(
                onPressed: () {
                  _handleLogout(context);
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width / 3 - 20,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.blueGrey[200],
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.black),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final adminPrefs = await SharedPreferences.getInstance();
    final adminEmail = adminPrefs.getString('admin_email') ?? '';
    final adminSessionToken = adminPrefs.getString('admin_sessionToken') ?? '';
    const String apiBaseUrl = Env.apiBaseUrl;
    final Uri adminLogoutUrl = Uri.parse('$apiBaseUrl/auth/adminlogout');

    final http.Response response = await http.post(
      adminLogoutUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $adminSessionToken',
      },
      body: jsonEncode({
        'email': adminEmail,
      }),
    );

    if (response.statusCode == 200) {
      adminPrefs.remove('admin_sessionToken');
      // await adminPrefs.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MyApp(),
        ),
      );
    } else {
      _showErrorPopup(context, 'Logout failed: ${response.body}');
    }
  }

  Future<void> _showErrorPopup(BuildContext context, String message) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
