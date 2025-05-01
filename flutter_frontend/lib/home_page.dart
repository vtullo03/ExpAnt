import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('https://expant-backend.onrender.com/get_my_account'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['account_type']; // expects 'official_company' or 'jobforceuser'
    } else {
      print('Failed to fetch user type: ${response.body}');
      return null;
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You are logged in! sample homepage',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 30),

            // Button to Forum List
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forum_list');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BA273),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View Forum Posts',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Button to Jobs
            /*
            ElevatedButton(
              onPressed: () async {
                final type = await getUserType();
                if (type == 'official_company') {
                  Navigator.pushNamed(context, '/company_dashboard');
                } else if (type == 'jobforceuser') {
                  Navigator.pushNamed(context, '/job_board_user');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Could not determine user type')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BA273),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View Jobs',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            */

            ElevatedButton(
              onPressed: () async {
                  Navigator.pushNamed(context, '/job_board_user_page');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BA273),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View Jobs',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            
            ElevatedButton(
              onPressed: () async {
                  Navigator.pushNamed(context, '/company_dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BA273),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View Jobs (COMPANY)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
