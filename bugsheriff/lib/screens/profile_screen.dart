import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../left_sidebar.dart'; // Import LeftSidebar

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfileScreenPageState createState() => _ProfileScreenPageState();
}

class _ProfileScreenPageState extends State<ProfilePage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final secretAnswerController = TextEditingController();
  final ibanController = TextEditingController();

  String? selectedSecretQuestion; // Selected secret question
  bool _isLoading = false;

  final List<String> secretQuestions = [
    "What is your pet's name?",
    "What is your mother's maiden name?",
    "What is your favorite book?"
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwt_token');

    if (jwtToken == null || jwtToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to login to view your profile')),
      );
      // Kullanıcıyı login sayfasına yönlendir
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    const String apiUrl = 'http://192.168.1.30:5000/user-details';
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
        final data = jsonDecode(response.body);
        setState(() {
          usernameController.text = data['username'];
          selectedSecretQuestion = data['secret_question'];
          secretAnswerController.text = data['secret_answer'];
          ibanController.text = data['iban'];
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user details')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching user details')),
      );
    }
  }

  Future<void> _updateUserDetails() async {
    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwt_token');

    const String apiUrl = 'http://192.168.1.30:5000/update-user';
    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type':
              'application/json', // Set content type to application/json
        },
        body: jsonEncode({
          'password': passwordController.text,
          'secret_question': selectedSecretQuestion ?? '',
          'secret_answer': secretAnswerController.text,
          'iban': ibanController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Failed to update profile';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('An error occurred while updating the profile.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'), // Changed title to "User Profile"
        leading: Builder(
          builder: (BuildContext context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context)
                  .openDrawer(); // Opens the drawer when pressed
            },
          ),
        ),
      ),
      drawer: LeftSidebar(), // Keep the sidebar
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 16),
                  // Display username
                  Text(
                    'Username: ${usernameController.text}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Password change section
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      hintText: "New Password",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18)),
                      fillColor: Colors.purple.withOpacity(0.1),
                      filled: true,
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      hintText: "Confirm New Password",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18)),
                      fillColor: Colors.purple.withOpacity(0.1),
                      filled: true,
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: selectedSecretQuestion,
                    hint: const Text("Select a Secret Question"),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedSecretQuestion = newValue;
                      });
                    },
                    items: secretQuestions.map((String question) {
                      return DropdownMenuItem<String>(
                        value: question,
                        child: Text(question),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.purple.withOpacity(0.1),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: secretAnswerController,
                    decoration: InputDecoration(
                      hintText: "Secret Answer",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18)),
                      fillColor: Colors.purple.withOpacity(0.1),
                      filled: true,
                      prefixIcon: const Icon(Icons.security),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: ibanController,
                    decoration: InputDecoration(
                      hintText: "IBAN",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18)),
                      fillColor: Colors.purple.withOpacity(0.1),
                      filled: true,
                      prefixIcon: const Icon(Icons.account_balance),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Update button
                  ElevatedButton(
                    onPressed: () {
                      if (passwordController.text ==
                          confirmPasswordController.text) {
                        _updateUserDetails();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text("Passwords do not match!")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color.fromARGB(26, 44, 6, 11),
                    ),
                    child: const Text(
                      "Update Profile",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
