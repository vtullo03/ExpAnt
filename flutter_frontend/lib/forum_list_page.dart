import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ForumListPage extends StatefulWidget {
  const ForumListPage({super.key});

  @override
  State<ForumListPage> createState() => _ForumListPageState();
}

class _ForumListPageState extends State<ForumListPage> {
  List<Map<String, dynamic>> forums = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchForums();
  }

  Future<void> fetchForums() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) {
      print('No token found');
      return;
    }

    final response = await http.get(
      Uri.parse('https://expant-backend.onrender.com/get_forum_ids/garfield'), // test user
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final ids = List<int>.from(json['forum_ids']);

      final List<Map<String, dynamic>> loadedForums = [];

      for (final id in ids) {
        final forumResponse = await http.get(
          Uri.parse('https://expant-backend.onrender.com/forums/$id'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (forumResponse.statusCode == 200) {
          final forumData = jsonDecode(forumResponse.body);
          loadedForums.add(forumData);
        }
      }

      setState(() {
        forums = loadedForums;
        isLoading = false;
      });
    } else {
      print('Failed to load forums: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6E3),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.circle, color: Color(0xFFD98268)),
                    border: InputBorder.none,
                    hintText: 'Search forum posts...',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Forum list
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : forums.isEmpty
                      ? const Center(child: Text("No forums to display."))
                      : ListView.builder(
                          itemCount: forums.length,
                          itemBuilder: (context, index) {
                            final forum = forums[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              forum['title'] ?? 'No title',
                                              style: const TextStyle(
                                                color: Color(0xFF7BA273),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.black),
                                          const SizedBox(width: 4),
                                          Text('${forum['comment_count'] ?? 0}',
                                              style: const TextStyle(fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "${forum['username']} • ${forum['created_time']} • ID: ${forum['id']}",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(thickness: 1),
                              ],
                            );
                          },
                        ),
            ),

            // Create post button
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/create_forum');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7BA273),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                ),
                child: const Text(
                  '+ Create post',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
