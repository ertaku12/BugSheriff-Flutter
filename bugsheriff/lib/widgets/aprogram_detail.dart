import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProgramDetailPage extends StatefulWidget {
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

  @override
  _ProgramDetailPageState createState() => _ProgramDetailPageState();
}

class _ProgramDetailPageState extends State<ProgramDetailPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _statusController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _descriptionController = TextEditingController(text: widget.description);
    _startDateController =
        TextEditingController(text: widget.applicationStartDate);
    _endDateController = TextEditingController(text: widget.applicationEndDate);
    _statusController = TextEditingController(text: widget.status);
  }

  Future<void> _updateProgram() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwt_token');

    final response = await http.put(
      Uri.parse('http://192.168.1.30:5000/admin/program/${widget.id}'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'application_start_date': _startDateController.text,
        'application_end_date': _endDateController.text,
        'status': _statusController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program updated successfully')),
      );
      Navigator.pop(context); // Close the screen after update
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update program')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Program'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextFormField(
              controller: _startDateController,
              decoration:
                  const InputDecoration(labelText: 'Start Date (mm-dd-yyyy)'),
            ),
            TextFormField(
              controller: _endDateController,
              decoration:
                  const InputDecoration(labelText: 'End Date (mm-dd-yyyy)'),
            ),
            DropdownButtonFormField<String>(
              value: _statusController.text.isNotEmpty
                  ? _statusController.text
                  : null,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(
                  value: 'Open',
                  child: Text('Open'),
                ),
                DropdownMenuItem(
                  value: 'Closed',
                  child: Text('Closed'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _statusController.text = value; // Update the controller value
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProgram,
              child: const Text('Update Program'),
            ),
          ],
        ),
      ),
    );
  }
}
