import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:url_launcher/url_launcher.dart';
import 'package:bugsheriff/aleft_sidebar.dart'; // Left sidebar import
import 'package:logger/logger.dart';

final logger = Logger();

void logInfo(String message) {
  logger.i(message);
}

void logError(String message) {
  logger.e(message);
}

class aReportsPage extends StatefulWidget {
  const aReportsPage({Key? key}) : super(key: key);

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<aReportsPage> {
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  TextEditingController _searchController = TextEditingController();
  Map<int, String> _selectedStatuses =
      {}; // Map to store status for each report

  @override
  void initState() {
    super.initState();
    _fetchReports();
    _searchController.addListener(_filterReports); // Add listener for search
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

    const String apiUrl = 'http://192.168.1.30:5000/admin/getreports';
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
          _filteredReports = _reports; // Initialize filtered reports

          // Initialize statuses for each report
          for (var report in _reports) {
            _selectedStatuses[report['id']] = report['status'];
          }
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

  void _filterReports() {
    String query = _searchController.text.toLowerCase();


    setState(() {
      if (query.isEmpty) {
        _filteredReports =
            List.from(_reports); // Reset to all reports if query is empty
      } else {
        _filteredReports = _reports.where((report) {
          return report['id'].toString().contains(query) ||
              report['iban'].toString().toLowerCase().contains(query) ||
              report['program_name'].toLowerCase().contains(query) ||
              report['status'].toLowerCase().contains(query) ||
              report['reward_amount'].toString().contains(query);
        }).toList();
      }
    });
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
      logError('Error fetching PDF: $e');
      return null;
    }
  }

  void _viewReport(String reportPath) async {
    String reportUrl = 'http://192.168.1.30:5000/admin/uploads/$reportPath';

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

  Future<void> _updateReport(int reportId, String status, double reward) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwt_token');

    const String apiUrl = 'http://192.168.1.30:5000/admin/report/';
    try {
      final response = await http.put(
        Uri.parse('$apiUrl$reportId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'reward_amount': reward,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated successfully')),
        );
        _fetchReports(); // Refresh the list after updating
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = errorData['message'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating report')),
      );
    }
  }

  Future<void> _copyToClipboard(String iban) async {
    await Clipboard.setData(ClipboardData(text: iban));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('IBAN copied to clipboard')),
    );

  }

  Future<void> _onRefresh() async {
    
    await _fetchReports(); // Refresh the reports
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      drawer: const aLeftSidebar(), // Use LeftSidebar widget
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText:
                    'Search by ID, IBAN, Program Name, Status, or Reward',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: _filteredReports.isEmpty
                    ? const Center(child: Text('No reports found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _filteredReports.length,
                        itemBuilder: (context, index) {
                          final report = _filteredReports[index];
                          TextEditingController rewardController =
                              TextEditingController(
                                  text: report['reward_amount'].toString());

                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text('Report ID: ${report['id']}'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Program: ${report['program_name']}'),
                                      Text(
                                          'Current Status: ${report['status']}'),
                                      Text(
                                          'Current Reward: \$${report['reward_amount']}'),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('IBAN: ${report['iban']}'),
                                          IconButton(
                                            icon: const Icon(Icons.copy),
                                            onPressed: () => _copyToClipboard(
                                              
                                                report['iban']),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.visibility),
                                    onPressed: () =>
                                        _viewReport(report['report_pdf_path']),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Row(
                                    children: [
                                      DropdownButton<String>(
                                        value: _selectedStatuses[report['id']],
                                        items: const [
                                          DropdownMenuItem(
                                              value: 'Pending',
                                              child: Text('Pending')),
                                          DropdownMenuItem(
                                              value: 'Accepted',
                                              child: Text('Accepted')),
                                          DropdownMenuItem(
                                              value: 'Rejected',
                                              child: Text('Rejected')),
                                        ],
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _selectedStatuses[report['id']] =
                                                newValue!; // Update individual status
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: rewardController,
                                          decoration: const InputDecoration(
                                            labelText: 'Reward Amount',
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.save),
                                        onPressed: () {
                                          double newReward = double.tryParse(
                                                  rewardController.text) ??
                                              0.0;

                                          if (_selectedStatuses[report['id']]!
                                              .isNotEmpty) {
                                            _updateReport(
                                                report['id'],
                                                _selectedStatuses[
                                                    report['id']]!,
                                                newReward);
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        'Please select a status.')));
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
