import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../left_sidebar.dart'; // Sol menüyü import edin
import '../widgets/program_detail.dart'; // Import the ProgramDetailPage here

class ProgramsPage extends StatefulWidget {
  const ProgramsPage({super.key});

  @override
  _ProgramsScreenState createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsPage> {
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
          _filteredPrograms =
              _programs; // Filtrelenmiş listeyi başta tüm programlarla eşitle
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
              program['id'].toString().contains(query))
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
      ),
      // Please add a text which is "Long press on a program to delete it"
      drawer: const LeftSidebar(),
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
          Expanded(
            child: RefreshIndicator(
              onRefresh:
                  _fetchPrograms, // Sayfa yenilendiğinde programları tekrar çek
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
}
