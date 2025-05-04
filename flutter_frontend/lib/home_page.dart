import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_frontend/message_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userType;
  bool isLoading = true;
  String? username;

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
        userType = json['user_type'];
        print(userType);
        username = prefs.getString('username');
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
      backgroundColor: const Color(0xFFF8F6E3),
      appBar: AppBar(
        title: const Text(
          'Welcome to ExpAnt',
          style: TextStyle(color: Color(0xFF3B2C2F)),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF7BA273),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B2C2F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome, ${username ?? ""}',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      children: [
                        _dashboardCard(
                          label: 'My Profile',
                          icon: Icons.person,
                          onTap: () => Navigator.pushNamed(context, '/profile_page'),
                        ),
                        _dashboardCard(
                          label: 'Forum',
                          icon: Icons.forum,
                          onTap: () => Navigator.pushNamed(context, '/forum_list'),
                        ),
                        _dashboardCard(
                          label: 'Jobs',
                          icon: Icons.work,
                          onTap: userType == 'worker'
                              ? () => Navigator.pushNamed(context, '/job_board_user_page')
                              : () => ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Only workers can view this.')),
                                  ),
                        ),
                        _dashboardCard(
                          label: 'Messages',
                          icon: Icons.message,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MessageScreen()),
                          ),
                        ),
                        _dashboardCard(
                          label: 'Connect',
                          icon: Icons.people,
                          onTap: () => Navigator.pushNamed(context, '/profile_swipe'),
                        ),
                        _dashboardCard(
                          label: 'Settings',
                          icon: Icons.settings,
                          onTap: () => Navigator.pushNamed(context, '/settings'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _dashboardCard({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF7BA273),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
