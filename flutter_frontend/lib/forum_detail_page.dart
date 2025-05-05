import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ForumDetailPage extends StatefulWidget {
  final int forumId;
  const ForumDetailPage({super.key, required this.forumId});
  @override
  State<ForumDetailPage> createState() => _ForumDetailPageState();
}

class _ForumDetailPageState extends State<ForumDetailPage> {
  Map<String, dynamic>? forum;
  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchForumDetails();
  }

  Future<void> fetchForumDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) return;
    final forumResponse = await http.get(
      Uri.parse('https://expant-backend.onrender.com/forums/${widget.forumId}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (forumResponse.statusCode == 200) {
      final forumData = jsonDecode(forumResponse.body);
      final List<Map<String, dynamic>> parsedComments =
          List<Map<String, dynamic>>.from(forumData['comments'] ?? []);
      if (!mounted) return;
      setState(() {
        forum = {'id': widget.forumId, ...forumData};
        comments = parsedComments;
        isLoading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> submitComment() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null || _commentController.text.trim().isEmpty) return;
    await http.post(
      Uri.parse('https://expant-backend.onrender.com/create_comment/${widget.forumId}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'description': _commentController.text.trim()}),
    );
    _commentController.clear();
    fetchForumDetails();
  }

  String formatTimestamp(String raw) {
    try {
      final dt = DateTime.parse(raw).toUtc();
      return '${DateFormat('EEE, dd MMM yyyy HH:mm:ss').format(dt)} GMT';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6E3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F1DE),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Post details",
          style: TextStyle(color: Color(0xFF618B4A), fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: Divider(thickness: 2, color: Color(0xFF618B4A)),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : forum == null
              ? const Center(child: Text("Forum not found."))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  forum!['title'] ?? '[title]',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFF7BA273)),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                      context, '/profile_page',
                                      arguments: forum!['username']),
                                  child: Text(
                                    "${forum!['username']} • ${formatTimestamp(forum!['created_time'])}",
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(forum!['description'] ?? '',
                                    style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          const Divider(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                const Text("Comments",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF7BA273))),
                                const Spacer(),
                                const Icon(Icons.comment_outlined),
                                const SizedBox(width: 4),
                                Text(comments.length.toString()),
                              ],
                            ),
                          ),
                          const Divider(),
                          ...comments.asMap().entries.map((entry) {
                            final comment = entry.value;
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                  border: Border(
                                      bottom:
                                          BorderSide(color: Colors.black12))),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                        context, '/profile_page',
                                        arguments: comment['username']),
                                    child: Text(
                                      "@${comment['username']} • ${formatTimestamp(comment['created_at'])}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          decoration:
                                              TextDecoration.underline),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(comment['description'] ?? '',
                                      style:
                                          const TextStyle(fontSize: 14)),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextField(
                              controller: _commentController,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: "Write a comment...",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: submitComment,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF7BA273)),
                                    child: const Text(
                                      "+ Comment",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
