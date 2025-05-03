import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CreateForumPage extends StatefulWidget {
  const CreateForumPage({super.key});

  @override
  State<CreateForumPage> createState() => _CreateForumPageState();
}

class _CreateForumPageState extends State<CreateForumPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool isSubmitting = false;

  Future<void> submitForumPost() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) return;

    setState(() => isSubmitting = true);

    final response = await http.post(
      Uri.parse('https://expant-backend.onrender.com/create_forum'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'Images': [], 
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context); //back to forum list page
    } else {
      print("Failed to create forum: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${response.body}")),
      );
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6E3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B3A3A),
        iconTheme: const IconThemeData(color: Colors.white, size: 35),
        title: const Text("Create Post", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSubmitting ? null : submitForumPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BA273),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("+ Submit", style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
