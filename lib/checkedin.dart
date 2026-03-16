import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckedInPage extends StatefulWidget {
  @override
  _CheckedInPageState createState() => _CheckedInPageState();
}

class _CheckedInPageState extends State<CheckedInPage> {
  List<Map<String, dynamic>> checkedInVolunteers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCheckedInVolunteers();
  }

  Future<void> _fetchCheckedInVolunteers() async {
    try {
      final adminPrefs = await SharedPreferences.getInstance();
      final adminSessionToken =
          adminPrefs.getString('admin_sessionToken') ?? '';
      const String apiBaseUrl = Env.apiBaseUrl;

      final response = await http.get(
        Uri.parse('$apiBaseUrl/reports/currentlyCheckedIn'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminSessionToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          checkedInVolunteers = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorPopup(context,
            'Failed to load checked-in volunteers data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorPopup(context, 'Error loading checked-in volunteers: $e');
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataTable() {
    if (checkedInVolunteers.isEmpty)
      return const Text("No volunteers currently checked in");

    return DataTable(
      columns: const [
        DataColumn(label: Text('Volunteer ID')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Check-In Time')),
      ],
      rows: checkedInVolunteers.map((volunteer) {
        return DataRow(
          cells: [
            DataCell(Text(volunteer['VolunteerID']?.toString() ?? 'N/A')),
            DataCell(Text(volunteer['Email'] ?? 'N/A')),
            DataCell(Text(volunteer['CheckInTime'] ?? 'N/A')),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFcddcd0),
      appBar: AppBar(
        title: const Text("Currently Checked-In Volunteers"),
        backgroundColor: const Color(0xFFcddcd0),
      ),
      body: Container(
        color: const Color(0xFFcddcd0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: isLoading
              ? const CircularProgressIndicator()
              : Container(
                  color: const Color(0xFFcddcd0),
                  padding: const EdgeInsets.all(16.0),
                  child: _buildDataTable(),
                ),
        ),
      ),
    );
  }
}
