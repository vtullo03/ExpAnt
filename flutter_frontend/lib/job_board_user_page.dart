import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class JobBoardUserPage extends StatefulWidget {
  const JobBoardUserPage({super.key});

  @override
  State<JobBoardUserPage> createState() => _JobBoardUserPageState();
}

class _JobBoardUserPageState extends State<JobBoardUserPage> {
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
      Uri.parse('https://expant-backend.onrender.com/job_postings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("DEBUG job_postings response: $data");

      final jobs = List<Map<String, dynamic>>.from(data);


      setState(() {
        jobPostings = jobs;
        isLoading = false;
      });
    } else {
      print('Server responded with status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      //setState(() => isLoading = false);
    }
  } catch (e) {
    print('An error occurred: $e');
   // setState(() => isLoading = false);
  }
}


  String formatDate(dynamic raw) {
  if (raw == null || raw is! String || raw.trim().isEmpty) return '[date posted]';
  try {
    final dt = DateTime.parse(raw).toUtc();
    return DateFormat('EEE, dd MMM yyyy HH:mm').format(dt);
  } catch (_) {
    return '[date posted]';
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
            "Job Board",
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
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Recommended jobs for you",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                    //Company icon and info
                    Row(
                      children: [
                        //const CircleAvatar(radius: 24, backgroundColor: Colors.grey),
                        //const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job['username'] ?? '[company name]',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(job['location'] ?? '[location]'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Job title
                    Text(
                      job['title'] ?? '[position/title]',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    // Salary and date
                    Row(
                      children: [
                        const Text("Salary: ", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(_formatSalary(job['salary'])),
                      ],
                    ),
                    Text(formatDate(job['created_time'])),
                    const SizedBox(height: 10),
                    //View details text
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/job_details',
                            arguments: job,
                          );
                        },
                        child: const Text(
                          "View details",
                          style: TextStyle(
                            color: Color(0xFF7BA273),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          ),
        ),
      ],
    ),
  );
}

    String _formatSalary(dynamic salary) {
    try {
      final num value = num.parse(salary.toString());
      final formatter = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);
      return formatter.format(value);
    } catch (_) {
      return '[salary]';
    }
  }



}
