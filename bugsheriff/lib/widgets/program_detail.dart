import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

final logger = Logger();

void logInfo(String message) {
  logger.i(message);
}

void logError(String message) {
  logger.e(message);
}

class ProgramDetailPage extends StatelessWidget {
  final String id;
  final String name;
  final String description;
  final String applicationStartDate;
  final String applicationEndDate;
  final String status;

  const ProgramDetailPage({
    Key? key,
    required this.id,
    required this.name,
    required this.description,
    required this.applicationStartDate,
    required this.applicationEndDate,
    required this.status,
  }) : super(key: key);

  Future<void> _uploadReport(BuildContext context) async {
    // Select a PDF file using FilePicker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      // Prepare to upload the file
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'http://192.168.1.30:5000/upload'), // Replace with your actual upload endpoint
      );

      // Check if we are on the web platform
      if (kIsWeb) {
        // Upload using bytes instead of path
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else {
        // For non-web platforms, use the file path
        request.files.add(
          await http.MultipartFile.fromPath('file', file.path!),
        );
      }

      // Include the program ID in the request
      request.fields['program_id'] = id; // Program ID to send

      // Retrieve the JWT token from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jwtToken = prefs.getString('jwt_token');

      if (jwtToken != null && jwtToken.isNotEmpty) {
        // Add the JWT token to the request headers
        request.headers['Authorization'] = 'Bearer $jwtToken';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You need to login to view programs')),
        );
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Send the request
      var response = await request.send();

      // Check the response status
      if (response.statusCode == 200) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report uploaded successfully')),
        );
        logInfo('Report uploaded successfully');
      } else {
        // Read the response body to get the error message
        var responseBody = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseBody); // Decode the JSON
        var errorMessage = decodedResponse['message']; // Extract the message

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        logError('Failed to upload report: $errorMessage');
      }
    } else {
      logError('No file selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Description: $description'),
            SizedBox(height: 16),
            Text('Start Date: $applicationStartDate'),
            SizedBox(height: 16),
            Text('End Date: $applicationEndDate'),
            SizedBox(height: 16),
            Text('Status: $status'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  _uploadReport(context), // Pass context to the method
              child: Text('Upload Report (PDF)'),
            ),
          ],
        ),
      ),
    );
  }
}
