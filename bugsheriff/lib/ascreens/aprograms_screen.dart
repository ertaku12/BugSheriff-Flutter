import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../aleft_sidebar.dart'; // Sol menüyü import edin
import '../widgets/aprogram_detail.dart'; // Program detay sayfasını import edin

class aProgramsPage extends StatefulWidget {
  const aProgramsPage({super.key});

  @override
  _ProgramsScreenState createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<aProgramsPage> {
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _filteredPrograms = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
  }

  Future<void> _fetchPrograms() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwt_token');

    if (jwtToken == null || jwtToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to login to view programs')),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    const String apiUrl = 'http://192.168.1.30:5000/programs';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _programs =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
          _filteredPrograms = _programs; // Başlangıçta tüm programları göster
        });
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = errorData['message'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching programs')),
      );
    }
  }

  void _filterPrograms(String query) {
    setState(() {
      _searchQuery = query;
      _filteredPrograms = _programs
          .where((program) =>
              program['name'].toLowerCase().contains(query.toLowerCase()) ||
              program['description']
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              program['status'].toLowerCase().contains(query.toLowerCase()) ||
              program['application_end_date']
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              program['application_start_date']
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              program['id'].toString().contains(query.toLowerCase()) )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programs'),
        leading: Builder(
          builder: (BuildContext context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addProgram,
          ),
        ],
      ),
      drawer: const aLeftSidebar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterPrograms,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Long press a program to delete it',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchPrograms,
              child: _filteredPrograms.isEmpty
                  ? const Center(child: Text('No programs found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _filteredPrograms.length,
                      itemBuilder: (context, index) {
                        final program = _filteredPrograms[index];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              program['name'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              program['description'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Status: ${program['status']}'),
                                const SizedBox(height: 8),
                                Text(
                                  'Ends: ${program['application_end_date']}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProgramDetailPage(
                                    id: program['id'].toString(),
                                    name: program['name'],
                                    description: program['description'],
                                    applicationStartDate:
                                        program['application_start_date'],
                                    applicationEndDate:
                                        program['application_end_date'],
                                    status: program['status'],
                                  ),
                                ),
                              );
                            },
                            onLongPress: () {
                              _confirmDelete(program['id']);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Add your delete, add, and confirm delete methods here
  Future<void> _deleteProgram(int programId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwt_token');

    final String apiUrl = 'http://192.168.1.30:5000/admin/program/$programId';
    final response = await http.delete(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program deleted successfully')),
      );
      _fetchPrograms(); // Update the list automatically after deletion
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete program')),
      );
    }
  }

  void _confirmDelete(int programId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Do you really want to delete this program?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProgram(programId);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addProgram() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwt_token');

    TextEditingController nameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController startDateController = TextEditingController();
    TextEditingController endDateController = TextEditingController();
    String status = 'Open';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Program'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description')),
              TextField(
                  controller: startDateController,
                  decoration: const InputDecoration(
                      labelText: 'Start Date (mm-dd-yyyy)')),
              TextField(
                  controller: endDateController,
                  decoration: const InputDecoration(
                      labelText: 'End Date (mm-dd-yyyy)')),
              DropdownButtonFormField<String>(
                value: status,
                items: ['Open', 'Closed']
                    .map((status) =>
                        DropdownMenuItem(value: status, child: Text(status)))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    status = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _createProgram(nameController.text, descriptionController.text,
                    startDateController.text, endDateController.text, status);
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createProgram(String name, String description, String startDate,
      String endDate, String status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwt_token');

    final String apiUrl = 'http://192.168.1.30:5000/admin/newprogram';
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'application_start_date': startDate,
        'application_end_date': endDate,
        'status': status,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program added successfully')),
      );
      _fetchPrograms(); // Update the list after adding a new program
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add program')),
      );
    }
  }
}
