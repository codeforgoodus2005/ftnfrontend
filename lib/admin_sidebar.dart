import 'package:flutter/material.dart';
import 'package:project/AdminHomePage.dart';
import 'package:project/AdminReports.dart';

class AdminSideBar extends StatelessWidget {
  const AdminSideBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color:
            const Color(0xFFcddcd0), // Set the background color of the drawer
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFFcddcd0), // Make DrawerHeader the same color
              ),
              child: Text(
                "Welcome!",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                ),
              ),
            ),
            ListTile(
              title: const Text("Home"),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminHomePage()),
                );
              },
            ),
            ListTile(
              title: const Text("Reports"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminReports()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
