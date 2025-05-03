import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_frontend/message_screen.dart'; // Adjust path if needed


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userType;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserType();
  }

  Future<void> fetchUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) {
      print('No token found');
      setState(() {
        isLoading = false;
        userType = null;
      });
      return;
    }

    final response = await http.get(
      Uri.parse('https://expant-backend.onrender.com/user_type'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      setState(() {
        userType = json['user_type']; //should be 'jobforceuser' or 'official'
        print(userType);
        isLoading = false;
      });
    } else {
      print('Failed to fetch user type: ${response.body}');
      setState(() {
        isLoading = false;
        userType = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7D5CA),
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: const Color(0xFF7BA273),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'You are logged in! sample homepage',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 30),

                  // Forum Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forum_list');
                    },
                    style: _buttonStyle(),
                    child: const Text('View Forum Posts', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),

                  // Jobforceuser job board
                  ElevatedButton(
                    onPressed: userType == 'worker'
                        ? () => Navigator.pushNamed(context, '/job_board_user_page')
                        : () => print('Access denied: Only users can view this'),
                    style: _buttonStyle(disabled: userType != 'worker'),
                    child: const Text('View Jobs', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 20),

                  // Chat Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MessageScreen()),
                      );
                    },
                    style: _buttonStyle(),
                    child: const Text('Open Messages', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),

                  // Matches today swipe screen
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile_swipe');
                    },
                    style: _buttonStyle(),
                    child: const Text('View profiles', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
      ),
    );
  }

  ButtonStyle _buttonStyle({bool disabled = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: disabled ? Colors.grey.shade400 : const Color(0xFF7BA273),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
