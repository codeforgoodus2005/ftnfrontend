import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class VolDocPage extends StatefulWidget {
  const VolDocPage({Key? key}) : super(key: key);

  @override
  _VolDocPageState createState() => _VolDocPageState();
}

class _VolDocPageState extends State<VolDocPage> {
  List<Map<String, dynamic>> documents = [];
  final String serverUrl = 'http://localhost:3001';
  bool isLoading = false;
  bool isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    checkAuthAndFetchDocuments();
  }

  Future<void> authenticate() async {
    try {
      final response = await http.get(Uri.parse('$serverUrl/auth/google'));
      if (response.statusCode == 200) {
        final authUrl = json.decode(response.body)['url'];
        await launchUrl(Uri.parse(authUrl));
      }
    } catch (error) {
      print('Authentication error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: $error')),
      );
    }
  }

  Future<void> checkAuthAndFetchDocuments() async {
    try {
      await fetchDocuments();
      setState(() {
        isAuthenticated = true;
      });
    } catch (error) {
      print('Error: $error');
      if (!mounted) return;
      if (!isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('Please authenticate first'),
                TextButton(
                  onPressed: authenticate,
                  child: const Text('Authenticate',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> fetchDocuments() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$serverUrl/files'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          documents = List<Map<String, dynamic>>.from(jsonData);
        });
      } else {
        throw Exception('Failed to fetch documents');
      }
    } catch (error) {
      _showErrorSnackBar('Failed to load documents: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> openDocument(String fileId, String fileName) async {
    try {
      setState(() {
        isLoading = true;
      });

      final downloadUrl = '$serverUrl/files/$fileId/download';

      if (await canLaunchUrl(Uri.parse(downloadUrl))) {
        await launchUrl(
          Uri.parse(downloadUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorSnackBar('Could not open file');
      }
    } catch (error) {
      _showErrorSnackBar('Error opening file: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    print(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Documents'),
        elevation: 0,
        backgroundColor: const Color(0xFFcddcd0),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFcddcd0),
              const Color(0xFFcddcd0).withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documentation',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View and download available documents',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : documents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.folder_open,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No documents available',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: documents.length,
                              itemBuilder: (context, index) {
                                final doc = documents[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: ListTile(
                                    onTap: () =>
                                        openDocument(doc['id'], doc['name']),
                                    leading: Icon(
                                      Icons.description,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    title: Text(
                                      doc['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.visibility,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
