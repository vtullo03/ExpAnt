import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewJobDetailsPage extends StatefulWidget {
  const ViewJobDetailsPage({super.key});

  @override
  State<ViewJobDetailsPage> createState() => _ViewJobDetailsPageState();
}

class _ViewJobDetailsPageState extends State<ViewJobDetailsPage> {
  String? selectedConnection; // Placeholder for connection selection
  final List<String> mockConnections = ['Alice', 'Bob', 'Charlie']; // Replace with real connections later

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '[date posted]';
    try {
      final dt = DateTime.parse(raw).toUtc();
      return DateFormat('EEE, dd MMM yyyy HH:mm').format(dt);
    } catch (_) {
      return '[date posted]';
    }
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

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6E3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B3A3A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Job Details", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Job Summary Card
            Card(
              elevation: 3,
              shadowColor: Colors.grey.shade300,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                    Text(job['title'] ?? '[position/title]',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text("Salary: ${_formatSalary(job['salary'])}"),
                    Text("Posted: ${_formatDate(job['created_time'])}"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Job Description",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black26),
              ),
              child: Text(job['description'] ?? '[Description]'),
            ),

            const SizedBox(height: 20),

            // Apply Button
            if (job['company_website_link'] != null &&
                job['company_website_link'].toString().trim().isNotEmpty)
              ElevatedButton(
                onPressed: () => _launchURL(job['company_website_link']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7BA273),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: const Text("Apply on website", style: TextStyle(color: Colors.white)),
              ),

            const SizedBox(height: 30),

            // Share to Connection
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Want to recommend this job to a connection?",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedConnection,
                    hint: const Text("[dropdown]"),
                    items: mockConnections.map((conn) {
                      return DropdownMenuItem(
                        value: conn,
                        child: Text(conn),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedConnection = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: selectedConnection == null
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Shared with $selectedConnection!")),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7BA273),
                  ),
                  child: const Text("Share", style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
