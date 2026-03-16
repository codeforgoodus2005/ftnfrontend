import 'dart:async';
import 'dart:convert';
// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DocsPage extends StatefulWidget {
  const DocsPage({Key? key}) : super(key: key);

  @override
  _DocsPageState createState() => _DocsPageState();
}

class _DocsPageState extends State<DocsPage> {
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

  Future<void> uploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        _showErrorSnackBar('No file data available');
        return;
      }

      setState(() {
        isLoading = true;
      });

      final uri = Uri.parse('$serverUrl/upload');
      final request = http.MultipartRequest('POST', uri);

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        _showSuccessSnackBar('File uploaded successfully');
        await fetchDocuments();
      } else {
        _showErrorSnackBar('Upload failed: ${response.body}');
      }
    } catch (error) {
      _showErrorSnackBar('Error uploading file: $error');
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

      // Try to launch the download URL directly
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

  Future<void> deleteDocument(String fileId) async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.delete(
        Uri.parse('$serverUrl/files/$fileId'),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('File deleted successfully');
        await fetchDocuments();
      } else {
        _showErrorSnackBar('Failed to delete file');
      }
    } catch (error) {
      _showErrorSnackBar('Error deleting file: $error');
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

  void _showSuccessSnackBar(String message) {
    print(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
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
                    'Your Documents',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload and manage your files',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : uploadDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoading)
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        Icon(Icons.upload_file, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isLoading ? 'Uploading...' : 'Upload New Document',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                  child: documents.isEmpty
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
                                'No documents found',
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
                                  Icons.insert_drive_file,
                                  color: Theme.of(context).primaryColor,
                                ),
                                title: Text(
                                  doc['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red[400],
                                  ),
                                  onPressed: () => deleteDocument(doc['id']),
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
