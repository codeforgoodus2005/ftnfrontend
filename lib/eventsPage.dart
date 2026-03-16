import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:project/env.dart';
import 'package:project/eventSignup';
// import 'package:project/eventSignup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;

class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  List<Map<String, dynamic>> _selectedEvents = [];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  void _fetchEvents() async {
    try {
      final volunteerPrefs = await SharedPreferences.getInstance();
      final volunteerSessionToken =
          volunteerPrefs.getString('volunteer_sessionToken');
      const String apiBaseUrl = Env.apiBaseUrl;

      final response = await http.get(
        Uri.parse('$apiBaseUrl/reports/get_events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $volunteerSessionToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        List<Map<String, dynamic>> eventsList = [];

        for (var event in data) {
          eventsList.add({
            'eventId': event['EventId'],
            'eventName': event['eventName'],
            'eventDate': event['eventDate'],
          });
        }

        // Create a temporary map to store events
        // Map<DateTime, List<String>> tempEvents = {};
        Map<DateTime, List<Map<String, dynamic>>> tempEvents = {};

        // Process each event
        for (var event in eventsList) {
          // Parse the date and remove time component
          final date = DateTime.parse(event['eventDate']).toUtc();
          final dateKey = DateTime.utc(date.year, date.month, date.day);

          // Initialize the list for this date if it doesn't exist
          if (!tempEvents.containsKey(dateKey)) {
            tempEvents[dateKey] = [];
          }

          // Add the event name to the list for this date
          // tempEvents[dateKey]!.add(event['eventName']);
          tempEvents[dateKey]!.add({
            'eventId': event['eventId'],
            'eventName': event['eventName'],
          });
        }

        setState(() {
          _events = tempEvents;
        });
      } else {
        print('Failed to fetch events: ${response.statusCode}');
        // You might want to show a snackbar or other error indication to the user
      }
    } catch (e) {
      print('Error fetching events: $e');
      // Handle error appropriately
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    // Convert the provided day to UTC and remove time component for consistent comparison
    final dateKey = DateTime.utc(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events'),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime.now()
                .subtract(const Duration(days: 365)), // Show past year
            lastDay:
                DateTime.now().add(const Duration(days: 365)), // Show next year
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(_selectedEvents[index]['eventName']),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventSignupPage(
                          eventName: _selectedEvents[index]['eventName'],
                          eventId: _selectedEvents[index]['eventId'],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
