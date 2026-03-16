import "dart:async";
import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:project/VolDocPage.dart";
import "package:project/VolunteerSidebar.dart";
import "package:project/env.dart";
import "package:project/eventsPage.dart";
import "package:project/main.dart";
import "package:shared_preferences/shared_preferences.dart";

class VolunteerHomePage extends StatefulWidget {
  const VolunteerHomePage({Key? key}) : super(key: key);
  @override
  _VolunteerHomePageState createState() => _VolunteerHomePageState();
}

class _VolunteerHomePageState extends State<VolunteerHomePage> {
  static const backgroundColor = Color(0xFFcddcd0);
  String? _latestEventName;
  @override
  void initState() {
    super.initState();
    _loadLatestEventName();
  }

  Future<void> _loadLatestEventName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _latestEventName = prefs.getString('latest_event_name');
        print('Loaded event name: $_latestEventName');
      });
    } catch (e) {
      print('Error loading event name: $e');
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Volunteer Home Page"),
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
              CheckInButtonWidget(),
              _buildDashboardCard(
                title: "View Upcoming Events",
                icon: Icons.calendar_today,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventsPage(),
                    ),
                  );

                  // Navigate to view upcoming events
                },
              ),
              _buildDashboardCard(
                title: "View Documents",
                icon: Icons.person,
                onTap: () {
                  // Navigate to VolDocPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VolDocPage(),
                    ),
                  );
                },
              ),
              // New Notifications Widget
              if (_latestEventName != null)
                _buildDashboardCard(
                  title: "Notifications",
                  icon: Icons.notifications,
                  onTap: () {
                    // You can add navigation or additional functionality later
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('New Event: $_latestEventName')),
                    );
                  },
                  customColor: Colors.orange[200],
                  additionalWidget: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'New Event: $_latestEventName',
                      style: TextStyle(
                        color: Colors.blueGrey[700],
                        fontSize: 12,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      drawer: const VolunteerSidebar(),
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
    Color? customColor,
    Widget? additionalWidget,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width / 3 - 20,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
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
            Icon(icon, size: 40, color: Colors.blueGrey[700]),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            if (additionalWidget != null) additionalWidget,
          ],
        ),
      ),
    );
  }
}

Future<void> _handleLogout(BuildContext context) async {
  final volunteerPrefs = await SharedPreferences.getInstance();
  final volunteerEmail = volunteerPrefs.getString('volunteer_email');
  final volunteerSessionToken =
      volunteerPrefs.getString('volunteer_sessionToken');

  if (volunteerEmail != null && volunteerSessionToken != null) {
    try {
      // Check if the volunteer is checked in before logging out
      if (await _isCheckedIn(volunteerEmail)) {
        // Checkout the volunteer before logging out
        await _checkOut(volunteerEmail, volunteerSessionToken);
      }

      // Perform logout
      const String apiBaseUrl = Env.apiBaseUrl;
      final Uri volunteerLogoutUrl =
          Uri.parse('$apiBaseUrl/auth/volunteerlogout');
      await http.post(
        volunteerLogoutUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $volunteerSessionToken',
        },
        body: jsonEncode({'email': volunteerEmail}),
      );

      // Clear local storage and navigate to the main app
      // await volunteerPrefs.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
      );
    } catch (e) {
      _showErrorPopup(context, 'Logout failed: $e');
    }
  } else {
    _showErrorPopup(context, 'Volunteer email or session token not found');
  }
}

Future<bool> _isCheckedIn(String email) async {
  const String apiBaseUrl = Env.apiBaseUrl;
  final Uri checkInStatusUrl = Uri.parse('$apiBaseUrl/reports/ischeckedin');
  final response = await http.post(
    checkInStatusUrl,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['isCheckedIn'] as bool;
  } else {
    throw Exception(
        'Failed to check volunteer check-in status: ${response.body}');
  }
}

Future<void> _checkOut(String email, String sessionToken) async {
  const String apiBaseUrl = Env.apiBaseUrl;
  final Uri checkOutUrl = Uri.parse('$apiBaseUrl/auth/volunteercheckout');
  final response = await http.post(
    checkOutUrl,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $sessionToken',
    },
    body: jsonEncode({'email': email}),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to check out volunteer: ${response.body}');
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
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

class CheckInButtonWidget extends StatefulWidget {
  @override
  _CheckInButtonWidgetState createState() => _CheckInButtonWidgetState();
}

class _CheckInButtonWidgetState extends State<CheckInButtonWidget> {
  bool isCheckedIn = false;
  DateTime? checkInTime;
  Timer? timer;
  String elapsedTime = "00:00:00";
  String? volunteerEmail;

  @override
  void initState() {
    super.initState();
    _loadCheckInStatus();
  }

  void _startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        final duration = DateTime.now().difference(checkInTime!);
        elapsedTime = _formatDuration(duration);
      });
    });
  }

  Future<void> _loadCheckInStatus() async {
    final prefs = await SharedPreferences.getInstance();
    isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
    volunteerEmail = prefs.getString('volunteer_email');

    if (isCheckedIn) {
      final storedCheckInTime = prefs.getString('checkInTime');
      if (storedCheckInTime != null) {
        checkInTime = DateTime.parse(storedCheckInTime);
        _startTimer();
      }
    }
  }

  Future<void> _toggleCheckInStatus() async {
    final prefs = await SharedPreferences.getInstance();

    if (isCheckedIn) {
      await _checkOut();
      setState(() {
        isCheckedIn = false;
        timer?.cancel();
        elapsedTime = "00:00:00";
      });
      await prefs.setBool('isCheckedIn', false);
      await prefs.remove('checkInTime');
    } else {
      await _checkIn();
      checkInTime = DateTime.now();
      _startTimer();
      setState(() {
        isCheckedIn = true;
      });
      await prefs.setBool('isCheckedIn', true);
      await prefs.setString('checkInTime', checkInTime.toString());
    }
  }

  Future<void> _checkIn() async {
    if (volunteerEmail == null) {
      throw Exception("Volunteer email not found");
    }

    const String apiBaseUrl = Env.apiBaseUrl;
    final Uri checkInUrl = Uri.parse('$apiBaseUrl/auth/volunteercheckin');
    final response = await http.post(
      checkInUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': volunteerEmail}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to check in: ${response.body}");
    }
  }

  Future<void> _checkOut() async {
    if (volunteerEmail == null) {
      throw Exception("Volunteer email not found");
    }

    const String apiBaseUrl = Env.apiBaseUrl;
    final Uri checkOutUrl = Uri.parse('$apiBaseUrl/auth/volunteercheckout');
    final response = await http.post(
      checkOutUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': volunteerEmail}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to check out: ${response.body}");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCheckInStatus,
      child: Container(
        width: MediaQuery.of(context).size.width / 3 - 20,
        height: 140,
        decoration: BoxDecoration(
          color: isCheckedIn ? Colors.green[600] : Colors.white,
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
            Icon(
              isCheckedIn ? Icons.check_circle : Icons.access_time,
              size: 40,
              color: isCheckedIn ? Colors.white : Colors.blueGrey[700],
            ),
            const SizedBox(height: 10),
            Text(
              isCheckedIn ? 'Check Out' : 'Check In',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCheckedIn ? Colors.white : Colors.blueGrey[700],
              ),
            ),
            if (isCheckedIn)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  "Checked in for: $elapsedTime",
                  style: TextStyle(
                    color: isCheckedIn ? Colors.white : Colors.blueGrey[700],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
