// main.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/VolunteerHomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AdminHomePage.dart';
import 'env.dart';
import 'ui/app_button_styles.dart';
import 'package:flutter/gestures.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

void main() async {
  // await dotenv.load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key? key}) : super(key: key);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _handleVolunteerLogin(BuildContext context) async {
    try {
      const String apiBaseUrl = Env.apiBaseUrl;
      final Uri volunteerloginUrl =
          Uri.parse('$apiBaseUrl/auth/volunteerlogin');

      final http.Response response = await http.post(
        volunteerloginUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Login successful
        final responseData = jsonDecode(response.body);
        final volunteer_sessionToken = responseData['volunteer_sessionToken'];
        final volunteer = responseData['volunteer'];
        final volunteer_prefs = await SharedPreferences.getInstance();
        volunteer_prefs.setString(
            'volunteer_sessionToken', volunteer_sessionToken);
        volunteer_prefs.setString(
            'volunteer_userId', volunteer['volunteer_userId'].toString());
        volunteer_prefs.setString('volunteer_email', volunteer['email']);
        print('All keys in SharedPreferences: ${volunteer_prefs.getKeys()}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VolunteerHomePage()),
        );
      } else {
        // Login failed
        print('Login failed');
        print('Response body: ${response.body}');
        _showErrorDialog(context, 'Login failed', response.body);
      }
    } catch (e) {
      print('Error: $e');
      _showErrorDialog(context, 'Error', 'Error: $e');
    }
  }

  Future<void> _handleAdminLogin(BuildContext context) async {
    try {
      const String apiBaseUrl = Env.apiBaseUrl;
      final Uri loginUrl = Uri.parse('$apiBaseUrl/auth/adminlogin');

      final http.Response response = await http.post(
        loginUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': emailController.text,
          'password': passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Login successful
        final responseData = jsonDecode(response.body);
        final admin_sessionToken = responseData['admin_sessionToken'];
        final admin = responseData['admin'];
        final admin_prefs = await SharedPreferences.getInstance();
        await admin_prefs.clear();
        admin_prefs.setString('admin_sessionToken', admin_sessionToken);
        admin_prefs.setString('userId', admin['userId'].toString());
        admin_prefs.setString('admin_email', admin['email']);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminHomePage()),
        );
      } else {
        // Login failed
        print('Login failed');
        print('Response body: ${response.body}');
        _showErrorDialog(context, 'Login failed', response.body);
      }
    } catch (e) {
      print('Error: $e');
      _showErrorDialog(context, 'Error', 'Error: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/fortheneedlogo.png',
                        height: 120,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Login Page',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Email TextField inside a fixed box
                      Container(
                        width: 350, // Fixed width for the box
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.black),
                        ),
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Password TextField inside a fixed box
                      Container(
                        width: 350, // Fixed width for the box
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.black),
                        ),
                        child: TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Admin Login Button
                      SizedBox(
                        width: 350,
                        child: ElevatedButton(
                          onPressed: () => _handleAdminLogin(context),
                          style: AppButtonStyles.loginPrimary(),
                          child: const Text(
                            'Admin Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Volunteer Login Button
                      ElevatedButton(
                        onPressed: () {
                          _handleVolunteerLogin(context);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32.0,
                            vertical: 16.0,
                          ),
                          side: BorderSide(color: Colors.black),
                        ),
                        child: const Text('Volunteer checkIn'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
