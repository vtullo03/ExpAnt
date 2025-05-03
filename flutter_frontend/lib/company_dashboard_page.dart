import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CompanyDashboardPage extends StatefulWidget {
  const CompanyDashboardPage({super.key});

  @override
  State<CompanyDashboardPage> createState() => _CompanyDashboardPageState();
}

class _CompanyDashboardPageState extends State<CompanyDashboardPage> {
  List<Map<String, dynamic>> jobPostings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchJobPostings();
  }

  Future<void> fetchJobPostings() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');
  if (token == null) {
    print('No token found');
    setState(() => isLoading = false);
    return;
  }

  try {
    final response = await http.get(
      Uri.parse('https://expant-backend.onrender.com/messages/company_job_postings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final jobs = List<Map<String, dynamic>>.from(data['job_postings']); //extract properly
      setState(() {
        jobPostings = jobs;
        isLoading = false;
      });
    } else {
      print('Failed to fetch jobs: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching jobs: $e');
  }
}


  String formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '[date posted]';
    try {
      final dt = DateTime.parse(raw).toUtc();
      return DateFormat('EEE, dd MMM yyyy HH:mm').format(dt);
    } catch (_) {
      return '[date posted]';
    }
  }

  String formatSalary(dynamic salary) {
    try {
      final num value = num.parse(salary.toString());
      return NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0).format(value);
    } catch (_) {
      return '[salary]';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6E3),
    appBar: AppBar(
        backgroundColor: const Color(0xFF8B3A3A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); //Goes back to home
          },
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F6E3),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Text(
            "Company Dashboard",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF7BA273),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: 
              Text("Posted listings", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: jobPostings.length,
                    itemBuilder: (context, index) {
                      final job = jobPostings[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 3,
                        shadowColor: Colors.grey.shade300,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job['title'] ?? '[title]',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(job['location'] ?? '[location]'),
                              const SizedBox(height: 8),
                              Text(formatSalary(job['salary'])),
                              //Text(formatDate(job['created_time'])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/create_job_posting');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7BA273),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  '+ New job posting',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
