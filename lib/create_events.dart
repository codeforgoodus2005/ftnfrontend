import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:project/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateEventsPage extends StatefulWidget {
  @override
  _CreateEventsPageState createState() => _CreateEventsPageState();
}

class _CreateEventsPageState extends State<CreateEventsPage> {
  static const backgroundColor = Color(0xFFcddcd0);
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _eventLocationController = TextEditingController();
  final _numberOfPeopleController = TextEditingController();
  DateTime? _selectedDate;
  String? _startTime;
  String? _endTime;
  // bool _signedWaiver = false;

  // Time options (30-minute intervals)
  final List<String> _timeOptions = List.generate(48, (index) {
    final time = DateTime(0, 1, 1, 0, 0).add(Duration(minutes: 30 * index));
    return DateFormat.jm().format(time);
  });

  // Date picker
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate:
          DateTime.now().add(const Duration(days: 180)), // 6 months from today
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an event date')),
        );
        return;
      }

      // Convert startTime and endTime to 24-hour format
      String? convertTo24Hour(String? time) {
        if (time == null) return null;
        final parsedTime = DateFormat.jm().parse(time); // Parse AM/PM time
        return DateFormat.Hms().format(parsedTime); // Convert to HH:mm:ss
      }

      final eventData = {
        'eventName': _eventNameController.text,
        'eventDate': _selectedDate?.toIso8601String(),
        'startTime': convertTo24Hour(_startTime), // Convert here
        'endTime': convertTo24Hour(_endTime), // Convert here
        'description': _eventDescriptionController.text,
        'eventLocation': _eventLocationController.text,
        'numberOfPeople': int.tryParse(_numberOfPeopleController.text) ?? 0,
      };

      _insertEventData(eventData);

      // print('Event Data: $eventData');

      _formKey.currentState!.reset();
      setState(() {
        _selectedDate = null;
        _startTime = null;
        _endTime = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event created successfully!')),
      );
    }
  }


  Future<void> _insertEventData(Map<String, dynamic> eventData) async {
    // Make API call to the backend route
    final adminPrefs = await SharedPreferences.getInstance();
    final adminSessionToken = adminPrefs.getString('admin_sessionToken') ?? '';
    const String apiBaseUrl = Env.apiBaseUrl;
    final response = await http.post(
      Uri.parse('$apiBaseUrl/reports/insertEventdata'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $adminSessionToken',
      },
      body: json.encode(eventData),
    );

    if (response.statusCode == 200) {
      // Save the latest event name to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('latest_event_name', eventData['eventName']);

      String? savedName = prefs.getString('latest_event_name');
      print('Saved event name: $savedName');
      print('All keys in SharedPreferences: ${prefs.getKeys()}');
      // Display success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('inserted the event data successfully!')),
      );
    } else {
      // Display error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }


  List<String> _getFilteredEndTimeOptions(String? startTime) {
    if (startTime == null) return [];

    final parsedStartTime = DateFormat.jm().parse(startTime);
    return _timeOptions.where((time) {
      final parsedEndTime = DateFormat.jm().parse(time);
      return parsedEndTime.isAfter(parsedStartTime);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Create Event'),
        backgroundColor: backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Name
              TextFormField(
                controller: _eventNameController,
                decoration: InputDecoration(
                  labelText: 'Event Name*',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the event name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Event Date
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding:
                      EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Select Date*'
                            : DateFormat.yMMMd().format(_selectedDate!),
                        style: TextStyle(fontSize: 16),
                      ),
                      Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Start Time
              DropdownButtonFormField<String>(
                value: _startTime,
                decoration: InputDecoration(
                  labelText: 'Start Time*',
                  border: OutlineInputBorder(),
                ),
                items: _timeOptions
                    .map((time) => DropdownMenuItem(
                          value: time,
                          child: Text(time),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _startTime = value;
                    _endTime = null; // Reset end time when start time changes
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a start time';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // End Time
              DropdownButtonFormField<String>(
                value: _endTime,
                decoration: InputDecoration(
                  labelText: 'End Time*',
                  border: OutlineInputBorder(),
                ),
                items: _getFilteredEndTimeOptions(_startTime)
                    .map((time) => DropdownMenuItem(
                          value: time,
                          child: Text(time),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _endTime = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an end time';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Event Description
              TextFormField(
                controller: _eventDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Event Description*',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the event description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // SizedBox(height: 16),
              TextFormField(
                controller: _eventLocationController,
                decoration: InputDecoration(labelText: 'Event Location*'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter the event location' : null,
              ),

              SizedBox(height: 16),

              // Number of People
              TextFormField(
                controller: _numberOfPeopleController,
                decoration: InputDecoration(
                  labelText: 'Number of People Required*',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of people required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('Create Event'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
