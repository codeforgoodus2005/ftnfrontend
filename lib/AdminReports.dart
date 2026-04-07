import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/env.dart';
import 'package:flutter/gestures.dart';

class AdminReports extends StatefulWidget {
  const AdminReports({Key? key}) : super(key: key);

  @override
  _AdminReportsState createState() => _AdminReportsState();
}

class _AdminReportsState extends State<AdminReports> {
  List<Map<String, dynamic>> volunteerData = [];
  List<Map<String, dynamic>> participantData = [];
  List<Map<String, dynamic>> volunteerTrackedHoursData = [];
  List<Map<String, dynamic>> filteredData = [];

  String? _lastPressedButton;
  bool _isDataFetched = false;
  final TextEditingController _nameFilterController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

   @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildReportButton('Get Volunteer Tracked Hours', () {
                  _fetchVolunteerTrackedHoursData();
                  _lastPressedButton = 'volunteerTrackedHours';
                }),
                _buildReportButton('Get Arrow attendance details', () {
                  _fetchVolunteerData();
                  _lastPressedButton = 'allVolunteers';
                }),
                _buildReportButton('Get All Participants', () {
                  _fetchParticipantData();
                  _lastPressedButton = 'participants';
                }),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameFilterController,
              decoration: const InputDecoration(
                labelText: 'Filter by Name',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _applyFilter();
              },
            ),
             const SizedBox(height: 20),
            if (_lastPressedButton != null)
              ElevatedButton(
                onPressed: _showEmailDialog,
                child: Text(
                  'Email ${_lastPressedButton == 'volunteerTrackedHours' ? 'Volunteer Tracked Hours' : _lastPressedButton == 'allVolunteers' ? 'All Volunteers' : 'All Participants'} Report',
                ),
              ),
            Expanded(
  child: ScrollConfiguration(
    behavior: ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      },
    ),
    child: Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      notificationPredicate: (notif) => notif.depth == 1, 
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          // Add a bit of padding so the horizontal bar doesn't overlap the last row
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0), 
            child: _buildDataTable(),
          ),
        ),
      ),
    ),
  ),
),
          ],
        ),
      ),
    );
  }

  ElevatedButton _buildReportButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFcddcd0),
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.black),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      ),
      child: Text(text),
    );
  }

  void _applyFilter() {
    setState(() {
      final filterText = _nameFilterController.text.toLowerCase();
      if (filterText.isEmpty) {
        filteredData = _getDataForLastPressedButton();
      } else {
        filteredData = _getDataForLastPressedButton().where((item) {
          final name = item['VolunteerName'] ?? item['YouthName'] ?? '';
          return name.toString().toLowerCase().contains(filterText);
        }).toList();
      }
    });
  }

  List<Map<String, dynamic>> _getDataForLastPressedButton() {
    switch (_lastPressedButton) {
      case 'volunteerTrackedHours':
        return volunteerTrackedHoursData;
      case 'allVolunteers':
        return volunteerData;
      case 'participants':
        return participantData;
      default:
        return [];
    }
  }

  Widget _buildDataTable() {
    if (!_isDataFetched) return const SizedBox.shrink();
    if (filteredData.isEmpty) return const Text("No Data Available");

    return DataTable(
      columns: _lastPressedButton == 'volunteerTrackedHours'
          ? const [
              DataColumn(label: Text('Volunteer ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Total Hours Logged')),
              DataColumn(label: Text('Event Name')),
              DataColumn(label: Text('Event Date')),
              DataColumn(label: Text('Start Time')),
              DataColumn(label: Text('End Time')),
            ]
          : _lastPressedButton == 'allVolunteers'
              ? const [
                  DataColumn(label: Text('Account ID')),
                  DataColumn(label: Text('Full Name')),
                  DataColumn(label: Text('Totals 2021')),
                  DataColumn(label: Text('Totals 2022')),
                  DataColumn(label: Text('Totals 2023')),
                  DataColumn(label: Text('Totals 2024')),
                  DataColumn(label: Text('Totals 2025')),
                  DataColumn(label: Text('Legacy Event Count')),
                  DataColumn(label: Text('Award Level')),
                  DataColumn(label: Text('Program Status 2023')),
                  DataColumn(label: Text('# last 3 events 2023')),
                  DataColumn(label: Text('# last 6 2023')),
                  DataColumn(label: Text('5 In a Row 2023')),
                  DataColumn(label: Text('Program Status 2024')),
                  DataColumn(label: Text('# last 3 events 2024')),
                  DataColumn(label: Text('# last 6 2024')),
                  DataColumn(label: Text('5 In a Row 2024')),
                  DataColumn(label: Text('Program Status 2025')),
                  DataColumn(label: Text('# last 3 events 2025')),
                  DataColumn(label: Text('# last 6 2025')),
                  DataColumn(label: Text('5 In a Row 2025')),
                  DataColumn(label: Text('Totals 2026')),
                  DataColumn(label: Text('Program Status 2026')),
                  DataColumn(label: Text('# last 3 events 2026')),
                  DataColumn(label: Text('# last 6 2026')),
                  DataColumn(label: Text('5 In a Row 2026')),
                ]
              : const [
                  DataColumn(label: Text('Youth ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Age')),
                  DataColumn(label: Text('Mentee Status')),
                  DataColumn(label: Text('Interests')),
                  DataColumn(label: Text('Events Count')),
                  DataColumn(label: Text('First Signup Date')),
                ],
      rows: filteredData.skip(1).map((item) {
        List<String> interests = item['Interests']?.split(',') ?? [];
        String firstInterest = interests.isNotEmpty ? interests[0] : 'N/A';
        return DataRow(
            cells: _lastPressedButton == 'volunteerTrackedHours'
                ? [
                    DataCell(Text(item['VolunteerID']?.toString() ?? 'N/A')),
                    DataCell(Text(item['VolunteerName'] ?? 'N/A')),
                    DataCell(Text(item['Email'] ?? 'N/A')),
                    DataCell(
                        Text(item['TotalHoursLogged']?.toString() ?? 'N/A')),
                    DataCell(Text(item['EventName'] ?? 'N/A')),
                    DataCell(Text(item['EventDate'] ?? 'N/A')),
                    DataCell(Text(item['StartTime'] ?? 'N/A')),
                    DataCell(Text(item['EndTime'] ?? 'N/A')),
                  ]
                : _lastPressedButton == 'allVolunteers'
                    ? [
                        DataCell(Text(item['Account ID']?.toString() ?? 'N/A')),
                        DataCell(Text(item['Full Name (F)']?.toString() ?? 'N/A')),
                        DataCell(Text(item['Totals 2021']?.toString() ?? 'N/A')),
                        DataCell(Text(item['Totals 2022']?.toString() ?? 'N/A')),
                        DataCell(Text(item['Totals 2023']?.toString() ?? 'N/A')),
                        DataCell(Text(item['Totals 2024']?.toString() ?? 'N/A')),
                        DataCell(Text(item['Totals 2025']?.toString() ?? 'N/A')),
                        DataCell(Text(item['Legacy Event Count']?.toString() ?? 'N/A')),
                        DataCell(Text(item['Award Level']?.toString() ?? 'N/A')),
                        DataCell(Text(item['Program Status 2023']?.toString() ?? 'N/A')),
                        DataCell(Text(item['# last 3 events 2023']?.toString() ?? 'N/A')),
                        DataCell(Text(item['# last 6 2023']?.toString() ?? 'N/A')),
                        DataCell(Text(item['5 In a Row 2023']?.toString() ?? 'N/A')),
                        DataCell(Text(item['Program Status 2024']?.toString() ?? 'N/A')),
                        DataCell(Text(item['# last 3 events 2024']?.toString() ?? 'N/A')),
                        DataCell(Text(item['# last 6 2024']?.toString() ?? 'N/A')),
                        DataCell(Text(item['5 In a Row 2024']?.toString() ?? 'N/A')),
                        DataCell(Text(item['Program Status 2025']?.toString() ?? 'N/A')),
                        DataCell(Text(item['# last 3 events 2025']?.toString() ?? 'N/A')),
                        DataCell(Text(item['# last 6 2025']?.toString() ?? 'N/A')),
                        DataCell(Text(item['5 In a Row 2025']?.toString() ?? 'N/A')),
                        DataCell(Text(item['Totals 2026']?.toString() ?? 'N/A')),
                        DataCell(Text(item['Program Status 2026']?.toString() ?? 'N/A')),
                        DataCell(Text(item['# last 3 events 2026']?.toString() ?? 'N/A')),
                        DataCell(Text(item['# last 6 2026']?.toString() ?? 'N/A')),
                        DataCell(Text(item['5 In a Row 2026']?.toString() ?? 'N/A')),
                      ]
                    : [
                        DataCell(Text(item['YouthID']?.toString() ?? 'N/A')),
                        DataCell(Text(item['YouthName'] ?? 'N/A')),
                        DataCell(Text(item['Age']?.toString() ?? 'N/A')),
                        DataCell(
                            Text(item['MenteeStatus'] == 1 ? 'Yes' : 'No')),
                        DataCell(
                          Row(
                            children: [
                              Text(firstInterest), // Display first interest
                              IconButton(
                                icon: const Icon(Icons.arrow_drop_down),
                                onPressed: () =>
                                    _showInterestDropdownDialog(interests),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(
                            item['EventsParticipatedCount']?.toString() ??
                                'N/A')),
                        DataCell(Text(item['FirstSignupDate'] ?? 'N/A')),
                      ]);
      }).toList(),
    );
  }

  Future<void> _showInterestDropdownDialog(List<String> interests) async {
    String selectedInterest =
        interests.isNotEmpty ? interests[0] : 'No Interest';

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Other interests'),
          content: DropdownButton<String>(
            value: selectedInterest,
            onChanged: (String? newValue) {
              setState(() {
                selectedInterest = newValue ?? selectedInterest;
              });
              Navigator.of(context).pop();
            },
            items: interests.map<DropdownMenuItem<String>>((String interest) {
              return DropdownMenuItem<String>(
                value: interest,
                child: Text(interest),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _showEmailDialog() async {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Custom Date Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _startDateController,
                decoration: const InputDecoration(
                  labelText: 'Start Date (YYYY/MM/DD)',
                ),
              ),
              TextField(
                controller: _endDateController,
                decoration: const InputDecoration(
                  labelText: 'End Date (YYYY/MM/DD)',
                ),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: (_startDateController.text.isNotEmpty &&
                      _endDateController.text.isNotEmpty &&
                      _emailController.text.isNotEmpty)
                  ? () async {
                      Navigator.of(context).pop();
                      await _generateReport();
                    }
                  : null,
              child: const Text('Generate Report'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateReport() async {
    final String reportType = _lastPressedButton == 'volunteerTrackedHours'
        ? 'volunteerTrackedHours'
        : _lastPressedButton == 'allVolunteers'
            ? 'allVolunteers'
            : 'participants';
    final String startDate = _startDateController.text;
    final String endDate = _endDateController.text;
    final String email = _emailController.text;

    final adminPrefs = await SharedPreferences.getInstance();
    final adminSessionToken = adminPrefs.getString('admin_sessionToken') ?? '';
    const String apiBaseUrl = Env.apiBaseUrl;
    final response = await http.post(
      Uri.parse('$apiBaseUrl/reports/emailReport'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $adminSessionToken',
      },
      body: json.encode({
        'reportType': reportType,
        'startDate': startDate,
        'endDate': endDate,
        'email': email,
      }),
    );

    if (response.statusCode == 200) {
      // Display success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Report generated and emailed successfully!')),
      );
    } else {
      // Display error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.reasonPhrase}')),
      );
    }
  }

  Future<void> _fetchVolunteerData() async {
    try {
      final adminPrefs = await SharedPreferences.getInstance();
      final adminSessionToken =
          adminPrefs.getString('admin_sessionToken') ?? '';
      const String apiBaseUrl = Env.apiBaseUrl;
      final response = await http.post(
        Uri.parse('$apiBaseUrl/reports/ftnreport'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminSessionToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          volunteerData =
              List<Map<String, dynamic>>.from(json.decode(response.body));

          
          filteredData = volunteerData;
          _isDataFetched = true;
        });
      } else {
        _showErrorPopup(
            'Failed to load volunteer data: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorPopup('Error: $e');
    }
  }

  Future<void> _fetchParticipantData() async {
    try {
      final adminPrefs = await SharedPreferences.getInstance();
      final adminSessionToken =
          adminPrefs.getString('admin_sessionToken') ?? '';
      const String apiBaseUrl = Env.apiBaseUrl;
      final response = await http.post(
        Uri.parse('$apiBaseUrl/reports/participants'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminSessionToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          participantData =
              List<Map<String, dynamic>>.from(json.decode(response.body));
          filteredData = participantData;
          volunteerData = [];
          volunteerTrackedHoursData = [];
        });
      } else {
        _showErrorPopup(
            'Failed to load participant data: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorPopup('Error: $e');
    }
  }

  Future<void> _fetchVolunteerTrackedHoursData() async {
    try {
      final adminPrefs = await SharedPreferences.getInstance();
      final adminSessionToken =
          adminPrefs.getString('admin_sessionToken') ?? '';
      const String apiBaseUrl = Env.apiBaseUrl;
      final response = await http.post(
        Uri.parse('$apiBaseUrl/reports/volunteerTrackedHours'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $adminSessionToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          volunteerTrackedHoursData =
              List<Map<String, dynamic>>.from(json.decode(response.body));
          filteredData = volunteerTrackedHoursData;
          volunteerData = [];
          participantData = [];
        });
      } else {
        _showErrorPopup(
            'Failed to load tracked hours data: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorPopup('Error: $e');
    }
  }

  void _showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}