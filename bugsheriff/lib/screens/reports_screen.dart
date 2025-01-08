import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bugsheriff/left_sidebar.dart';
import 'package:http/http.dart' as http;

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsPage> {
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwt_token');

    if (jwtToken == null || jwtToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to login to view reports')),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    const String apiUrl = 'http://192.168.1.30:5000/reports';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _reports = List<Map<String, dynamic>>.from(jsonDecode(response.body));
          _filteredReports =
              _reports; // Initially, filtered list is same as original
        });
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = errorData['message'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching reports')),
      );
    }
  }

  Future<Uint8List?> _fetchPdfContent(final String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwt_token');

    if (jwtToken == null || jwtToken.isEmpty) {
      return null; // Token yoksa null döndür
    }

    try {
      final Response<List<int>> response = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Authorization': 'Bearer $jwtToken', // JWT token'ı header'a ekledik
          },
        ),
      );
      return Uint8List.fromList(response.data!);
    } catch (e) {
      print('Error fetching PDF: $e');
      return null;
    }
  }

  void _viewReport(String reportPath) async {
    String reportUrl = 'http://192.168.1.30:5000/uploads/$reportPath';

    final pdfData = await _fetchPdfContent(reportUrl);

    if (pdfData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text('PDF Viewer')),
            body: PdfPreview(
              allowPrinting: false,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              pdfFileName: reportPath,
              enableScrollToPage: true,
              initialPageFormat: PdfPageFormat.a4,
              build: (format) => pdfData,
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load PDF')),
      );
    }
  }

  void _filterReports(String query) {
    setState(() {
      _searchText = query.toLowerCase();
      _filteredReports = _reports.where((report) {
        final id = report['id'].toString().toLowerCase();
        final status = report['status'].toLowerCase();
        final programName = report['program_name'].toLowerCase();
        final reward = report['reward_amount'].toString().toLowerCase();

        return id.contains(_searchText) ||
            status.contains(_searchText) ||
            programName.contains(_searchText) ||
            reward.contains(_searchText);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      drawer: const LeftSidebar(), // LeftSidebar widget'ını kullanın
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Reports',
                border: OutlineInputBorder(),
              ),
              onChanged: _filterReports,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh:
                  _fetchReports, // Pull-to-refresh için raporları yeniden yükleme
              child: _filteredReports.isEmpty
                  ? const Center(child: Text('No reports found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = _filteredReports[index];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('Report ID: ${report['id']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: ${report['status']}'),
                                Text('Program: ${report['program_name']}'),
                                Text(
                                    'Reward: \$${report['reward_amount'].toString()}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () =>
                                  _viewReport(report['report_pdf_path']),
                            ),
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
